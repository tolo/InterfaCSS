//
//  UIResponder+InterfaCSS.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit

// TODO: Move into core...
public extension UIResponder {
  
  public func applyStyling(usingStyler styler: Styler = StylingManager.shared()) {
    styler.applyStyling(self)
  }
  
}
