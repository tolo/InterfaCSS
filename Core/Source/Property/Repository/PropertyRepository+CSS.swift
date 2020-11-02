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



//private typealias CGFloatSetter = (UIView, CGFloat) -> Void
private typealias TypedSetter<ViewType, ValueType> = (ViewType, ValueType) -> Void
private typealias TypedParameterizedSetter<ViewType, ValueType> = (ViewType, ValueType, [Any]) -> Void

extension PropertyRepository {
   
  
  private func _registerProperty<ViewType: UIView, ValueType>(_ name: String, _ type: TypedPropertyType<ValueType>, in clazz: ViewType.Type = ViewType.self, setter: @escaping TypedSetter<ViewType, ValueType>) {
    _register(name, in: clazz, type: type) { (_, view, value: ValueType, _) in
      setter(view, value)
    }
  }
  
  private func _registerProperty<ViewType: UIView, ValueType>(_ name: String, _ type: TypedPropertyType<ValueType>, in clazz: ViewType.Type = ViewType.self, setter: @escaping TypedParameterizedSetter<ViewType, ValueType>) {
    _register(name, in: clazz, type: type) { (_, view, value: ValueType, args) in
      setter(view, value, args)
    }
  }
  

  private static func setColor(_ property: Property, _ view: Any, _ color: UIColor, _ parameters: [Any]) {
    let controlState = parameters.first as? UIControl.State ?? UIControl.State.normal

    if let l = view as? UILabel { l.textColor = color }
    else if let l = view as? UITextField { l.textColor = color }
    else if let l = view as? UITextView { l.textColor = color }
    else if let l = view as? UIButton { l.setTitleColor(color, for: controlState) }
  }
  
  
  // MARK: - Register defaults
  
  func registerDefaultCSSProperties() {
    
    register(CompoundFontProperty())
        
    // TODO: More complex borders, like border-top-left-radius, border bottom-width (requires something like CAShapeLayer,
    // maybe best implemented using a special ViewClass)
    
    _registerProperty("border-color", .cgColor) { $0.layer.borderColor = $1 }
    
    _registerProperty("border-radius", .number) { $0.layer.cornerRadius = $1.cgFloatValue }
    _registerProperty("border-width", .number) { $0.layer.borderWidth = $1.cgFloatValue }
    
    _registerProperty("color", .color, in: UILabel.self) { $0.textColor = $1 }
    _registerProperty("color", .color, in: UITextField.self) { $0.textColor = $1 }
    _registerProperty("color", .color, in: UITextView.self) { $0.textColor = $1 }
    _registerProperty("color", .color, in: UIButton.self) { (t, v, args) in
      let controlState = args.first as? UIControl.State ?? UIControl.State.normal
      t.setTitleColor(v, for: controlState)
    }
    
    
    
    // TODO: background-image
    
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
    
    // TODO:
    // box-shadow...
  }
}
