//
//  Property.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

  
public typealias PropertySetterBlock<TargetType, ValueType> = (_ property: Property, _ target: TargetType, _ value: ValueType, _ parameters: [Any]) -> Void
public typealias PropertyParameterTransformer = (_ rawValue: String) -> Any


/**
 * Represents the definition of a property that can be declared in a stylesheet.
 */
public class Property: CustomStringConvertible, CustomDebugStringConvertible, Hashable {
  
  public let name: String
  private (set) lazy var normalizedName: String = {
    return Self.normalizeName(name)
  }()
  
  public let declaredInClass: AnyClass
  private (set) lazy var fqn: String = {
    return "\(NSStringFromClass(declaredInClass.self)).\(name)"
  }()
  
  public let type: PropertyType
  public let propertySetter: PropertySetter
  
  public var description: String {
    return fqn
  }
  
  public var debugDescription: String {
    return "Property[\(description)]"
  }
  
  
  // MARK: - Initialization
  
  convenience init() {
    fatalError("Hold on there professor, init not allowed!")
  }
  
  public init(withName name: String, in clazz: AnyClass, type: PropertyType, propertySetter: PropertySetter) {
    self.name = name
    self.declaredInClass = clazz
    self.type = type
    self.propertySetter = propertySetter
  }
  
  public convenience init(runtimeProperty: RuntimeProperty, type: PropertyType, enumValueMapping: AnyPropertyEnumValueMappingType? = nil) {
    self.init(withName: runtimeProperty.propertyName, in: runtimeProperty.foundInClass, type: type,
              propertySetter: RuntimePropertySetter(runtimeProperty: runtimeProperty, enumValueMapping: enumValueMapping))
  }
  
  
  // MARK: - Set property value on target
  
  public func setValue(_ propertyValue: PropertyValue, onTarget target: AnyObject) {
    let value = type.parseAny(propertyValue: propertyValue)
    let params = propertyValue.rawParameters != nil ? transform(parameters: propertyValue.rawParameters!) : nil
    propertySetter.setValue(value, property: self, onTarget: target, withParameters: params)
  }
  
  
  // MARK: - Transformations utilities
  
  public func transform(parameters rawParams: [String]) -> [Any] {
    guard let parameterTransformers = self.propertySetter.parameterTransformers else { return Array.init(repeating: NSNull(), count: rawParams.count) }
    var transformedParameters: [Any] = []
    for i in 0..<parameterTransformers.count {
      let transformer = parameterTransformers[i]
      transformedParameters.append(transformer(i < rawParams.count ? rawParams[i] : ""))
    }
    return transformedParameters
  }
  
  public func transform(value: PropertyValue) -> Any? {
    return type.parseAny(propertyValue: value)
  }
    
  
  // MARK: - Hashable and Equatable
  
  public static func == (lhs: Property, rhs: Property) -> Bool {
    return lhs.fqn == rhs.fqn
  }
  
  public static func == (lhs: Property, rhs: PropertyValue) -> Bool {
    return lhs.normalizedName == rhs.propertyName
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(fqn)
  }
}

extension Property {
  class func normalizeName(_ name: String) -> String {
    return name.replacingOccurrences(of: "-", with: "").lowercased()
  }
}


/// PropertySetter
public protocol PropertySetter {
  var parameterTransformers: [PropertyParameterTransformer]? { get }
  
  func setValue(_ value: Any?, property: Property, onTarget target: AnyObject, withParameters params: [Any]?)
}

/// BlockSetter
public struct BlockSetter<TargetType, ValueType>: PropertySetter {
  public let parameterTransformers: [PropertyParameterTransformer]?
  public let setterBlock: PropertySetterBlock<TargetType, ValueType>
  
  public func setValue(_ _value: Any?, property: Property, onTarget _target: AnyObject, withParameters params: [Any]? = nil) {
    guard let target = _target as? TargetType, let value = _value as? ValueType else {
      Logger.properties.trace("Unable to apply property value '\(String(describing: _value))' to '\(property.fqn)' in '\(_target)' - expected target type \(TargetType.self), and value type \(ValueType.self)!")
      return
    }
    setterBlock(property, target, value, params ?? [])
  }
}

/// EnumBlockSetter
public struct EnumBlockSetter<TargetType, ValueType, EnumMappingType: PropertyEnumValueMappingType>: PropertySetter where EnumMappingType.EnumValueType == ValueType {
  public let enumValueMapping: EnumMappingType
  public let parameterTransformers: [PropertyParameterTransformer]?
  public let setterBlock: PropertySetterBlock<TargetType, ValueType>
  
  public func setValue(_ value: Any?, property: Property, onTarget _target: AnyObject, withParameters params: [Any]? = nil) {
    guard let target = _target as? TargetType else {
      Logger.properties.trace("Unable to apply property value '\(String(describing: value))' to '\(property.fqn)' in '\(_target)' - expected target type \(TargetType.self)!")
      return
    }
    let string: String = value as? String ?? String(describing: value)
    setterBlock(property, target, enumValueMapping.enumValue(from: string), params ?? [])
  }
}

/// RuntimePropertySetter
public struct RuntimePropertySetter: PropertySetter {
  public let runtimeProperty: RuntimeProperty
  public let enumValueMapping: AnyPropertyEnumValueMappingType?
  
  public var parameterTransformers: [PropertyParameterTransformer]? { nil }
  
  public func setValue(_ value: Any?, property: Property, onTarget target: AnyObject, withParameters params: [Any]? = nil) {
    var propertyValue: Any = value ?? NSNull()
    if let mapping = enumValueMapping, let val = value as? String {
      propertyValue = mapping.value(from: val)
    }
    if RuntimeIntrospectionUtils.invokeSetter(for: runtimeProperty, withValue: propertyValue, in: target) == false {
      Logger.properties.trace("Unable to apply property value to '\(property.fqn)' in '\(target)'!")
    }
  }
}

/// SelectorSetter
public struct SelectorSetter: PropertySetter {
  public let enumValueMapping: AnyPropertyEnumValueMappingType?
  public let parameterTransformers: [PropertyParameterTransformer]?
  public let selector: Foundation.Selector
  
  public func setValue(_ value: Any?, property: Property, onTarget target: AnyObject, withParameters params: [Any]? = nil) {
    var propertyValue: Any = value ?? NSNull()
    if let mapping = enumValueMapping, let val = value as? String {
      propertyValue = mapping.value(from: val)
    }
    let arguments = [propertyValue] + (params ?? [])
    RuntimeIntrospectionUtils.invokeInstanceSelector(selector, withArguments: arguments, in: target)
  }
}

