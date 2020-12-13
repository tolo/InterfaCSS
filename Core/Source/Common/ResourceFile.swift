//
//  ResourceFile.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


/// Represents a local resource file, like a stylesheet, that may be refreshable
public enum ResourceFile {
  case mainBundeFile(filename: String)
  case refreshableProjectFile(filename: String, relativeToDirectory: URL)
  
  public var refreshable: Bool {
    switch self {
      case .refreshableProjectFile(_, _): return true
      default: return false
    }
  }
  
  public var filename: String {
    switch self {
    case .refreshableProjectFile:
      return fileURL.lastPathComponent
    case .mainBundeFile(let filename):
      return filename
    }
  }
  
  public var fileURL: URL {
    switch self {
    case .refreshableProjectFile(let filename, let localProjectDirectory):
      return URL(fileURLWithPath:filename, isDirectory: false, relativeTo: localProjectDirectory)
    case .mainBundeFile(let filename):
      guard let url = Bundle.main.url(forResource: filename, withExtension: nil) else {
        preconditionFailure("Main bundle file '\(filename)' does not exist!")
      }
      return url
    }
  }

  public static func refreshableProjectFile(_ filename: String, relativeToDirectoryContaining baseDirFilePath: String) -> ResourceFile {
    #if targetEnvironment(simulator)
    let baseUrl = URL(fileURLWithPath: baseDirFilePath)
    return .refreshableProjectFile(filename: filename, relativeToDirectory: baseUrl.deletingLastPathComponent())
    #else
    return .mainBundeFile(filename: filename)
    #endif
  }
}
