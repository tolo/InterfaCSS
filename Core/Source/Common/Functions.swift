//
//  Functions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

func doublesEquals(_ a: Double, _ b: Double, upToNumberOfFractionalDigits : Int = 5) -> Bool {
  return fabs(a - b) < pow(10.0, Double(-upToNumberOfFractionalDigits))
}
