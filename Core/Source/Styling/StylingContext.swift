//
//  StylingContext.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

public class StylingContext {
  // MARK: - Input
  public let styler: Styler
  
  public let styleSheetScope: StyleSheetScope
  public let ignorePseudoClasses: Bool
  
  // MARK: - Output
  public var containsPartiallyMatchedDeclarations = false
  public var stylesCacheable = false
  
  // TODO: Last matching pseudo - for used when for instace setting control state dependent properties...
  
  // MARK: - Convenience
  public var propertyManager: PropertyManager { styler.propertyManager }
  public var styleSheetManager: StyleSheetManager { styler.styleSheetManager }
  
  // MARK: - Creation
  
  public init(styler: Styler, styleSheetScope: StyleSheetScope = .all, ignorePseudoClasses: Bool = false) {
    self.styler = styler
    self.styleSheetScope = styleSheetScope
    self.ignorePseudoClasses = ignorePseudoClasses
    
    containsPartiallyMatchedDeclarations = false
    stylesCacheable = true
  }
}
