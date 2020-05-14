//
//  Property.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

  
public typealias PropertySetterBlock = (_ property: Property, _ target: AnyObject, _ value: Any?, _ parameters: [Any]) -> Bool
public typealias TypedNeverFailingPropertySetterBlock<TargetType, ValueType> = (_ property: Property, _ target: TargetType, _ value: ValueType, _ parameters: [Any]) -> Void
public typealias PropertyParameterTransformer = (_ property: Property, _ rawValue: String) -> Any


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
  public let enumValueMapping: AnyPropertyEnumValueMappingType?
  public let parameterTransformers: [PropertyParameterTransformer]?
  public let setterBlock: PropertySetterBlock
  
  public var description: String {
    return fqn
  }
  
  public var debugDescription: String {
    return "Property[\(description)]"
  }
  
  
  convenience init() {
    fatalError("Hold on there professor, init not allowed!")
  }
  
  public init(withName name: String, in clazz: AnyClass, type: PropertyType, enumValueMapping: AnyPropertyEnumValueMappingType? = nil,
              parameterTransformers: [PropertyParameterTransformer]? = nil, setterBlock setter: @escaping PropertySetterBlock) {
    self.name = name
    self.declaredInClass = clazz
    self.type = type
    self.enumValueMapping = enumValueMapping
    self.parameterTransformers = parameterTransformers
    self.setterBlock = setter
  }
  
  public convenience init<TargetType, ValueType>(withName name: String, in clazz: AnyClass, type: PropertyType, enumValueMapping: AnyPropertyEnumValueMappingType? = nil,
                                                 parameterTransformers: [PropertyParameterTransformer]? = nil, setterBlock typedSetter: @escaping TypedNeverFailingPropertySetterBlock<TargetType, ValueType>) {
    let setter: PropertySetterBlock = { (propery, target, value, parameters) in
      guard let target = target as? TargetType, let value = value as? ValueType else { return false }
      typedSetter(propery, target, value, parameters)
      return true
    }
    self.init(withName: name, in: clazz, type: type, enumValueMapping: enumValueMapping, parameterTransformers: parameterTransformers, setterBlock: setter)
  }
  
  public convenience init(runtimeProperty: RuntimeProperty, type: PropertyType, enumValueMapping: AnyPropertyEnumValueMappingType? = nil) {
    self.init(withName: runtimeProperty.propertyName, in: runtimeProperty.foundInClass, type: type, enumValueMapping: enumValueMapping, parameterTransformers: nil, setterBlock: { property, target, value, parameters in
      var propertyValue: Any = value ?? NSNull()
      if let mapping = enumValueMapping, let val = value as? String {
        propertyValue = mapping.value(from: val)
      }
      return RuntimeIntrospectionUtils.invokeSetter(for: runtimeProperty, withValue: propertyValue, in: target)
    })
  }
  
  public convenience init(withName name: String, in clazz: AnyClass, type: PropertyType, selector: Foundation.Selector, enumValueMapping: AnyPropertyEnumValueMappingType? = nil, parameterTransformers: [PropertyParameterTransformer]? = nil) {
    self.init(withName: name, in: clazz, type: type, enumValueMapping: enumValueMapping, parameterTransformers: parameterTransformers, setterBlock: { property, target, value, parameters in
      let arguments = [value ?? NSNull()] + parameters
      RuntimeIntrospectionUtils.invokeInstanceSelector(selector, withArguments: arguments, in: target)
      return true
    })
  }
  
//  public convenience init(withCompoundName compoundName: String, type: PropertyType) {
//    let setter: PropertySetterBlock = { (_, _ : AnyObject, _ : Any? , _) -> Bool in return true }
//    self.init(withName: compoundName, in: AnyObject.self, type: type, setterBlock: setter)
//  }
  
  
  public func transform(parameters rawParams: [String]) -> [Any] {
    guard let parameterTransformers = self.parameterTransformers else { return Array.init(repeating: NSNull(), count: rawParams.count) }
    var transformedParameters: [Any] = []
    for i in 0..<parameterTransformers.count {
      let transformer = parameterTransformers[i]
      transformedParameters.append(transformer(self, i < rawParams.count ? rawParams[i] : ""))
    }
    return transformedParameters
  }
  
  public func transform(value: PropertyValue) -> Any? {
    return type.parser.parse(propertyValue: value)
  }
  
//  public func setValue(_ value: PropertyValue, onTarget target: AnyObject) -> Bool {
//    let value = type.parser.parse(propertyValue: value)
//    return setValue(value, onTarget: target, withParameters: )
//  }
  
  public func setValue(_ value: Any?, onTarget target: AnyObject, withParameters params: [Any]? = nil) -> Bool {
    return setterBlock(self, target, value, params ?? [])
  }
  
  /// Hashable and Equatable
  
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
