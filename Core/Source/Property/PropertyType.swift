//
//  PropertyType.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

public struct PropertyType : Hashable {
  public let type: String
  public let parser: PropertyTypeValueParser
  
  public init(_ type: String, parser: PropertyTypeValueParser) {
    self.type = type
    self.parser = parser
  }
  
  public static func == (lhs: PropertyType, rhs: PropertyType) -> Bool {
    return lhs.type == rhs.type
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(type)
  }
  
  static let string = PropertyType("String", parser: StringPropertyParser())
  static let bool = PropertyType("Bool", parser: BoolPropertyParser())
  static let number = PropertyType("Number", parser: NumberPropertyParser())
  static let relativeNumber = PropertyType("RelativeNumber", parser: RelativeNumberPropertyParser())
  static let color = PropertyType("Color", parser: UIColorPropertyParser())
  static let cgColor = PropertyType("CGColor", parser: CGColorPropertyParser())
  static let image = PropertyType("Image", parser: ImagePropertyParser())
  static let transform = PropertyType("Transform", parser: TransformPropertyParser())
  // TODO: Transform 3d?
  static let offset = PropertyType("Offset", parser: UIOffsetPropertyParser())
  static let rect = PropertyType("Rect", parser: CGRectPropertyParser())
  static let size = PropertyType("Size", parser: CGSizePropertyParser())
  static let point = PropertyType("Point", parser: CGPointPropertyParser())
  static let edgeInsets = PropertyType("EdgeInsets", parser: UIEdgeInsetsPropertyParser())
  static let font = PropertyType("Font", parser: UIFontPropertyParser())
  static let textAttributes = PropertyType("TextAttributes", parser: StringPropertyParser()) // TODO
  static let enumType = PropertyType("EnumType", parser: EnumPropertyParser())
  static let unknown = PropertyType("Unknown", parser: StringPropertyParser())
}

public protocol PropertyTypeValueParser {
   func parse(propertyValue: PropertyValue) -> Any?
}
