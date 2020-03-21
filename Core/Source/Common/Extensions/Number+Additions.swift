//
//  Double+Additions.swift
//  InterfaCSS-Core
//
//  Created by Tobias on 2019-04-18.
//  Copyright © 2019 Leafnode AB. All rights reserved.
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
