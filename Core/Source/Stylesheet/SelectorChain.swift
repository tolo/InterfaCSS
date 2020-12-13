//
//  SelectorChain.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

/**
 * SelectorCombinator
 */
public enum SelectorCombinator: String, CustomStringConvertible {
  case descendant
  case child
  case sibling
  case generalSibling
  
  public var description: String {
    switch self {
      case .descendant: return " "
      case .child: return " > "
      case .sibling: return " + "
      case .generalSibling: return " ~ "
    }
  }
}

/**
 * SelectorChainComponent
 */
public enum SelectorChainComponent: Hashable, CustomStringConvertible {
  case selector(Selector)
  case combinator(SelectorCombinator)
  
  public var description: String {
    switch self {
      case.selector(let selector): return selector.description
      case.combinator(let combinator): return combinator.description
    }
  }
  
  public var selector: Selector? {
    if case .selector(let selector) = self { return selector }
    return nil
  }
  
  public var combinator: SelectorCombinator? {
    if case .combinator(let combinator) = self { return combinator }
    return nil
  }
}

/**
 * SelectorChain
 */
public struct SelectorChain: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
  //typealias SelectorCombinatorPair = (selector: Selector, combinator: SelectorCombinator)
  private struct SelectorCombinatorPair: Hashable {
    let selector: Selector
    let combinator: SelectorCombinator
  }
  
  private var isNestedElementSelectorChain: Bool { return lastSelector.isNestedElementSelector }
  public var selectorComponents: [SelectorChainComponent] {
    var result = chainPairs.map { [SelectorChainComponent.selector($0.selector),
                                   SelectorChainComponent.combinator($0.combinator)] }.reduce([]) { $0 + $1 }
    result.append(.selector(lastSelector))
    return result
  }
  
  private let chainPairs: [SelectorCombinatorPair]
  private let lastSelector: Selector
  
  public let hasPseudoClassSelector: Bool
  
  public var specificity: Int {
    return selectorComponents.compactMap { $0.selector }.reduce(0) { (partialResult: Int, selector: Selector) -> Int in
      partialResult + selector.specificity
    }
  }
  
  public var description: String {
    return selectorComponents.compactMap { $0.description }.joined()
  }
  
  public var debugDescription: String {
    return "SelectorChain[\(description)]"
  }
  
  
  public init(selector: Selector) {
    self.chainPairs = []
    self.lastSelector = selector
    self.hasPseudoClassSelector = selector.hasPseudoClassSelector
  }
  
  public init?(components selectorComponents: [SelectorChainComponent]) {
    // Validate selector components
    if selectorComponents.count % 2 == 1, let lastSelector = selectorComponents.last?.selector { // Selector chain must always contain odd number of components
      var hasPseudoClassSelector = false
      var chainPairs: [SelectorCombinatorPair] = []
      for i in stride(from: 0, to: selectorComponents.count-1, by: 2) {
        guard let selector = selectorComponents[i].selector else { return nil }
        guard let combinator = selectorComponents[i+1].combinator else { return nil }
        hasPseudoClassSelector = hasPseudoClassSelector || selector.hasPseudoClassSelector
        chainPairs.append(SelectorCombinatorPair(selector: selector, combinator: combinator))
      }
      
      self.chainPairs = chainPairs
      self.lastSelector = lastSelector
      self.hasPseudoClassSelector = hasPseudoClassSelector || lastSelector.hasPseudoClassSelector
    } else {
      return nil
    }
  }
  
  func addingDescendantSelector(_ selector: Selector) -> SelectorChain {
    let newComponents = selectorComponents + [SelectorChainComponent.combinator(.descendant), SelectorChainComponent.selector(selector)]
    guard let chain = SelectorChain(components: newComponents) else { preconditionFailure("Invalid selector chain components") }
    return chain
  }
  
  func addingDescendantSelectorChain(_ selectorChain: SelectorChain) -> SelectorChain {
    let newComponents = selectorComponents + [SelectorChainComponent.combinator(.descendant)] + selectorChain.selectorComponents
    guard let chain = SelectorChain(components: newComponents) else { preconditionFailure("Invalid selector chain components") }
    return chain
  }
  
  public func matches(_ element: ElementStyle, context: StylingContext) -> Bool {
    guard lastSelector.matches(element, context: context) else { // Match last selector...
      return false
    }
    
    let isNestedElementSelectorChain = self.isNestedElementSelectorChain
    var nextElement: ElementStyle? = element
    for (i, element) in chainPairs.reversed().enumerated() {
      //let (selector, combinator) = element
      let (selector, combinator) = (element.selector, element.combinator)
      var nextParentElement: ElementStyle?
      if isNestedElementSelectorChain && i == (chainPairs.count-1) { // In case last selector is ISSNestedElementSelector, we need to use ownerElement instead of parentElement
        nextParentElement = nextElement?.ownerElementStyle
      } else {
        nextParentElement = nextElement?.parentElementStyle
      }
      nextElement = SelectorChain.matchElement(nextElement, parentElement: nextParentElement, selector: selector, combinator: combinator, context: context)
    }
    
    // If element at least matched last selector in chain, but didn't match it completely (due to pseudo class) - set a flag indicating that there are partial matches
    if nextElement == nil && hasPseudoClassSelector {
      context.containsPartiallyMatchedDeclarations = true
    }
    return nextElement != nil
  }
  
  // MARK: - Utility methods
  static func find(matchingDescendantSelectorParent parentDetails: ElementStyle?, for selector: Selector, context: StylingContext) -> ElementStyle? {
    guard let parentDetails = parentDetails else {
      return nil
    }
    
    if selector.matches(parentDetails, context: context) {
      return parentDetails
    } else {
      let grandParentDetails: ElementStyle? = parentDetails.parentElementStyle
      return self.find(matchingDescendantSelectorParent: grandParentDetails, for: selector, context: context)
    }
  }
  
  static func find(matchingChildSelectorParent parentDetails: ElementStyle?, for selector: Selector, context: StylingContext) -> ElementStyle? {
    if let parentDetails = parentDetails, selector.matches(parentDetails, context: context) {
      return parentDetails
    } else {
      return nil
    }
  }
  
  static func find(matchingAdjacentSiblingTo elementDetails: ElementStyle?, inParent parentDetails: ElementStyle?, for selector: Selector, context: StylingContext) -> ElementStyle? {
    guard let subviews = parentDetails?.view?.subviews, let view = elementDetails?.view,
      let index = subviews.firstIndex(of: view) else { return nil }
    
    let siblingDetails = subviews[index - 1].interfaCSS
    if (index - 1) >= 0, selector.matches(siblingDetails, context: context) {
      return siblingDetails
    }
    return nil
  }
  
  static func find(matchingGeneralSiblingTo elementDetails: ElementStyle?, inParent parentElement: ElementStyle?, for selector: Selector, context: StylingContext) -> ElementStyle? {
    for sibling in parentElement?.view?.subviews ?? [] {
      let siblingElement = sibling.interfaCSS
      if sibling != parentElement?.view, selector.matches(siblingElement, context: context) {
        return siblingElement
      }
    }
    return nil
  }
  
  static func matchElement(_ elementDetails: ElementStyle?, parentElement parentDetails: ElementStyle?, selector: Selector, combinator: SelectorCombinator, context: StylingContext) -> ElementStyle? {
    var nextElement: ElementStyle? = nil
    switch combinator {
      case .descendant:
        nextElement = find(matchingDescendantSelectorParent: parentDetails, for: selector, context: context)
      case .child:
        nextElement = find(matchingChildSelectorParent: parentDetails, for: selector, context: context)
      case .sibling:
        nextElement = find(matchingAdjacentSiblingTo: elementDetails, inParent: parentDetails, for: selector, context: context)
      case .generalSibling:
        nextElement = find(matchingGeneralSiblingTo: elementDetails, inParent: parentDetails, for: selector, context: context)
    }
    return nextElement
  }
}
