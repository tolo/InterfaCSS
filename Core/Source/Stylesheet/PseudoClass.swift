//
//  PseudoClass
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//


import Foundation
import UIKit

// TODO: "Block" -> "Function"
public typealias StructuralPseudoClassMatcherBlock = (_ a: Int, _ b: Int, _ element: ElementStyle, _ context: StylingContext) -> Bool
public typealias SingleParameterPseudoClassMatcherBlock = (_ parameter: String, _ element: ElementStyle, _ context: StylingContext) -> Bool
public typealias SimplePseudoClassMatcherBlock = (_ element: ElementStyle, _ context: StylingContext) -> Bool

public enum PseudoClassMatcherBuilder {
  case structural(matcher: StructuralPseudoClassMatcherBlock)
  case singleParameter(matcher: SingleParameterPseudoClassMatcherBlock)
  case simple(matcher: SimplePseudoClassMatcherBlock)
  
  public func matcher(withParameters parameters: Any?) -> PseudoClassMatcher? {
    switch self {
      case .structural(let matcher):
        guard let values: (a: Int, b: Int) = (parameters as? (Int, Int)) else { return nil }
        return .structural(a: values.a, b: values.b, matcher: matcher)
      case .singleParameter(let matcher):
        guard let parameter = parameters as? String else { return nil }
        return .singleParameter(parameter: parameter, matcher: matcher)
      case .simple(let matcher):
        return .simple(matcher: matcher)
    }
  }
}

public enum PseudoClassMatcher {
  case structural(a: Int, b: Int, matcher: StructuralPseudoClassMatcherBlock)
  case singleParameter(parameter: String, matcher: SingleParameterPseudoClassMatcherBlock)
  case simple(matcher: SimplePseudoClassMatcherBlock)
  
  public func matches(_ element: ElementStyle, context: StylingContext) -> Bool {
    switch self {
      case .structural(let a, let b, let matcher):
        return matcher(a, b, element, context)
      case .singleParameter(let parameter, let matcher):
        return matcher(parameter, element, context)
      case .simple(let matcher):
        return matcher(element, context)
    }
  }
}

/**
 * See http://www.w3.org/TR/selectors/#structural-pseudos for a description of the a & p parameters.
 */
public struct PseudoClass: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
  public let type: String
  public let matcher: PseudoClassMatcher
  
  public var description: String {
    switch matcher {
      case .structural(let a, let b, _):
        let bSign = b < 0 ? "" : "+"
        return "\(type)(\(a)n\(bSign)\(b))"
      case .singleParameter(let parameter, _): return "\(type)(\(parameter))"
      case .simple: return type
    }
  }
  
  public var debugDescription: String {
    return "PseudoClass(\(description))"
  }
  
  public func matches(_ element: ElementStyle, context: StylingContext) -> Bool {
    return matcher.matches(element, context: context)
  }
  
  public static func == (lhs: PseudoClass, rhs: PseudoClass) -> Bool {
    return lhs.description == rhs.description
  }
  public func hash(into hasher: inout Hasher) {
    hasher.combine(description)
  }
}
