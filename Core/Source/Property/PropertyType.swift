//
//  PropertyType.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

public class PropertyType: Hashable {
  public let type: String
  public let parser: PropertyTypeValueParser
  
  public init(_ type: String, parser: PropertyTypeValueParser) {
    self.type = type
    self.parser = parser
  }
  
  public func parseAny(propertyValue: PropertyValue) -> Any? {
    return parser.parseAny(propertyValue: propertyValue)
  }
    
  public static func == (lhs: PropertyType, rhs: PropertyType) -> Bool {
    return lhs.type == rhs.type
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(type)
  }
}


extension PropertyType {
  public static let string = TypedPropertyType("String", parser: StringPropertyParser())
  public static let bool = TypedPropertyType("Bool", parser: BoolPropertyParser())
  public static let number = TypedPropertyType("Number", parser: NumberPropertyParser())
  public static let relativeNumber = TypedPropertyType("RelativeNumber", parser: RelativeNumberPropertyParser())
  public static let color = TypedPropertyType("Color", parser: UIColorPropertyParser())
  public static let cgColor = TypedPropertyType("CGColor", parser: CGColorPropertyParser())
  public static let image = TypedPropertyType("Image", parser: ImagePropertyParser())
  public static let transform = TypedPropertyType("Transform", parser: TransformPropertyParser())
  // TODO: Transform 3d?
  public static let offset = TypedPropertyType("Offset", parser: UIOffsetPropertyParser())
  public static let rect = TypedPropertyType("Rect", parser: CGRectPropertyParser())
  public static let size = TypedPropertyType("Size", parser: CGSizePropertyParser())
  public static let point = TypedPropertyType("Point", parser: CGPointPropertyParser())
  public static let edgeInsets = TypedPropertyType("EdgeInsets", parser: UIEdgeInsetsPropertyParser())
  public static let font = TypedPropertyType("Font", parser: UIFontPropertyParser())
  public static let border = TypedPropertyType("Border", parser: BorderPropertyParser())
  public static let textAttributes = TypedPropertyType("TextAttributes", parser: StringPropertyParser()) // TODO
  public static let enumType = TypedPropertyType("EnumType", parser: EnumPropertyParser())
  public static let unknown = TypedPropertyType("Unknown", parser: StringPropertyParser())
}


public class TypedPropertyType<T>: PropertyType {
  public var typedParser: TypedPropertyParser<T> { parser as! TypedPropertyParser<T> }
  
  public init(_ type: String, parser: TypedPropertyParser<T>) {
    super.init(type, parser: parser)
  }
  
  public func parse(propertyValue: PropertyValue) -> T? {
    return typedParser.parse(propertyValue: propertyValue)
  }
}


public protocol PropertyTypeValueParser {
  func parseAny(propertyValue: PropertyValue) -> Any?
}


public class TypedPropertyParser<ParsedType>: PropertyTypeValueParser {
  public func parseAny(propertyValue: PropertyValue) -> Any? {
    return parse(propertyValue: propertyValue)
  }

  public func parse(propertyValue: PropertyValue) -> ParsedType? { return nil }
}
