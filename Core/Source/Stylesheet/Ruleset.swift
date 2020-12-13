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
      var props = extendedDeclaration._properties
      props.addAndReplace(_properties)
      return props
    }
    return _properties
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
  
  public init(selectorChains: [SelectorChain], andProperties properties: [PropertyValue], extendedDeclarationSelectorChain: SelectorChain?, extendedDeclaration: Ruleset? = nil) {
    self.selectorChains = selectorChains
    self._properties = properties
    self.extendedDeclarationSelectorChain = extendedDeclarationSelectorChain
    self.extendedDeclaration = extendedDeclaration
    var containsPseudoClassSelector = false
    for chain in selectorChains {
      if chain.hasPseudoClassSelector {
        containsPseudoClassSelector = true
        break
      }
    }
    self.containsPseudoClassSelector = containsPseudoClassSelector
  }
  
  public func copyWith(selectorChains: [SelectorChain]) -> Ruleset {
    Ruleset(selectorChains: selectorChains, andProperties: properties, extendedDeclarationSelectorChain: extendedDeclarationSelectorChain, extendedDeclaration: extendedDeclaration)
  }
  
  public func matches(_ element: ElementStyle, context: StylingContext) -> Bool {
    return selectorChains.first { $0.matches(element, context: context) } != nil
  }
  
  public func ruleset(matching element: ElementStyle, context: StylingContext) -> Ruleset? {
    var matchingChains: [SelectorChain] = []
    for selectorChain in selectorChains {
      if selectorChain.matches(element, context: context) {
        matchingChains.append(selectorChain)
      }
    }
    if matchingChains.count > 0 {
      return copyWith(selectorChains: matchingChains)
    } else {
      return nil
    }
  }
  
  public func contains(_ selectorChain: SelectorChain) -> Bool {
    return selectorChains.contains { $0 == selectorChain }
  }
}
