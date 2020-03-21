//
//  RefreshableResource.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

public typealias RefreshableResourceObserverBlock = (RefreshableResource) -> Void
public typealias RefreshableResourceLoadCompletionBlock = (_ success: Bool, _ data: String?, _ error: Error?) -> Void

/**
 *
 */
open class RefreshableResource {
  let logger = Logger.misc
  
  public let resourceURL: URL
  
  public internal(set) var lastModified: Date?
  
  var lastErrorTime: TimeInterval = 0
  
  public var hasErrorOccurred: Bool { lastErrorTime != 0 }
  public private(set) var lastError: Error? = nil {
    didSet {
      lastErrorTime = lastError != nil ? Date.timeIntervalSinceReferenceDate : 0
    }
  }
  
  public var resourceModificationMonitoringSupported: Bool { false }
  public var resourceModificationMonitoringEnabled: Bool { false }
  
  public init(withURL url: URL) {
    resourceURL = url
  }
  
  func startMonitoringResourceModification(modificationCallback: @escaping RefreshableResourceObserverBlock) {}
  func endMonitoringResourceModification() {}
  
  func refresh(intervalDuringError: TimeInterval = 0, force: Bool = false, completionHandler: @escaping RefreshableResourceLoadCompletionBlock) {}
}

public class RefreshableLocalResource : RefreshableResource {
  override public var resourceModificationMonitoringSupported: Bool { true }
  override public var resourceModificationMonitoringEnabled: Bool { fileChangeSource != nil }
  
  private var fileChangeSource: DispatchSourceFileSystemObject? = nil
  
  override func refresh(intervalDuringError: TimeInterval = 0, force: Bool = false, completionHandler: @escaping RefreshableResourceLoadCompletionBlock) {
    
    if hasErrorOccurred && (Date.timeIntervalSinceReferenceDate - lastErrorTime) < intervalDuringError {
      return
    }
    
    let fm = FileManager.default
    let attrs = try? fm.attributesOfItem(atPath: resourceURL.path)
    var date: Date?
    if let attrs = attrs {
      date = attrs[.modificationDate] as? Date
      if date == nil {
        date = attrs[.creationDate] as? Date
      }
    }
    if force || lastModified == nil || lastModified != date {
      let data = try? String(contentsOf: resourceURL)
      completionHandler(true, data, nil)
      lastModified = date
    }
  }
  
  override func startMonitoringResourceModification(modificationCallback: @escaping RefreshableResourceObserverBlock) {
    if resourceModificationMonitoringEnabled {
      endMonitoringResourceModification()
    }
    
    let fileDescriptor = open(FileManager.default.fileSystemRepresentation(withPath: resourceURL.path), O_EVTONLY)
    guard fileDescriptor >= 0 else {
      logger.error("Unable to monitor '\(resourceURL.lastPathComponent)' for changes (file could not be opened)")
      return
    }
    
    self.fileChangeSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: .all, queue: DispatchQueue.global())
    guard let fileChangeSource = self.fileChangeSource else {
      logger.error("Unable to monitor '\(resourceURL.lastPathComponent)' for changes (error creating dispatch source)")
      return
    }
    
    fileChangeSource.setEventHandler() { [weak self, resourceURL, logger] in
      guard let strongSelf = self, let fileChangeSource = strongSelf.fileChangeSource else { return }
      let data = fileChangeSource.data
      DispatchQueue.main.async {
        modificationCallback(strongSelf)
      }
      DispatchQueue.main.async {
        if data == .delete {
          logger.debug("RefreshableResource - '\(resourceURL.lastPathComponent)' seems to have been deleted - attempting to restart monitoring of file")
          self?.startMonitoringResourceModification(modificationCallback: modificationCallback)
        }
      }
    }
    
    fileChangeSource.setCancelHandler() {
      close(fileDescriptor)
    }
    
    fileChangeSource.resume()
    
    logger.debug("Started monitoring - '\(resourceURL.lastPathComponent)' for changes")
  }
  
  override func endMonitoringResourceModification() {
    fileChangeSource?.cancel()
    fileChangeSource = nil
  }
}
