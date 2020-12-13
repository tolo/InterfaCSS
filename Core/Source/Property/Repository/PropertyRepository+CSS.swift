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


extension PropertyRepository {
  
  // MARK: - Register defaults
  
  func registerDefaultCSSProperties() {
    
    register(CompoundFontProperty())
    
    // TODO: More complex borders, like border-top-left-radius, border bottom-width (requires something like CAShapeLayer,
    // maybe best implemented using a special ViewClass)
    
    registerBlockProperty("border", type: .border) { (_, t, v, _) in  // Quasi-compound property
      t.layer.borderColor = v.color.cgColor
      t.layer.borderWidth = v.width
    }
    registerBlockProperty("border-color", type: .cgColor) { (_, t, v, _) in t.layer.borderColor = v }
    registerBlockProperty("border-width", type: .number) { (_, t, v, _) in t.layer.borderWidth = v.cgFloatValue }
    
    registerBlockProperty("border-radius", type: .number) { (_, t, v, _) in t.layer.cornerRadius = v.cgFloatValue }

    registerBlockProperty("color", in: UILabel.self, type: .color) { (_, t, v, _) in t.textColor = v }
    registerBlockProperty("color", in: UITextField.self, type: .color) { (_, t, v, _) in t.textColor = v }
    registerBlockProperty("color", in: UITextView.self, type: .color) { (_, t, v, _) in t.textColor = v }
    registerBlockProperty("color", in: UIButton.self, type: .color, params: [Self.controlStateTransformer]) { (_, t, v, args) in
      let controlState = args.first as? UIControl.State ?? UIControl.State.normal
      t.setTitleColor(v, for: controlState)
    }
    
    registerEnumBlockProperty("text-align", in: UILabel.self, enums: Self.textAlignmentMapping) { (_, t, v, _) in t.textAlignment = v }
    registerEnumBlockProperty("text-align", in: UITextField.self, enums: Self.textAlignmentMapping) { (_, t, v, _) in t.textAlignment = v }
    registerEnumBlockProperty("text-align", in: UITextView.self, enums: Self.textAlignmentMapping) { (_, t, v, _) in t.textAlignment = v }
    
    
    // TODO: background-image
    // TODO: text-shadow
    // TODO: box-shadow...
  }
}
