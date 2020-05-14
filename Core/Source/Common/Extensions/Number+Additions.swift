//
//  Double+Additions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit

extension Double {
  func isEqualToWithScreenPrecision(_ other: Double) -> Bool {
    return self.isEqualTo(other, upToNumberOfFractionalDigits: 3)
  }
  
  func isEqualTo(_ other: Double, upToNumberOfFractionalDigits : Int) -> Bool {
    return fabs(self - other) < pow(10.0, Double(-upToNumberOfFractionalDigits))
  }
  
}

extension CGFloat {
  func isEqualToWithScreenPrecision(_ other: CGFloat) -> Bool {
    return Double(self).isEqualToWithScreenPrecision(Double(other))
  }
}
