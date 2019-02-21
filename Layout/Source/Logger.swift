//
//  Logger.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

public final class Logger: NSObject {
  
  public static let shared: Logger = {
    Logger("InterfaCSS")
  }()

  public let name: String
  public override var description: String { return name }

  public init(_ name: String) {
    self.name = name
  }
}
