//
//  RelativeNumber.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

public enum RelativeNumberUnit {
  case absolute
  case percent
  case auto
}

public struct RelativeNumber {
  public let rawValue: NSNumber
  public let unit: RelativeNumberUnit
  
  public var value: NSNumber {
    switch unit {
      case .percent: return NSNumber(value: rawValue.doubleValue / 100.0)
      default: return rawValue
    }
  }
}
