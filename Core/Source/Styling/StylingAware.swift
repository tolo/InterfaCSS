//
//  StylingAware.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

public protocol StylingAware {
  
  /// Called when styling has been applied to this element and all its children
  func didApplyStyling(withStyler styler: Styler)
  
}
