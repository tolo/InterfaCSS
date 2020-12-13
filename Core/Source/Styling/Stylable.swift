//
//  Stylable.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import ObjectiveC
import UIKit


private struct AssociatedKeys {
  static var interfaCSSStoredPropertyKey: UInt8 = 0
}


/**
 *
 */
public protocol Stylable: AnyObject {
  var interfaCSS: ElementStyle { get set }
}

public extension Stylable {
  
  var interfaCSS: ElementStyle {
    get {
      return objc_getAssociatedObject(self, &AssociatedKeys.interfaCSSStoredPropertyKey) as? ElementStyle ?? {
        let stylingProxy = ElementStyle(uiElement: self)
        self.interfaCSS = stylingProxy
        return stylingProxy
      }()
    }
    set {
      objc_setAssociatedObject(self, &AssociatedKeys.interfaCSSStoredPropertyKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

extension UIResponder: Stylable {}
extension UIBarItem: Stylable {}
extension CALayer: Stylable {}
