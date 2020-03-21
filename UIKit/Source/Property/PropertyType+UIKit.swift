//
//  PropertyType+UIKit.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

extension PropertyType {
  static let textAttributes = PropertyType("TextAttributes")
  static let offset = PropertyType("Offset")
  static let rect = PropertyType("Rect")
  static let size = PropertyType("Size")
  static let point = PropertyType("Point")
  static let edgeInsets = PropertyType("EdgeInsets")
  static let font = PropertyType("Font")
  static let unknown = PropertyType("Unknown")
}
