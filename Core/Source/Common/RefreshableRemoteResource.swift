//
//  RefreshableRemoteResource.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


let ISSRefreshableResourceErrorDomain = "InterfaCSS.RefreshableResource"


/// Handles refreshing of a remote file resource
public class RefreshableRemoteResource: RefreshableResource {
    
  public internal(set) var eTag: String?
  
  private let urlSession: URLSession
  
  
  override init(withURL url: URL) {
    let configuration = URLSessionConfiguration.default
    configuration.requestCachePolicy = .reloadIgnoringLocalCacheData // Note: ReloadIgnoringLocalAndRemoteCacheData is unimplemented
    configuration.urlCache = URLCache(memoryCapacity: 0, diskCapacity: 0, diskPath: nil) // Disable disk cache
    
    self.urlSession = URLSession(configuration: configuration)
    super.init(withURL: url)
  }
  
  
  public override func refresh(intervalDuringError: TimeInterval = 0, force: Bool = false, completionHandler: @escaping RefreshableResourceLoadCompletionBlock) {
    if hasErrorOccurred && (Date.timeIntervalSinceReferenceDate - lastErrorTime) < intervalDuringError {
      return
    }
    
    var request = URLRequest(url: self.resourceURL)
    request.cachePolicy = .reloadIgnoringLocalCacheData
    if !force, let lastModified = lastModified {
      request.setValue(lastModified.formatHttpDate(), forHTTPHeaderField: "If-Modified-Since")
    }
    if !force, let eTag = eTag {
      request.setValue(eTag, forHTTPHeaderField: "If-None-Match")
    }
    
    if !force && (lastModified != nil || eTag != nil) { executeRequest(request, isHead: true, completion: completionHandler) }
    else { executeRequest(request, isHead: false, completion: completionHandler) }
  }
}


/// HTTP calls
private extension RefreshableRemoteResource {

  private func parseLastModifiedFromResponse(_ response: HTTPURLResponse) -> Date? {
    var updatedLastModified = (response.allHeaderFields.value(forCaseInsensitiveKey: "Last-Modified") as? String)?.asHttpDate()
    if updatedLastModified == nil { updatedLastModified = (response.allHeaderFields.value(forCaseInsensitiveKey: "Date") as? String)?.asHttpDate() }
    return updatedLastModified;
  }
  
  private func executeRequest(_ _request: URLRequest, isHead: Bool = false, completion: @escaping RefreshableResourceLoadCompletionBlock) {
    var request = _request
    request.httpMethod = isHead ? "HEAD" : "GET"
    
    let task = urlSession.dataTask(with: request) { [weak self] (data, response, _error) in
      guard let self = self else { return }
      var error = _error
      let httpResponse = response as! HTTPURLResponse
      let errorPrefix = isHead ? "Unable to verify if remote resource (\(self.resourceURL)) is modified" : "Error downloading resource \(self.resourceURL)"
      
      if isHead && httpResponse.statusCode == 200 {
        let updatedETag = httpResponse.allHeaderFields.value(forCaseInsensitiveKey: "ETag") as? String
        let eTagModified = self.eTag != nil && self.eTag != updatedETag
        let updatedLastModified = self.parseLastModifiedFromResponse(httpResponse)
        let lastModifiedModified = self.lastModified != nil && self.lastModified != updatedLastModified
        if eTagModified || lastModifiedModified  { // In case server didn't honor etag/last modified
          Logger.misc.debug("Remote resource (\(self.resourceURL) modified - executing get request")
          self.executeRequest(request, isHead: false, completion: completion)
        } else {
          Logger.misc.trace("Remote resource (\(self.resourceURL) NOT modified - ETag: \(self.eTag ?? "-")/\(updatedETag ?? "-"), " +
                              "Last-Modified: \(self.lastModified?.description ?? "-")/\(updatedLastModified?.description ?? "-")")
        }
      }
      else if httpResponse.statusCode == 200 {
        self.eTag = httpResponse.allHeaderFields.value(forCaseInsensitiveKey: "ETag") as? String
        self.lastModified = self.parseLastModifiedFromResponse(httpResponse)
        Logger.misc.debug("Remote resource (\(self.resourceURL) downloaded (ETag: \(self.eTag ?? "-"), Last-Modified: \(self.lastModified?.description ?? "-") - parsing response data")
        
        let encodingName = httpResponse.textEncodingName
        var encoding = String.Encoding.utf8
        if let encodingName = encodingName {
          let enc = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
          if enc != kCFStringEncodingInvalidId {
            encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(enc))
          }
        }
        
        var responseString: String?
        if let data = data, let string = String(data: data, encoding: encoding) {
          responseString = string
        }
        
        DispatchQueue.main.async { completion(true, responseString, nil) }
      }
      else if httpResponse.statusCode == 304 {
        Logger.misc.trace("Remote resource (\(self.resourceURL) not modified");
      }
      else {
        if let error = error {
          if self.hasErrorOccurred { Logger.misc.trace("\(errorPrefix) - \(error.localizedDescription)") }
          else { Logger.misc.debug("\(errorPrefix) - \(error.localizedDescription)") }
        } else {
          error = NSError(domain: ISSRefreshableResourceErrorDomain, code: 1001, userInfo:
                          [NSLocalizedDescriptionKey: "\(errorPrefix) - got HTTP response code \(httpResponse.statusCode)"])
          if self.hasErrorOccurred { Logger.misc.trace(error!.localizedDescription) }
          else { Logger.misc.debug(error!.localizedDescription) }
        }
        self.lastError = error
        DispatchQueue.main.async { completion(false, nil, error) }
      }
      
      if error == nil { self.lastError = nil }
    }
    task.resume()
  }
}
