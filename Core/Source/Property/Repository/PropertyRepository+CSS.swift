//
//  PropertyRepository+CSS.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit
import Parsicle

private typealias P = AnyParsicle
private let S = StyleSheetParserSyntax.shared
private let identifier = S.identifier
private let anyName = S.anyName


class CompoundFontProperty: CompoundProperty {
  static let fontFamily = "font-family"
  static let fontWeight = "font-weight"
  // font-style (maybe)
  
  init() {
    super.init(name: "font", compoundNames: [Self.fontFamily, Self.fontWeight])
  }

}

extension PropertyRepository {
  
  // MARK: - Register defaults
  
  func registerDefaultCSSProperties() {
    
    register(CompoundFontProperty())
    
    
    // text-align
    // line-height
    
    // background-color
    // color
    
    // background-image
    
    // border-width
    // border-color
    // border-radius (also border-top-left-radius etc)
    // border
    
    // text-align
    // text-shadow
    
    // box-shadow...
  }
}
