//
//  BundleFile.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

public enum BundleFile {
  case mainBundeFile(filename: String)
  case refreshableProjectFile(filename: String, localProjectDirectory: String)
  
  public var refreshable: Bool {
    switch self {
      case .refreshableProjectFile(_, _): return true
      default: return false
    }
  }
  
  public var filename: String {
    switch self {
    case .refreshableProjectFile(let filename, _):
      return filename
    case .mainBundeFile(let filename):
      return filename
    }
  }
  
  public var validFileURL: URL {
    switch self {
    case .refreshableProjectFile(let filename, let localProjectDirectory):
      return URL(fileURLWithPath: localProjectDirectory + "/" + filename)
    case .mainBundeFile(let filename):
      guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
        preconditionFailure("Main bundle file '\(filename)' does not exist!")
      }
      return url
    }
  }
  
  public static func refreshableProjectFile(_ filename: String, inSameLocalProjectDirectoryAsCurrentFile currentFile: String) -> BundleFile {
    let lastSeparatorIndex = currentFile.lastIndex(of: "/") ?? currentFile.endIndex
    let dirPath = String(currentFile[..<lastSeparatorIndex])
    #if targetEnvironment(simulator)
    return .refreshableProjectFile(filename: filename, localProjectDirectory: dirPath)
    #else
    return .mainBundeFile(filename: filename)
    #endif
  }
  
  public static func refreshableProjectFile(_ filename: String, projectPathUsingCurrentFile currentFile: String, projectRootDir: String, subDir: String = "") -> BundleFile {
    let dirPath = localProjectPath(usingCurrentFile: currentFile, projectRootDir: projectRootDir, subDir: subDir)
    #if targetEnvironment(simulator)
    return .refreshableProjectFile(filename: filename, localProjectDirectory: dirPath)
    #else
    return .mainBundeFile(filename: filename)
    #endif
  }
  
  public static func localProjectPath(usingCurrentFile currentFile: String, projectRootDir: String, subDir: String = "") -> String {
    let pathComponents = URL(fileURLWithPath: currentFile).pathComponents.dropFirst()
    let rootPath = pathComponents.prefix(while: { $0 != projectRootDir }).joined(separator: "/")
    return "/\(rootPath)/\(projectRootDir)/\(subDir)"
  }
}
