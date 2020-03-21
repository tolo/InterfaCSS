//
//  StyleSheetContent.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

public struct StyleSheetContent {
  public static let empty: StyleSheetContent = { StyleSheetContent(rulesets: [], variables: [:]) }()
  
  public var rulesets: [Ruleset]
  public var variables: [String: String]
  
  mutating public func setValue(_ value: String, forStyleSheetVariableWithName variable: String) {
    variables[variable] = value;
  }
}
