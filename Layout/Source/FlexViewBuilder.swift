//
//  FlexViewBuilder.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit
import YogaKit

extension UIView {
  fileprivate func markYogaViewTreeDirty() {
    yoga.markDirty()
    for sub in subviews {
      sub.markYogaViewTreeDirty()
    }
  }
}

extension YGDirection: StringParsableEnum {
  public typealias AllCases = [YGDirection]
  public static var allCases: YGDirection.AllCases {
    return [.inherit, .LTR, .RTL]
  }
  public var description: String {
    return String(cString: YGDirectionToString(self))
  }
}

extension YGFlexDirection: StringParsableEnum {
  public typealias AllCases = [YGFlexDirection]
  public static var allCases: YGFlexDirection.AllCases {
    return [.column, .columnReverse, .row, .rowReverse]
  }
  public var description: String {
    return String(cString: YGFlexDirectionToString(self))
  }
}

extension YGJustify: StringParsableEnum {
  public typealias AllCases = [YGJustify]
  public static var allCases: YGJustify.AllCases {
    return [.flexStart, .center, .flexEnd, .spaceBetween, .spaceAround, .spaceEvenly]
  }
  public var description: String {
    return String(cString: YGJustifyToString(self))
  }
}

extension YGAlign: StringParsableEnum {
  public typealias AllCases = [YGAlign]
  public static var allCases: YGAlign.AllCases {
    return [.auto, .flexStart, .center, .flexEnd, .stretch, .baseline, .spaceBetween, .spaceAround]
  }
  public var description: String {
    return String(cString: YGAlignToString(self))
  }
}

extension YGPositionType: StringParsableEnum {
  public typealias AllCases = [YGPositionType]
  public static var allCases: YGPositionType.AllCases {
    return [.relative, .absolute]
  }
  public var description: String {
    return String(cString: YGPositionTypeToString(self))
  }
}

extension YGWrap: StringParsableEnum {
  public typealias AllCases = [YGWrap]
  public static var allCases: YGWrap.AllCases {
    return [.noWrap, .wrap, .wrapReverse]
  }
  public var description: String {
    return String(cString: YGWrapToString(self))
  }
}

extension YGOverflow: StringParsableEnum {
  public typealias AllCases = [YGOverflow]
  public static var allCases: YGOverflow.AllCases { return [.visible, .hidden, .scroll] }
  public var description: String { return String(cString: YGOverflowToString(self)) }
}

extension YGDisplay: StringParsableEnum {
  public typealias AllCases = [YGDisplay]
  public static var allCases: YGDisplay.AllCases {
    return [.flex, .none]
  }
  public var description: String {
    return String(cString: YGDisplayToString(self))
  }
}

extension YGValue {
  public init(_ floatValue: CGFloat) {
    self.init(value: Float(floatValue), unit: .point)
  }

  public init(_ relativeNumber: RelativeNumber) {
    switch relativeNumber.unit {
    case .percent:
      self.init(value: relativeNumber.rawValue.floatValue, unit: .percent)
    case .auto:
      self.init(value: 0, unit: .auto)
    default:
      self.init(value: relativeNumber.value.floatValue, unit: .point)
    }
  }
}

private typealias CGFloatSetter = (Property, UIView, CGFloat) -> Void
private typealias YGValueSetter = (Property, UIView, YGValue) -> Void

public class FlexViewBuilder: ViewBuilder {
  
  private static var didRegisterFlexProperties: Bool = false

  public var enableFlexboxOnSubviews = true
  

  public required init(layoutFileURL: URL, refreshable: Bool = false, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared()) {
    super.init(layoutFileURL: layoutFileURL, refreshable: refreshable, fileOwner: fileOwner, styler: styler)

    if !FlexViewBuilder.didRegisterFlexProperties || styler.propertyManager.findProperty(withName: "flex-direction", in: UIView.self) == nil {
      FlexViewBuilder.didRegisterFlexProperties = true
      registerFlexProperties(forStyler: styler)
    }
  }
  
  private func registerFlexProperties(forStyler styler: Styler) {
    // TODO: Remove flex prefix on properties where it doesn't belong...
    
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
    
    registerNumberFlexProperty(withName: "flex-grow") { $1.yoga.flexGrow = $2 }
    registerNumberFlexProperty(withName: "flex-shrink") { $1.yoga.flexShrink = $2 }
    registerRelativeNumberFlexProperty(withName: "flex-basis") { $1.yoga.flexBasis = $2 }
    
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
    registerNumberFlexProperty(withName: "flex-aspect-ratio") { $1.yoga.aspectRatio = $2 }
  }

  private func registerEnumFlexProperty<EnumType: StringParsableEnum>(_ name: String, propertySetter: @escaping (Property, UIView, EnumType) -> Void) {
    registerFlexProperty(withName: name, type: .enumType) { (property, view, value) in
      guard let value = value as? String else {
        return false
      }
      propertySetter(property, view, EnumType.enumValueWithDefault(from: value))
      return true
    }
  }

  private func registerNumberFlexProperties(_ properties: [String: CGFloatSetter]) {
    for entry in properties {
      registerNumberFlexProperty(withName: entry.key, propertySetter: entry.value)
    }
  }

  private func registerNumberFlexProperty(withName name: String, propertySetter: @escaping CGFloatSetter) {
    registerFlexProperty(withName: name, type: .number) { (property, view, value) in
      guard let value = value as? NSNumber else {
        return false
      }
      propertySetter(property, view, CGFloat(value.doubleValue))
      return true
    }
  }

  private func registerRelativeNumberFlexProperties(_ properties: [String: YGValueSetter]) {
    for entry in properties {
      registerRelativeNumberFlexProperty(withName: entry.key, propertySetter: entry.value)
    }
  }

  private func registerRelativeNumberFlexProperty(withName name: String, propertySetter: @escaping YGValueSetter) {
    registerFlexProperty(withName: name, type: .relativeNumber) { (property, view, value) in
      guard let value = value as? RelativeNumber else {
        return false
      }
      propertySetter(property, view, YGValue(value))
      return true
    }
  }

  private func registerFlexProperty(withName name: String, type: PropertyType, propertySetter: @escaping (Property, UIView, Any) -> Bool) {
    let pm = styler.propertyManager
    guard pm.findProperty(withName: name, in: UIView.self) == nil else {
      return
    }

    let p = Property(customPropertyWithName: name, in: UIView.self, type: type, enumValueMapping: nil, parameterTransformers: nil) { (property, view, value, _) -> Bool in
      guard let view = view as? UIView, let value = value else {
        return false
      }
      if propertySetter(property, view, value) {
        view.yoga.isEnabled = true
        return true
      }
      return false
    }
    pm.register(p, in: UIView.self)
  }


  // MARK: - ViewBuilder
  
  override open func applyLayout(onView view: UIView) {
    super.applyLayout(onView: view)
    view.markYogaViewTreeDirty() // Needed to ensure layout is recalculated properly
    view.yoga.applyLayout(preservingOrigin: true)
    logger.logTrace(message: "Applied layout - view frame: \(view.frame)")
  }
  
  override open func calculateLayoutSize(forView view: UIView, fittingSize size: CGSize) -> CGSize {
    view.markYogaViewTreeDirty()
    return view.yoga.calculateLayout(with: size)
  }

  override open func createViewTree(withRootNode root: AbstractViewTreeNode, fileOwner: AnyObject? = nil) -> (UIView, [UIViewController])? {
    guard let (rootView, childViewControllers) = super.createViewTree(withRootNode: root, fileOwner: fileOwner) else {
      return nil
    }
    rootView.yoga.isEnabled = true // Ensure that yoga is always enabled for root view
    return (rootView, childViewControllers)
  }

  override open func addViewObject(_ viewObject: AnyObject, toParentView parentView: UIView, fileOwner: AnyObject?) {
    super.addViewObject(viewObject, toParentView: parentView, fileOwner: fileOwner)
    if enableFlexboxOnSubviews, let view = viewObject as? UIView {
      if parentView.yoga.isEnabled {
        view.yoga.isEnabled = true
      }
      styler.applyStyling(parentView) // Needed for above to work
    }
  }
}
