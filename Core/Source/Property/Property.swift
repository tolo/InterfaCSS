//
//  Property.swift
//  InterfaCSS-Core
//
//  Created by Tobias on 2019-02-12.
//  Copyright © 2019 Leafnode AB. All rights reserved.
//

import Foundation

  
public typealias PropertySetterBlock = (_ property: Property, _ target: AnyObject, _ value: Any?, _ parameters: [Any]) -> Bool
public typealias TypedNeverFailingPropertySetterBlock<TargetType, ValueType> = (_ property: Property, _ target: TargetType, _ value: ValueType, _ parameters: [Any]) -> Void
public typealias PropertyParameterTransformer = (_ property: Property, _ rawValue: String) -> Any


/**
 * Represents the definition of a property that can be declared in a stylesheet.
 */
public class Property: CustomStringConvertible, CustomDebugStringConvertible {
  
  public let name: String
  public var normalizedName: String {
    return Self.normalizeName(name)
  }
  
  public let declaredInClass: AnyClass
  var fqn: String {
    return "\(NSStringFromClass(declaredInClass.self)).\(name)"
  }
  
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
  
  public convenience init(withCompoundName compoundName: String, type: PropertyType) {
    self.init(withName: name, in: Property.self, type: type) { (_, _ : AnyObject, _ : Any? , _) in }
  }
  
  public func transformParameters(_ rawParams: [String]) -> [Any] {
    guard let parameterTransformers = self.parameterTransformers else { return Array.init(repeating: NSNull(), count: rawParams.count) }
    var transformedParameters: [Any] = []
    for i in 0..<parameterTransformers.count {
      let transformer = parameterTransformers[i]
      transformedParameters.append(transformer(self, i < rawParams.count ? rawParams[i] : ""))
    }
    return transformedParameters
  }
  
  public func setValue(_ value: Any?, onTarget target: AnyObject, withParameters params: [Any]? = nil) -> Bool {
    return setterBlock(self, target, value, params ?? [])
  }
}

extension Property {
  class func normalizeName(_ name: String) -> String {
    return name.replacingOccurrences(of: "-", with: "").lowercased()
  }
}
