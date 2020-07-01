//
//  StyleSheetParser+Support.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation
import Parsicle

func createPseudoClass(_ parts: [Any], styleSheetManager: StyleSheetManager?) -> PseudoClass? {
  let pseudoClassType = parts.first as? String ?? ""
  let params = parts.last
  return styleSheetManager?.pseudoClassFactory.createPseudoClass(ofType: pseudoClassType, parameters: params)
  
}

func createSelector(_ type: Any?, elementId: Any?, classNames: Any?, pseudoClasses: Any?, styleSheetManager: StyleSheetManager?) -> Selector? {
  return styleSheetManager?.createSelector(withType: type as? String, elementId: elementId as? String,
                                           styleClasses: classNames as? [String], pseudoClasses: pseudoClasses as? [PseudoClass])
}

/**
 * Internal placeholder class to reference a ruleset declaration that is to be extended.
 */
class RulesetExtension {
  var extendedSelectorChain: SelectorChain
  init(_ extendedSelectorChain: SelectorChain) {
    self.extendedSelectorChain = extendedSelectorChain
  }
}

enum CSSContent {
  case comment(String)
  case variable
  case ruleset(ParsedRuleset)
  case unrecognizedContent(String)
}

typealias TransformedPropertyPair = (propertyName: String, prefix: String?, value: PropertyValue.Value, rawParameters: [String]?)

enum ParsedRulesetContent {
  case comment(String)
  case propertyDeclaration(PropertyValue)
  //  case prefixedProperty(TransformedPropertyPair)
  case nestedRuleset(ParsedRuleset)
  case extendedDeclaration(RulesetExtension)
  case unsupportedNestedRuleset(String)
  case unrecognizedContent(String)
  
  var property: PropertyValue? {
    if case .propertyDeclaration(let p) = self {
      return p
    }
    return nil
  }
}

enum ParsedSelectorChain {
  case selectorChain(chain: SelectorChain)
  case badData(badData: String)
  
  var selectorChain: SelectorChain? {
    switch self {
      case .selectorChain(let chain): return chain
      default: return nil
    }
  }
}

class ParsedRuleset: CustomStringConvertible { // TODO: Equatable?
  let parsedChains: [ParsedSelectorChain]
  var parsedProperties: [ParsedRulesetContent] = []
  
  lazy var ruleset: Ruleset = {
    let chains = parsedChains.compactMap{ $0.selectorChain }
    let properties = parsedProperties.compactMap{ $0.property }
    return Ruleset(selectorChains: chains, andProperties: properties)
  }()
  var chains: [SelectorChain] { return ruleset.selectorChains }
  var properties: [PropertyValue] { return ruleset.properties }
  
  init(withSelectorChains parsedChains: [ParsedSelectorChain], parsedProperties: [ParsedRulesetContent] = []) {
    self.parsedChains = parsedChains
    self.parsedProperties = parsedProperties
  }
  
  var chainsDescription: String {
    return ruleset.chainsDescription
  }
  
  var propertiesDescription: String {
    return ruleset.propertiesDescription
  }
  
  var description: String {
    return ruleset.description
  }
  
  var firstSelector: Selector? {
    return parsedChains.first?.selectorChain?.selectorComponents.first?.selector
  }
}

/**
 * Internal parsing context object.
 */
class StyleSheetParsingContext: NSObject {
  var variables: [String : String] = [:]
}
