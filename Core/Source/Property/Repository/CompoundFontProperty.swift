//
//  CompoundFontProperty.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


class CompoundFontProperty: CompoundProperty {
  static let fontScalingStyle = "fontscalingstyle" /// font-scaling-style, support for dynamic font scaling
  // TODO: font-style, i.e italic / oblique
  // TODO: perhaps: font-variant, support for small caps etc (https://stackoverflow.com/questions/52994415/enabling-small-caps-font-in-uilabel)
  static let fontWeight = "fontweight" /// font-weight
  static let fontSize = "fontsize" /// font-size
  static let fontFamily = "fontfamily" /// font-family
  
  init() {
    super.init(name: "font", compoundNames: [Self.fontScalingStyle, Self.fontWeight, Self.fontSize, Self.fontFamily])
  }
  
  override func resolve(propertyValues: [PropertyValue]) -> Any? {
    let values = rawValues(from: propertyValues)
    return CompoundFontPropertyValue(name: values[CompoundFontProperty.fontFamily], size: values[CompoundFontProperty.fontSize],
                                     weight: values[CompoundFontProperty.fontWeight], scalingTextStyle: values[CompoundFontProperty.fontScalingStyle])
  }
}

struct CompoundFontPropertyValue {
  let name: String?
  let size: String?
  let weight: String?
  let scalingTextStyle: String?
}
