//
//  Ruleset.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

/**
 * Represents a rule set (i.e. a set of selectors/selector chains and a style declarations block) in a stylesheet.
 */
public final class Ruleset: CustomStringConvertible, CustomDebugStringConvertible { // TODO: "Cannot" currently be struct due to extendedDeclaration...
  
  public let selectorChains: [SelectorChain]
  
  private let _properties: [PropertyValue]
  public var properties: [PropertyValue] {
    if let extendedDeclaration = extendedDeclaration, extendedDeclaration !== self {
      return _properties + extendedDeclaration._properties
    } else {
      return _properties
    }
  }
  
  public let containsPseudoClassSelector: Bool
  
  public let extendedDeclarationSelectorChain: SelectorChain?
  public weak var extendedDeclaration: Ruleset?
  
  public var specificity: Int {
    var specificity: Int = 0
    for selectorChain in selectorChains {
      specificity += selectorChain.specificity
    }
    return specificity
  }
  
  // TODO: Do we need this?
  // public weak var scope: ISSStyleSheetScope? // The scope used by the parent stylesheet...
  
  public var chainsDescription: String {
    return selectorChains.map { $0.description }.joined(separator: ", ")
  }
  
  public var propertiesDescription: String {
    return properties.map { $0.description }.joined(separator: " ")
  }
  
  public var description: String {
    return "\(chainsDescription) { \(propertiesDescription) }"
  }
  
  public var debugDescription: String {
    return "Ruleset[\(description)]"
  }
  
  convenience init(selectorChains: [SelectorChain], andProperties properties: [PropertyValue]) {
    self.init(selectorChains: selectorChains, andProperties: properties, extendedDeclarationSelectorChain: nil)
  }
  
  public init(selectorChains: [SelectorChain], andProperties properties: [PropertyValue], extendedDeclarationSelectorChain: SelectorChain?) {
    self.selectorChains = selectorChains
    self._properties = properties
    self.extendedDeclarationSelectorChain = extendedDeclarationSelectorChain
    var containsPseudoClassSelector = false
    for chain in selectorChains {
      if chain.hasPseudoClassSelector {
        containsPseudoClassSelector = true
        break
      }
    }
    self.containsPseudoClassSelector = containsPseudoClassSelector
  }
  
  public func matches(_ element: ElementStyle, context: StylingContext) -> Bool {
    return selectorChains.first { $0.matches(element, context: context) } != nil
  }
  
  public func ruleset(matching element: ElementStyle, context: StylingContext) -> Ruleset? {
//    var matchingChains: [SelectorChain]? = containsPseudoClassSelector ? [] : nil
    var matchingChains: [SelectorChain] = []
    for selectorChain in selectorChains {
      if selectorChain.matches(element, context: context) {
// TODO: This messes with specificity!
//        if !containsPseudoClassSelector {
//          return self // If this style sheet declarations block doesn't contain any pseudo classes - return the declarations object itself directly when first selector chain match is found (since no additional matching needs to be done)
//        }
        matchingChains.append(selectorChain)
      }
    }
//    if let matchingChains = matchingChains, matchingChains.count > 0 {
    if matchingChains.count > 0 {
      return Ruleset(selectorChains: matchingChains, andProperties: properties)
    } else {
      return nil
    }
  }
  
  public func contains(_ selectorChain: SelectorChain) -> Bool {
    return selectorChains.contains { $0 == selectorChain }
  }
}
