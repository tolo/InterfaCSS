//
//  AbstractViewTreeNode.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit

public typealias AbstractViewTreeVisitor = (_ node: AbstractViewTreeNode, _ parentNode: AbstractViewTreeNode?, _ parentView: Any?) -> Any?
public typealias ViewTreeVisitor = (_ view: UIResponder, _ parentView: UIView?) -> UIResponder?

/**
 * AbstractViewTreeNode
 */
public final class AbstractViewTreeNode {
  public let elementType: UIElementType
  public let attributes: ElementAttributes
  
  public var elementId: String? { attributes.elementId }
  public var styleClasses: [String]? { attributes.styleClasses }
  public var fileOwnerPropertyName: String? { attributes.propertyName }
  public var accessibilityIdentifier: String? { attributes.accessibilityIdentifier }
  public var inlineStyle: [PropertyValue]? { attributes.inlineStyle }
  public var addToViewHierarchy: Bool { attributes.addToViewHierarchy }
  public var rawAttributes: [String: String] { attributes.rawAttributes }

  public lazy var childNodes: [AbstractViewTreeNode] = []
  public var stringContent: String?
  
  public init(elementType: UIElementType, attributes: ElementAttributes) {
    self.elementType = elementType
    self.attributes = attributes
  }

  func addChild(node: AbstractViewTreeNode) {
    childNodes.append(node)
  }

  public func visitAbstractViewTree(visitor: AbstractViewTreeVisitor) -> Any? {
    return visitAbstractViewTree(parentNode: nil, parentView: nil, visitor: visitor)
  }

  @discardableResult private func visitAbstractViewTree(parentNode: AbstractViewTreeNode?, parentView: Any?, visitor: AbstractViewTreeVisitor) -> Any? {
    let view = visitor(self, parentNode, parentView)
    childNodes.forEach {
      $0.visitAbstractViewTree(parentNode: self, parentView: view, visitor: visitor)
    }
    return view
  }
  
  public func visitViewTree(with viewBuilder: ViewBuilder, fileOwner: AnyObject? = nil, visitor: ViewTreeVisitor) -> UIView? {
    return visitAbstractViewTree() { (node, parentNode, parentView) in
      guard let viewObject = createElement(viewBuilder: viewBuilder) else {
        return nil
      }
      guard let parentView = parentView as? UIView else {
        return viewObject
      }
      return visitor(viewObject, parentView)
    } as? UIView
  }
  
  public func createElement(viewBuilder: ViewBuilder, parentView: AnyObject? = nil, fileOwner: AnyObject? = nil) -> UIResponder? {
    return elementType.createElement(forNode: self, parentView: parentView, viewBuilder: viewBuilder, fileOwner: fileOwner)
  }
  
  func nodeViewClass(withStyler styler: Styler) -> UIResponder.Type {
    if let implementationClass = attributes.implementationClass {
      return implementationClass
    }
    
    // Attempt to get UIKit class matching elementName
    let pm = styler.propertyManager
    var viewClass = pm.canonicalTypeClass(forType: attributes.elementName) as? UIResponder.Type
    if viewClass == nil {
      // Fallback - use element name as viewClass
      viewClass = RuntimeIntrospectionUtils.class(withName: attributes.elementName) as? UIResponder.Type
    }
    return viewClass ?? UIView.self
  }
}
