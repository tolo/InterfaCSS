//
//  FlexViewBuilder.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit
import YogaKit


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
    logger.trace("Applied layout - view frame: \(view.frame)")
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
