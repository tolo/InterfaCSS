//
//  PropertyValue.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//


/**
 * Represents the declaration of a property name/value pair in a stylesheet.
 */
public struct PropertyValue: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
  
  public enum Value: Hashable {
    case value(rawValue: String)
    case compoundValues(compoundProperty: CompoundProperty, compoundValues: [PropertyValue])
    case currentValue
  }
  
  public let propertyName: String /// Normalized property name
  public let value: Value
  public let rawParameters: [String]? // TODO: Remove?
  
  public func copyWith(value newValue: String? = nil, parameters newRawParameters: [String]? = nil) -> PropertyValue {
    let newVal = newValue != nil ? Value.value(rawValue: newValue!) : nil
    return PropertyValue(propertyName: propertyName, value: newVal ?? value, rawParameters: newRawParameters ?? rawParameters)
  }
  
  public var fqn: String {
    var parameterString = ""
    if let rawParameters = rawParameters {
      parameterString = "__\(rawParameters.joined(separator: "_"))"
    }
    
    return "\(propertyName)\(parameterString)"
  }
  
  public var rawValue: String? {
    guard case .value(let rawValue) = value else { return nil }
    return rawValue
  }
  
  public var useCurrentValue: Bool {
    return value == .currentValue
  }
  
  public var description: String {
    switch value {
      case .value(let rawValue): return "\(fqn): \(rawValue)"
      case .compoundValues(_, let compoundValues): return "\(fqn): \(compoundValues.map({$0.description}).joined(separator: ", "))"
      case .currentValue: return "\(fqn): <using current>"
    }
  }
  
  public var debugDescription: String {
    return "PropertyValue[\(description)]"
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(fqn)
  }
  
  public static func == (lhs: PropertyValue, rhs: PropertyValue) -> Bool {
    return lhs.fqn == rhs.fqn
  }
}


public extension PropertyValue {
  init(propertyName: String, value: String, rawParameters: [String]? = nil) {
    self.init(propertyName: propertyName, value: .value(rawValue: value), rawParameters: rawParameters)
  }
  
  init(propertyName: String, compoundProperty: CompoundProperty, compoundValues: [PropertyValue], rawParameters: [String]? = nil) {
    self.init(propertyName: propertyName,
      value: .compoundValues(compoundProperty: compoundProperty, compoundValues: compoundValues), rawParameters: rawParameters)
  }
  
  init(propertyUsingCurrentValue propertyName: String, rawParameters: [String]? = nil) {
    self.init(propertyName: propertyName, /*prefixKeyPath: nil,*/ value: .currentValue, rawParameters: rawParameters)
  }
}
