//
//  UIFont+Additions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit

internal extension UIFont {
  
  func scaledFont(for textStyle: UIFont.TextStyle, maxSize: CGFloat? = nil) -> UIFont {
    if let maxSize = maxSize {
      return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: self, maximumPointSize: maxSize)
    } else {
      return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: self)
    }
  }
  
  func scaledFont(maxSize: CGFloat? = nil) -> UIFont {
    if let maxSize = maxSize {
      return UIFontMetrics.default.scaledFont(for: self, maximumPointSize: maxSize)
    } else {
      return UIFontMetrics.default.scaledFont(for: self)
    }
  }
  
}
