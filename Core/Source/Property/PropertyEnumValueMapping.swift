//
//  PropertyEnumValueMapping.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


/// AnyPropertyEnumValueMappingType
public protocol AnyPropertyEnumValueMappingType {
  func value(from string: String) -> Any
}

extension AnyPropertyEnumValueMappingType {
  func toParameterTransformer() -> PropertyParameterTransformer {
    return { [self] in self.value(from: $0) }
  }
}


/// PropertyEnumValueMappingType
public protocol PropertyEnumValueMappingType: AnyPropertyEnumValueMappingType {
  associatedtype EnumValueType: RawRepresentable
  func enumValue(from string: String) -> EnumValueType
}

extension PropertyEnumValueMappingType {
  public func value(from string: String) -> Any {
    return enumValue(from: string).rawValue
  }
}


/// PropertyEnumValueMapping
public class PropertyEnumValueMapping<EnumType: RawRepresentable>: PropertyEnumValueMappingType {
  public typealias EnumValueType = EnumType
  public let enumValues: [String : EnumType]
  public let enumBaseName: String?
  public let defaultValue: EnumType
  
  public init(enumValues: [String : EnumType], enumBaseName: String? = nil, defaultValue: EnumType) {
    self.enumValues = enumValues.dictionaryWithLowerCaseKeys()
    self.enumBaseName = enumBaseName?.lowercased()
    self.defaultValue = defaultValue
  }
  
  public func enumValue(from string: String) -> EnumType {
    let lcEnumName = string.lowercased()
    var value = enumValues[lcEnumName]
    if value == nil, let enumBaseName = enumBaseName, lcEnumName.hasPrefix(enumBaseName) {
      value = enumValues[lcEnumName.substring(from: enumBaseName.count).str]
    }
    return value ?? defaultValue
  }
}


/// StringParsableEnumValueMapping
public class StringParsableEnumValueMapping<EnumType: StringParsableEnum>: PropertyEnumValueMappingType {
  public typealias EnumValueType = EnumType
  public let enumBaseName: String?
  
  public init(enumBaseName: String? = nil) {
    self.enumBaseName = enumBaseName?.lowercased()
  }
    
  public func enumValue(from string: String) -> EnumValueType {
    if let enumBaseName = enumBaseName {
      if let enumValue = EnumType.enumValue(from: string) { return enumValue }
      else if string.lowercased().hasPrefix(enumBaseName) { return EnumType.enumValueWithDefault(from: string.substring(from: enumBaseName.count).str) }
    }
    return EnumType.enumValueWithDefault(from: string)
  }
}


/// PropertyBitMaskEnumValueMapping
public class PropertyBitMaskEnumValueMapping<EnumType: OptionSet>: PropertyEnumValueMapping<EnumType> /*where EnumType.RawValue == UInt*/ {
  
  public override func enumValue(from string: String) -> EnumType {
    let stringValues = string.lowercased().components(separatedBy: bitMaskEnumValueSeparator)
    var result: EnumType = []
    for stringValue in stringValues {
      let enumValue = super.enumValue(from: stringValue)
      result = result.union(enumValue)
    }
    return result.isEmpty ? defaultValue : result
  }
}

let bitMaskEnumValueSeparator: CharacterSet = {
  CharacterSet(charactersIn: " |-")
}()
