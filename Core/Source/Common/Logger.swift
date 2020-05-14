//
//  Logger.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation
import os.log

public final class Logger: NSObject { // TODO: Remove NSObject
  
  private static var subsystem = Bundle.main.bundleIdentifier!
  
  public static let misc: Logger = { Logger("misc") }()
  public static let styling: Logger = { Logger("styling") }()
  public static let stylesheets: Logger = { Logger("stylesheets") }()
  public static let properties: Logger = { Logger("properties") }()
  public static let layout: Logger = { Logger("layout") }()
  
  public let name: String
  public override var description: String { return name }
  
  public let log: OSLog
  
  public init(_ name: String) {
    self.name = name
    log = OSLog(subsystem: Logger.subsystem, category: "InterfaCSS (\(name))")
  }
  
  public func debug(_ message: String) {
    os_log("%{public}@", log: log, type: .debug, message)
  }
  
  public func info(_ message: String) {
    os_log("%{public}@", log: log, type: .info, message)
  }
  
  public func error(_ message: String) {
    os_log("%{public}@", log: log, type: .error, message)
  }
  
  public func fault(_ message: String) {
    os_log("%{public}@", log: log, type: .fault, message)
  }
}

internal func logDebug(_ logger: Logger, _ message: String) {
  logger.debug(message)
}

internal func logInfo(_ logger: Logger, _ message: String) {
  logger.info(message)
}

internal func logError(_ logger: Logger, _ message: String) {
  logger.error(message)
}

internal func logFault(_ logger: Logger, _ message: String) {
  logger.fault(message)
}
