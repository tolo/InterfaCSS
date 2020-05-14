//
//  AbstractViewTreeNode.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit

public typealias AbstractViewTreeVisitor = (_ node: AbstractViewTreeNode, _ parentNode: AbstractViewTreeNode?, _ parentView: AnyObject?) -> AnyObject?

/**
 * AbstractViewTreeNode
 */
public final class AbstractViewTreeNode {
  public var elementType: UIElementType
  public var elementId: String?
  public var styleClasses: [String]?
  public var fileOwnerPropertyName: String?
  public var accessibilityIdentifier: String?
  public var inlineStyle: [PropertyValue]?
  public var addToViewHierarchy: Bool

  public lazy var childNodes: [AbstractViewTreeNode] = []
  public var stringContent: String?
  public var rawAttributes: [String: String]


  public init(elementType: UIElementType, elementId: String? = nil, styleClasses: [String]? = nil, inlineStyle: [PropertyValue]? = nil, addToViewHierarchy: Bool,
              fileOwnerPropertyName: String? = nil, accessibilityIdentifier: String? = nil, rawAttributes: [String: String]) {
    self.elementType = elementType
    self.elementId = elementId
    self.styleClasses = styleClasses
    self.inlineStyle = inlineStyle
    self.addToViewHierarchy = addToViewHierarchy
    self.fileOwnerPropertyName = fileOwnerPropertyName
    self.accessibilityIdentifier = accessibilityIdentifier ?? elementId
    self.rawAttributes = rawAttributes
  }

  func addChild(node: AbstractViewTreeNode) {
    childNodes.append(node)
  }

  public func visitAbstractViewTree(visitor: AbstractViewTreeVisitor) -> AnyObject? {
    return visitAbstractViewTree(parentNode: nil, parentView: nil, visitor: visitor)
  }

  @discardableResult private func visitAbstractViewTree(parentNode: AbstractViewTreeNode?, parentView: AnyObject?, visitor: AbstractViewTreeVisitor) -> AnyObject? {
    let view = visitor(self, parentNode, parentView)
    childNodes.forEach {
      $0.visitAbstractViewTree(parentNode: self, parentView: view, visitor: visitor)
    }
    return view
  }
}
