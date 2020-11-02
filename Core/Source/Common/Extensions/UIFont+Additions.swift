//
//  UIFont+Additions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit

internal extension UIFont {
  
  func scaledFont(for textStyle: UIFont.TextStyle) -> UIFont {
    return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: self)
  }
  
  func scaledFont() -> UIFont {
    return UIFontMetrics.default.scaledFont(for: self)
  }
  
}
