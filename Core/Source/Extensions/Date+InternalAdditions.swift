//
//  Date+InternalAdditions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


internal extension Date {
  private static func httpDateFormatter(withFormat format: String) -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(identifier: "UTC")
    return dateFormatter
  }
  
  private static let rfc1123DateFormatter: DateFormatter = {
    httpDateFormatter(withFormat: "EEE',' dd MMM yyyy HH':'mm':'ss z")
  }()
  
  private static let rfc850DateFormatter: DateFormatter = {
    httpDateFormatter(withFormat: "EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z")
  }()
  
  private static let asctimeFormatter: DateFormatter = {
    httpDateFormatter(withFormat: "EEE MMM d HH':'mm':'ss yyyy")
  }()
  
  static func httpDate(from string: String) -> Date? {
    if let date = Self.rfc1123DateFormatter.date(from: string) { return date }
    if let date = Self.rfc850DateFormatter.date(from: string) { return date }
    if let date = Self.asctimeFormatter.date(from: string) { return date }
    return nil
  }
  
  func formatHttpDate() -> String {
    Self.rfc1123DateFormatter.string(from: self)
  }
}

internal extension String {
  func asHttpDate() -> Date? {
    Date.httpDate(from: self)
  }
}
