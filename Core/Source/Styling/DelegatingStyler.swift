//
//  DelegatingStyler.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

// TODO: Rename? Only use a concret styler and no protocol?

public class DelegatingStyler: Styler {
  private let stylingManager: StylingManager
  
  public let styleSheetScope: StyleSheetScope
  
  public var propertyManager: PropertyManager { return stylingManager.propertyManager }
  public var styleSheetManager: StyleSheetManager { return stylingManager.styleSheetManager }
  
  public init(stylingManager: StylingManager, styleSheetScope: StyleSheetScope) {
    self.stylingManager = stylingManager
    self.styleSheetScope = styleSheetScope
  }
  
  public func styler(withScope styleSheetScope: StyleSheetScope) -> DelegatingStyler {
    return DelegatingStyler(stylingManager: stylingManager, styleSheetScope: styleSheetScope)
  }
  
  public func style(for uiElement: Stylable) -> ElementStyle {
    return stylingManager.style(for: uiElement)
  }
  
  public func applyStyling(_ uiElement: Stylable, includeSubViews: Bool = true, force: Bool = false) {
    stylingManager.applyStyling(uiElement, includeSubViews: includeSubViews, force: force, styleSheetScope: styleSheetScope)
  }
  
  public func clearCachedStylingInformation(for uiElement: Stylable, includeSubViews: Bool = true) {
    stylingManager.clearCachedStylingInformation(for: uiElement, includeSubViews: includeSubViews)
  }
}
