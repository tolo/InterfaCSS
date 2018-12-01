//
//  AbstractViewTreeParser.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit


public typealias AbstractLayoutCompletionHandler = (_ abstractLayout: AbstractLayout?, _ parseError: Error?) -> Void
public typealias AbstractViewTreeVisitor = (_ node: AbstractViewTreeNode, _ parentNode: AbstractViewTreeNode?, _ parentView: AnyObject?) -> AnyObject?


public enum AbstractViewTreeParserError: Error {
  case missingLayoutRootElement
  case invalidLayoutRootElementPosition
  case missingViewTreeRootNode
}

public struct AbstractLayout {
  public let rootNode: AbstractViewTreeNode
  public let layoutStyle: StyleSheetContent?
  public let layoutAttributes: LayoutAttributes
}

public class LayoutAttributes {
  public var useSafeAreaInsets: Bool = true
  public var useDefaultMargins: Bool = false
}

private class StyleNodeContent {
  var content: String = ""
}

//private enum UIElement { // TODO
//  case label
//  case button
//  case ...
//
//  func createElement() -> Any {
//    ...
//  }
//}

/**
 * AbstractViewTreeNode
 */
public final class AbstractViewTreeNode {
  public var viewClass: AnyClass
  public var elementId: String?
  public var styleClasses: [String]?
  public var fileOwnerPropertyName: String?
  public var accessibilityIdentifier: String?
  public var inlineStyle: [ISSPropertyValue]?
  public lazy var childNodes: [AbstractViewTreeNode] = []
  public var rawAttributes: [String: String]
  public var stringContent: String?

  public init(viewClass: AnyClass, elementId: String? = nil, styleClasses: [String]? = nil, inlineStyle: [ISSPropertyValue]? = nil, fileOwnerPropertyName: String? = nil, accessibilityIdentifier: String? = nil, rawAttributes: [String: String]) {
    self.viewClass = viewClass
    self.elementId = elementId
    self.styleClasses = styleClasses
    self.inlineStyle = inlineStyle
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


/**
 * AbstractViewTreeParser
 */
public final class AbstractViewTreeParser: NSObject {

  public static let rootElementName = "layout"
  public static let styleElementName = "style"

  enum Attribute: String, CustomStringConvertible, Equatable, Hashable {
    var description: String {
      return rawValue
    }

    case useSafeAreaInsets = "useSafeAreaInsets"
    case useDefaultMargins = "useDefaultMargins"

    case id = "id"
    case styleClasses = "class"
    case style = "style"
    case property = "property"
    case implementationClass = "implementation"
    case collectionViewLayoutClass = "collectionViewLayout"
    case accessibilityIdentifier = "accessibilityIdentifier"
  }

  private enum Node {
    case layoutNode(layoutAttributes: LayoutAttributes)
    case styleNode(styleNodeContent: StyleNodeContent)
    case viewNode(abstractViewTreeNode: AbstractViewTreeNode)
  }

  private let parser: XMLParser
  private (set) weak var fileOwner: AnyObject?

  public var parseError: Error?

  private var nodeStack: [Node] = []
  private var rootViewTreeNode: AbstractViewTreeNode?
  private var layoutAttributes: LayoutAttributes?
  private var styleNodeContent: StyleNodeContent?

  private (set) var styler: Styler


  public init(data: Data, fileOwner: AnyObject? = nil, styler: Styler) {
    parser = XMLParser(data: data)
    self.fileOwner = fileOwner
    self.styler = styler

    super.init()

    parser.delegate = self
  }

  public func parse(completion: AbstractLayoutCompletionHandler) {
    parser.parse()

    guard parseError == nil else {
      completion(nil, parseError)
      return
    }
    guard let layoutAttributes = layoutAttributes else {
      completion(nil, AbstractViewTreeParserError.missingLayoutRootElement)
      return
    }
    guard let rootViewTreeNode = rootViewTreeNode else {
      completion(nil, AbstractViewTreeParserError.missingViewTreeRootNode)
      return
    }

    var styleSheetContent: StyleSheetContent?
    if let styleNodeContent = styleNodeContent?.content {
      styleSheetContent = styler.styleSheetManager.parseStyleSheetData(styleNodeContent)
    }
    let layout = AbstractLayout(rootNode: rootViewTreeNode, layoutStyle: styleSheetContent, layoutAttributes: layoutAttributes)
    completion(layout, parseError)
  }

  func viewClassFor(elementName: String) -> AnyClass? {
    // Attempt to get UIKit class matching elementName
    let pm = styler.propertyManager
    var viewClass: AnyClass? = pm.canonicalTypeClass(forType: elementName)
    if viewClass == nil {
      // Fallback - use element name as viewClass
      viewClass = ISSRuntimeIntrospectionUtils.class(withName: elementName)
    }
    return viewClass
  }
}

extension AbstractViewTreeParser: XMLParserDelegate {

  public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {

    let node: Node
    
    if (elementName.iss_isEqualIgnoreCase(AbstractViewTreeParser.rootElementName)) {
      guard nodeStack.isEmpty else {
        parser.abortParsing()
        parseError = AbstractViewTreeParserError.invalidLayoutRootElementPosition
        return
      }
      
      layoutAttributes = LayoutAttributes()
      for (key, value) in attributeDict {
        if key.iss_isEqualIgnoreCase(Attribute.useSafeAreaInsets.rawValue) {
          layoutAttributes?.useSafeAreaInsets = (value as NSString).boolValue
        } else if key.iss_isEqualIgnoreCase(Attribute.useDefaultMargins.rawValue) {
          layoutAttributes?.useDefaultMargins = (value as NSString).boolValue
        }
      }
      node = .layoutNode(layoutAttributes: layoutAttributes!)
    }
    else if (elementName.iss_isEqualIgnoreCase(AbstractViewTreeParser.styleElementName)) {
      styleNodeContent = StyleNodeContent()
      node = .styleNode(styleNodeContent: styleNodeContent!)
    }
    else {
      // Attributes
      var elementId: String? = nil
      var styleClasses: String? = nil
      var propertyName: String? = nil
      var inlineStyle: [ISSPropertyValue]? = nil
      var accessibilityIdentifier: String? = nil
      var viewClass: AnyClass? = nil

      var rawAttributes: [String: String] = [:]
      for (key, value) in attributeDict {
        // "id" or "elementId":
        if key.iss_isEqualIgnoreCase(Attribute.id.rawValue) {
          elementId = value
          rawAttributes[Attribute.id.rawValue] = value
        }
        // "class":
        else if key.iss_isEqualIgnoreCase(Attribute.styleClasses.rawValue) {
          styleClasses = value
          rawAttributes[Attribute.styleClasses.rawValue] = styleClasses
        }
        // "style":
        else if key.iss_isEqualIgnoreCase(Attribute.style.rawValue) {
          inlineStyle = value.split(separator: ";").compactMap {
            return styler.styleSheetManager.parsePropertyNameValuePair(String($0))
          }
          rawAttributes[Attribute.style.rawValue] = value
        }
        // "property":
        else if key.iss_isEqualIgnoreCase(Attribute.property.rawValue) {
          propertyName = value
          rawAttributes[Attribute.property.rawValue] = value
        }
        // "impl" or "implementation":
        else if key.iss_isEqualIgnoreCase(Attribute.implementationClass.rawValue) || key.iss_isEqualIgnoreCase("impl") {
          viewClass = ISSRuntimeIntrospectionUtils.class(withName: value)
          rawAttributes[Attribute.implementationClass.rawValue] = value
        }
        // "impl" or "implementation":
        else if key.iss_isEqualIgnoreCase(Attribute.collectionViewLayoutClass.rawValue) {
          //collectionViewLayoutClass = ISSRuntimeIntrospectionUtils.class(withName: value)
          rawAttributes[Attribute.collectionViewLayoutClass.rawValue] = value
        }
        // "accessibilityIdentifier":
        else if key.iss_isEqualIgnoreCase(Attribute.accessibilityIdentifier.rawValue) {
          accessibilityIdentifier = value
          rawAttributes[Attribute.accessibilityIdentifier.rawValue] = value
        }
          // "accessibilityIdentifier":
        else if key.iss_isEqualIgnoreCase("style") {
          accessibilityIdentifier = value
          rawAttributes[Attribute.accessibilityIdentifier.rawValue] = value
        }
        else {
          rawAttributes[key] = value
        }
      }

      // Set viewClass if not specified by impl attribute
      viewClass = viewClass ?? viewClassFor(elementName: elementName)

      var styleClassArray: [String]?
      if let styleClasses = styleClasses {
        styleClassArray = styleClasses.iss_splitOnSpaceOrComma()
      }

      let viewTreeNode = AbstractViewTreeNode(viewClass: viewClass ?? UIView.self, // If class not found - fall back to UIView
          elementId: elementId, styleClasses: styleClassArray, inlineStyle: inlineStyle,
          fileOwnerPropertyName: propertyName, accessibilityIdentifier: accessibilityIdentifier, rawAttributes: rawAttributes)
      if let parentNode = nodeStack.last, case .viewNode(let parentViewNode) = parentNode {
        parentViewNode.addChild(node: viewTreeNode)
      } else if rootViewTreeNode == nil {
        rootViewTreeNode = viewTreeNode
      }
      node = .viewNode(abstractViewTreeNode: viewTreeNode)
    }
    
    nodeStack.append(node)
  }

  public func parser(_ parser: XMLParser, foundCharacters string: String) {
    guard string.iss_trim().count > 0 else {
      return
    }
    
    guard let currentNode = nodeStack.last else {
      return
    }

    if case .styleNode(let styleNodeContent) = currentNode {
      styleNodeContent.content += string
    }
    else if case .viewNode(let abstractViewTreeNode) = currentNode {
      abstractViewTreeNode.stringContent = (abstractViewTreeNode.stringContent ?? "") + string
    }
  }

  public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
      nodeStack.removeLast()
  }

  public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    self.parseError = parseError
  }
}
