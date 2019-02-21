//
//  String+InterfaCSS.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

// TODO: Remove after swift conversion of core...
public extension StringProtocol where Self.Index == String.Index {
  func isEmpty() -> Bool {
    return trim().count == 0
  }
  
  func hasData() -> Bool {
    return !isEmpty()
  }
  
  func trim() -> String {
    return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
  
  func isCaseInsensitiveEqual<Other: StringProtocol>(_ otherString: Other) -> Bool where Other.Index == Self.Index {
    return compare(otherString, options: .caseInsensitive) == .orderedSame
  }
  
  func isCaseInsensitiveEqual<Other: StringProtocol>(_ otherString: Other, withOptionalPrefix prefix: String) -> Bool where Other.Index == Self.Index {
    if isCaseInsensitiveEqual(otherString) {
      return true
    }
    return (prefix + self).isCaseInsensitiveEqual(prefix + otherString)
  }
}
