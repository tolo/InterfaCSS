//
//  CompoundProperty.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit

/// Handles the case when multiple (CSS) properties correspond to a single native property
open class CompoundProperty: Hashable {
  public let propertyName: String
  public let compoundPropertyNames: Set<String>
  
  init(name: String, compoundNames: [String]) {
    self.propertyName = name
    self.compoundPropertyNames = compoundNames.map { Property.normalizeName($0) }.toSet()
  }
  
  func process(propertyValues: inout [PropertyValue]) -> PropertyValue? {
    let matchingProperties = propertyValues.filter({ compoundPropertyNames.contains($0.propertyName) })
    guard matchingProperties.count > 0 else { return nil }
    propertyValues.removeAll { matchingProperties.contains($0) }
    return PropertyValue(propertyName: propertyName, compoundProperty: self, compoundValues: matchingProperties)
  }
  
  func rawValues(from propertyValues: [PropertyValue]) -> [String: String] {
    let entries = compoundPropertyNames.compactMap { name -> (String, String)? in
      guard let value = propertyValues.first(where: { $0.propertyName == name })?.rawValue else { return nil }
      return (name, value)
    }

    return Dictionary(uniqueKeysWithValues: entries)
  }
  
  func resolve(propertyValues: [PropertyValue]) -> Any? {
    return nil
  }
  
  /// Hashable and Equatable
  
  public static func == (lhs: CompoundProperty, rhs: CompoundProperty) -> Bool {
    return lhs.propertyName == rhs.propertyName
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(propertyName)
  }
}
