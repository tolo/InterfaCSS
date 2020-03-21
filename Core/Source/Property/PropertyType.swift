//
//  PropertyType.swift
//  InterfaCSS-Core
//
//  Created by Tobias on 2019-02-12.
//  Copyright © 2019 Leafnode AB. All rights reserved.
//

import Foundation

// TODO: Only define some property types here?
// TODO: Compound property support
public struct PropertyType : Hashable, Equatable, RawRepresentable {
  public typealias RawValue = String
  public let rawValue: String
  
  public init(_ rawValue: RawValue) {
    self.rawValue = rawValue
  }
  
  public init?(rawValue: RawValue) {
    self.rawValue = rawValue
  }
  
  static let string = PropertyType("String")
  static let bool = PropertyType("Bool")
  static let number = PropertyType("Number")
  static let relativeNumber = PropertyType("RelativeNumber")
  static let color = PropertyType("Color")
  static let cgColor = PropertyType("CGColor")
  static let image = PropertyType("Image")
  static let transform = PropertyType("Transform") // TODO: Transform 3d?
  static let enumType = PropertyType("EnumType")
}

struct ComplexProperty {
  
  let properties: [Property]
  
  
}
