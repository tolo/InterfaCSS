//
//  DelegatingStyler.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

public class DelegatingStyler: Styler {
  private let styler: Styler
  
  public let styleSheetScope: StyleSheetScope
  
  public var propertyManager: PropertyManager { return styler.propertyManager }
  public var styleSheetManager: StyleSheetManager { return styler.styleSheetManager }
  
  public init(styler: Styler, styleSheetScope: StyleSheetScope) {
    self.styler = styler
    self.styleSheetScope = styleSheetScope
  }
  
  public func styler(with styleSheetScope: StyleSheetScope, includeCurrent: Bool = true) -> Styler {
    let scope = includeCurrent ? self.styleSheetScope.including(styleSheetScope) : styleSheetScope
    return DelegatingStyler(styler: styler, styleSheetScope: scope)
  }
  
  public func stylingProxy(for uiElement: Stylable) -> ElementStyle {
    return styler.stylingProxy(for: uiElement)
  }
  
  public func applyStyling(_ uiElement: Stylable, includeSubViews: Bool, force: Bool, styleSheetScope: StyleSheetScope?) {
    styler.applyStyling(uiElement, includeSubViews: includeSubViews, force: force, styleSheetScope: styleSheetScope)
  }
  
  public func clearCachedStylingInformation(for uiElement: Stylable, includeSubViews: Bool) {
    styler.clearCachedStylingInformation(for: uiElement, includeSubViews: includeSubViews)
  }
}
