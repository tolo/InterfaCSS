//
//  PropertyEnumValueMapping.swift
//  InterfaCSS-Core
//
//  Created by Tobias on 2019-02-12.
//  Copyright © 2019 Leafnode AB. All rights reserved.
//

import Foundation


public protocol AnyPropertyEnumValueMappingType {
  func value(from string: String) -> Any
}

public protocol PropertyEnumValueMappingType: AnyPropertyEnumValueMappingType {
  associatedtype EnumValueType: RawRepresentable
  func enumValue(from string: String) -> EnumValueType
}

extension PropertyEnumValueMappingType {
  public func value(from string: String) -> Any {
    return enumValue(from: string).rawValue
  }
}

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

var bitMaskEnumValueSeparator: CharacterSet = {
  CharacterSet(charactersIn: " |-")
}()

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
