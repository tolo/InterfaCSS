//
//  FlexViewBuilder.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit
import YogaKit


private typealias CGFloatSetter = (Property, UIView, CGFloat) -> Void
private typealias YGValueSetter = (Property, UIView, YGValue) -> Void

/**
 * View builder with support for CSS flexbox layout.
 */
public class FlexViewBuilder: ViewBuilder {
  
  private static var didRegisterFlexProperties: Bool = false

  public var enableFlexboxOnSubviews = true
  

  public required init(layoutFileURL: URL, refreshable: Bool = false, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared) {
    super.init(layoutFileURL: layoutFileURL, refreshable: refreshable, fileOwner: fileOwner, styler: styler)

    if !FlexViewBuilder.didRegisterFlexProperties || styler.propertyManager.findProperty(withName: "flex-direction", in: UIView.self) == nil {
      FlexViewBuilder.didRegisterFlexProperties = true
      registerFlexProperties(forStyler: styler)
    }
  }
  
  private func registerFlexProperties(forStyler styler: Styler) {
    // TODO: Remove flex prefix on properties where it doesn't belong...
    // TODO: flex, margin, padding, border shorthand properties
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

  @discardableResult
  private func registerFlexProperty(withName name: String, type: PropertyType, propertySetter: @escaping (Property, UIView, Any) -> Bool) -> Property? {
    let pm = styler.propertyManager
    guard pm.findProperty(withName: name, in: UIView.self) == nil else {
      return nil
    }

    let p = Property(withName: name, in: UIView.self, type: type, enumValueMapping: nil, parameterTransformers: nil) { (property, view, value, _) -> Bool in
      guard let view = view as? UIView, let value = value else {
        return false
      }
      if propertySetter(property, view, value) {
        view.yoga.isEnabled = true
        return true
      }
      return false
    }
    return pm.register(p)
  }


  // MARK: - ViewBuilder
  
  override open func applyLayout(onView view: UIView, layoutDimension: LayoutDimension = .both) {
    super.applyLayout(onView: view)
    view.markYogaViewTreeDirty() // Needed to ensure layout is recalculated properly
    if layoutDimension == .both {
      view.yoga.applyLayout(preservingOrigin: true)
    } else {
      view.yoga.applyLayout(preservingOrigin: true,
                            dimensionFlexibility: layoutDimension == .width ? .flexibleWidth : .flexibleHeight)
    }
    logger.debug("Applied layout - view frame: \(view.frame)")
  }
  
  override open func calculateLayoutSize(forView view: UIView, fittingSize size: CGSize, layoutDimension: LayoutDimension = .both) -> CGSize {
    view.markYogaViewTreeDirty()
    if layoutDimension == .both {
      return view.yoga.calculateLayout(with: size)
    } else {
      return view.yoga.calculateLayout(with:
        CGSize(width: layoutDimension == .width ? CGFloat(YGValueUndefined.value) : size.width,
               height: layoutDimension == .height ? CGFloat(YGValueUndefined.value) : size.height))
    }
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
