//
//  Selector.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

public struct SelectorType: Hashable {
  public let typeName: String
  public let type: AnyClass
  
  public static func == (lhs: SelectorType, rhs: SelectorType) -> Bool {
    return lhs.typeName == rhs.typeName
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(typeName)
  }
}

public enum Selector: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
  case selector(type: SelectorType?, elementId: String?, styleClasses: [String]?, pseudoClasses: [PseudoClass]?)
  case wildcardType(elementId: String?, styleClasses: [String]?, pseudoClasses: [PseudoClass]?)
  case nestedElement(nestedElementKeyPath: String)
  
  public var specificity: Int {
    switch self {
      case .selector(let type, let elementId, let styleClasses, let pseudoClasses):
        return specificity(type: type, isWildcardType: false, elementId: elementId, styleClasses: styleClasses, pseudoClasses: pseudoClasses)
      case .wildcardType(let elementId, let styleClasses, let pseudoClasses):
        return specificity(type: nil, isWildcardType: true, elementId: elementId, styleClasses: styleClasses, pseudoClasses: pseudoClasses)
      case .nestedElement(_):
        return 100
    }
  }
  
  private func specificity(type: SelectorType?, isWildcardType: Bool, elementId: String?, styleClasses: [String]?, pseudoClasses: [PseudoClass]?) -> Int {
    var specificity: Int = elementId != nil ? 100 : 0
    specificity += 10 * (styleClasses ?? []).count
    specificity += 10 * (pseudoClasses ?? []).count
    specificity += type != nil ? 1 : 0
    return specificity
  }
  
  public var description: String {
    switch self {
      case .selector(let type, let elementId, let styleClasses, let pseudoClasses):
        return description(type: type, isWildcardType: false, elementId: elementId, styleClasses: styleClasses, pseudoClasses: pseudoClasses)
      case .wildcardType(let elementId, let styleClasses, let pseudoClasses):
        return description(type: nil, isWildcardType: true, elementId: elementId, styleClasses: styleClasses, pseudoClasses: pseudoClasses)
      case .nestedElement(let nestedElementKeyPath):
        return "$\(nestedElementKeyPath)"
    }
  }
  
  private func description(type: SelectorType?, isWildcardType: Bool, elementId: String?, styleClasses: [String]?, pseudoClasses: [PseudoClass]?) -> String {
    var typeString = ""
    if let type = type {
      typeString = type.typeName
    } else if isWildcardType {
      typeString = "*"
    }
    
    var idString = ""
    if let elementId = elementId {
      idString = "#\(elementId)"
    }
    
    let classString = (styleClasses ?? []).map({ ".\($0)" }).joined(separator: "")
    let pseudoClassString = (pseudoClasses ?? []).map({ ":\($0)" }).joined(separator: "")
    
    return "\(typeString)\(idString)\(classString)\(pseudoClassString)"
  }
  
  public var debugDescription: String {
    return "Selector[\(description)]"
  }
  
  public func matches(_ element: ElementStyle, context: StylingContext) -> Bool {
    switch self {
      case .selector(let type, let elementId, let styleClasses, let pseudoClasses):
        return matchesSelector(element, context: context, type: type, isWildcardType: false, elementId: elementId, styleClasses: styleClasses, pseudoClasses: pseudoClasses)
      case .wildcardType(let elementId, let styleClasses, let pseudoClasses):
        return matchesSelector(element, context: context, type: nil, isWildcardType: true, elementId: elementId, styleClasses: styleClasses, pseudoClasses: pseudoClasses)
      case .nestedElement(let nestedElementKeyPath):
        return matchesNestedElementSelector(element, context: context, nestedElementKeyPath: nestedElementKeyPath)
    }
  }
  
  private func matchesSelector(_ element: ElementStyle, context: StylingContext, type: SelectorType?, isWildcardType: Bool, elementId: String?, styleClasses: [String]?, pseudoClasses: [PseudoClass]?) -> Bool {
    // TYPE
    if !isWildcardType, let type = type?.type {
      if element.canonicalType == nil {
        element.reset(with: context.styler) // Make sure canonicalType is initialized
      }
      guard element.canonicalType == type else { return false }
    }
    
    // ELEMENT ID
    if let elementId = elementId {
      guard elementId ~= (element.elementId ?? "") else { return false }
    }
    
    // STYLE CLASSES
    if let styleClasses = styleClasses {
      let elementStyleClasses = element.styleClasses ?? []
      guard elementStyleClasses.isSuperset(of: styleClasses) else { return false }
    }
    
    // PSEUDO CLASSES
    if !context.ignorePseudoClasses, let pseudoClasses = pseudoClasses {
      let firstNotMatch = pseudoClasses.first { !$0.matches(element, context: context) }
      guard firstNotMatch == nil else { return false }
    }
    
    return true
  }
  
  private func matchesNestedElementSelector(_ element: ElementStyle, context: StylingContext, nestedElementKeyPath: String) -> Bool {
    guard let ownerElement = element.ownerElementStyle,
      let ownerUIElement = ownerElement.uiElement else { return false }
        
    // TODO: This assumes doesPropertyExist (ISSRuntimeIntrospectionUtils.validKeyPath) executes fast - may need to optimize that method...
    return PropertyManager.doesPropertyExist(nestedElementKeyPath, in: ownerUIElement)
  }
  
  public var isNestedElementSelector: Bool {
    switch self {
      case .nestedElement(_): return true
      default: return false
    }
  }
  
  public var hasPseudoClassSelector: Bool {
    var pseudoClasses: [PseudoClass]?
    switch self {
      case .selector(_, _, _, let p),
           .wildcardType(_, _, let p): pseudoClasses = p
      default: break
    }
    return (pseudoClasses ?? []).count > 0
  }
}
