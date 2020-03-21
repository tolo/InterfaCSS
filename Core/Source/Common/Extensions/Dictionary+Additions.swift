//
//  NSDictionary+DictionaryAdditions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

extension Dictionary where Key == String, Value: Any {
  
  public func dictionaryWithLowerCaseKeys() -> [String: Value] {
    return Dictionary(uniqueKeysWithValues: self.map({ (key, value) in
      (key.lowercased(), value)
    }))
  }
  
  func dictionary(byAddingValue value: Value, forKey key: String) -> [String: Value] {
    var dict = self
    dict[key] = value
    return dict
  }
}
