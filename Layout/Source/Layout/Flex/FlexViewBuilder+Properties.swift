//
//  FlexViewBuilder+Properties.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit
import YogaKit


private typealias CGFloatSetter = (Property, UIView, CGFloat) -> Void
private typealias YGValueSetter = (Property, UIView, YGValue) -> Void


extension FlexViewBuilder {
  
  private var pm: PropertyManager { styler.propertyManager }
  
  func registerFlexProperties(forStyler styler: Styler) {
    // TODO: Remove flex prefix on properties where it doesn't belong...
    // TODO: flex, margin, padding, border shorthand properties
    // TODO: width, height, top, left, right, bottom
    registerEnumFlexProperty("flex-layout-direction") { $1.yoga.direction = $2 }
    registerEnumFlexProperty("flex-direction") { $1.yoga.flexDirection = $2 }
    registerEnumFlexProperty("justify-content") { $1.yoga.justifyContent = $2 }
    registerEnumFlexProperty("align-content") { $1.yoga.alignContent = $2 }
    registerEnumFlexProperty("align-items") { $1.yoga.alignItems = $2 }
    registerEnumFlexProperty("align-self") { $1.yoga.alignSelf = $2 }
    registerEnumFlexProperty("position") { $1.yoga.position = $2 }
    registerEnumFlexProperty("flex-wrap") { $1.yoga.flexWrap = $2 }
    registerEnumFlexProperty("overflow") { $1.yoga.overflow = $2 }
    registerEnumFlexProperty("display") { $1.yoga.display = $2 }
    
    registerNumberFlexProperty("flex-grow") { $1.yoga.flexGrow = $2 }
    registerNumberFlexProperty("flex-shrink") { $1.yoga.flexShrink = $2 }
    registerRelativeNumberFlexProperty("flex-basis") { $1.yoga.flexBasis = $2 }
    
    registerRelativeNumberFlexProperties(["flex-left": { $1.yoga.left = $2 }, "flex-top": { $1.yoga.top = $2 },
                                          "flex-right": { $1.yoga.right = $2 }, "flex-bottom": { $1.yoga.bottom = $2 },
                                          "flex-start": { $1.yoga.start = $2 }, "flex-end": { $1.yoga.end = $2 }])
    
    registerRelativeNumberFlexProperties(["margin-left": { $1.yoga.marginLeft = $2 }, "margin-top": { $1.yoga.marginTop = $2 },
                                          "margin-right": { $1.yoga.marginRight = $2 }, "margin-bottom": { $1.yoga.marginBottom = $2 },
                                          "margin-start": { $1.yoga.marginStart = $2 }, "margin-end": { $1.yoga.marginEnd = $2 },
                                          "margin-horizontal": { $1.yoga.marginHorizontal = $2 }, "margin-vertical": { $1.yoga.marginVertical = $2 },
                                          "margin": { $1.yoga.margin = $2 }])
    
    registerRelativeNumberFlexProperties(["padding-left": { $1.yoga.paddingLeft = $2 }, "padding-top": { $1.yoga.paddingTop = $2 },
                                          "padding-right": { $1.yoga.paddingRight = $2 }, "padding-bottom": { $1.yoga.paddingBottom = $2 },
                                          "padding-start": { $1.yoga.paddingStart = $2 }, "padding-end": { $1.yoga.paddingEnd = $2 },
                                          "padding-horizontal": { $1.yoga.paddingHorizontal = $2 }, "padding-vertical": { $1.yoga.paddingVertical = $2 },
                                          "padding": { $1.yoga.padding = $2 }])
    
    registerNumberFlexProperties(["border-left": { $1.yoga.borderLeftWidth = $2 }, "border-top": { $1.yoga.borderTopWidth = $2 },
                                  "border-right": { $1.yoga.borderRightWidth = $2 }, "border-bottom": { $1.yoga.borderBottomWidth = $2 },
                                  "border-start": { $1.yoga.borderStartWidth = $2 }, "border-end": { $1.yoga.borderEndWidth = $2 },
                                  "border": { $1.yoga.borderWidth = $2 }])
    
    registerRelativeNumberFlexProperties(["flex-width": { $1.yoga.width = $2 }, "flex-height": { $1.yoga.height = $2 },
                                          "flex-min-width": { $1.yoga.minWidth = $2 }, "flex-min-height": { $1.yoga.minHeight = $2 },
                                          "flex-max-width": { $1.yoga.maxWidth = $2 }, "flex-max-height": { $1.yoga.maxHeight = $2 }])
    
    // Yoga specific properties, not compatible with flexbox specification
    registerNumberFlexProperty("flex-aspect-ratio") { $1.yoga.aspectRatio = $2 }
  }
  
  
  private func registerNumberFlexProperties(_ properties: [String: CGFloatSetter]) {
    properties.forEach { registerNumberFlexProperty($0.key, propertySetter: $0.value) }
  }
  
  private func registerNumberFlexProperty(_ name: String, propertySetter: @escaping CGFloatSetter) {
    registerFlexProperty(name, type: .number) { (p, view, value) in
      propertySetter(p, view, CGFloat(value.doubleValue))
    }
  }
  
  private func registerRelativeNumberFlexProperties(_ properties: [String: YGValueSetter]) {
    properties.forEach { registerRelativeNumberFlexProperty($0.key, propertySetter: $0.value) }
  }
  
  private func registerRelativeNumberFlexProperty(_ name: String, propertySetter: @escaping YGValueSetter) {
    registerFlexProperty(name, type: .relativeNumber) { (p, view, value) in
      propertySetter(p, view, YGValue(value))
    }
  }
  
  private func registerEnumFlexProperty<ValueType: StringParsableEnum>(_ name: String, propertySetter: @escaping (Property, UIView, ValueType) -> Void) {
    guard pm.findProperty(withName: name, in: UIView.self) == nil else { return }
    pm.propertyRepository.registerEnumBlockProperty(name, enums: StringParsableEnumValueMapping<ValueType>()) { (property, view, value, _) in
      propertySetter(property, view, value)
      view.yoga.isEnabled = true
    }
  }
  
  private func registerFlexProperty<ValueType>(_ name: String, type: TypedPropertyType<ValueType>, propertySetter: @escaping (Property, UIView, ValueType) -> Void) {
    guard pm.findProperty(withName: name, in: UIView.self) == nil else { return }
    pm.propertyRepository.registerBlockProperty(name, type: type) { (property, view, value, _) in
      propertySetter(property, view, value)
      view.yoga.isEnabled = true
    }
  }
}
