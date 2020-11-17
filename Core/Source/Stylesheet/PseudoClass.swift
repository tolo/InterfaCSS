//
//  PseudoClass
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//


import Foundation
import UIKit


public typealias StructuralPseudoClassMatcher = (_ a: Int, _ b: Int, _ element: ElementStyle, _ context: StylingContext) -> Bool
public typealias SingleParameterPseudoClassMatcher = (_ parameter: String, _ element: ElementStyle, _ context: StylingContext) -> Bool
public typealias NotPseudoClassMatcher = (_ parameter: [SelectorChain], _ element: ElementStyle, _ context: StylingContext) -> Bool
public typealias SimplePseudoClassMatcher = (_ element: ElementStyle, _ context: StylingContext) -> Bool


public enum PseudoClassBuilder {
  case structural(matcher: StructuralPseudoClassMatcher)
  case singleParameter(matcher: SingleParameterPseudoClassMatcher)
  case not
  case simple(matcher: SimplePseudoClassMatcher)
  
  public func pseudoClass(withType type: String, parameters: Any?) -> PseudoClass? {
    switch self {
      case .structural(let matcher):
        guard let values: (a: Int, b: Int) = (parameters as? (Int, Int)) else { return nil }
        return .structural(type: type, a: values.a, b: values.b, matcher: matcher)
      case .singleParameter(let matcher):
        guard let parameter = parameters as? String else { return nil }
        return .singleParameter(type: type, parameter: parameter, matcher: matcher)
      case .not:
        guard let selectorChains = parameters as? [SelectorChain] else { return nil }
        return .not(parameter: selectorChains)
      case .simple(let matcher):
        return .simple(type: type, matcher: matcher)
    }
  }
}


/**
 * See http://www.w3.org/TR/selectors/#structural-pseudos for a description of the a & p parameters.
 */
public enum PseudoClass: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
  case structural(type: String, a: Int, b: Int, matcher: StructuralPseudoClassMatcher)
  case singleParameter(type: String, parameter: String, matcher: SingleParameterPseudoClassMatcher)
  case not(parameter: [SelectorChain])
  case simple(type: String, matcher: SimplePseudoClassMatcher)
  
  public var specificity: Int {
    switch self {
      case .not(let chains):
        return chains.reduce(0) { (currentValue, chain) in
          currentValue + chain.specificity
        }
      default:
        return 10
    }
  }
  
  public var description: String {
    switch self {
      case .structural(let type, let a, let b, _):
        let bSign = b < 0 ? "" : "+"
        return "\(type)(\(a)n\(bSign)\(b))"
      case .singleParameter(let type, let parameter, _): return "\(type)(\(parameter))"
      case .not(let parameter): return "not(\(parameter.description))"
      case .simple(let type, _): return type
    }
  }
  
  public var debugDescription: String {
    return "PseudoClass(\(description))"
  }
  
  public func matches(_ element: ElementStyle, context: StylingContext) -> Bool {
    switch self {
      case .structural(_, let a, let b, let matcher):
        return matcher(a, b, element, context)
      case .singleParameter(_, let parameter, let matcher):
        return matcher(parameter, element, context)
      case .not(let selectorChains):
        // Return true if element doesn't match any of the selector chains specified as parameter of the "not" pseudo class
        return selectorChains.first { $0.matches(element, context: context) } == nil
      case .simple(_, let matcher):
        return matcher(element, context)
    }
  }
  
  public static func == (lhs: PseudoClass, rhs: PseudoClass) -> Bool {
    return lhs.description == rhs.description
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(description)
  }
}
