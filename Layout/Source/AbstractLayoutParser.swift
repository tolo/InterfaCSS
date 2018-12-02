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

public enum ButtonType: String, StringParsableEnum {
  public var description: String {
    return rawValue
  }
  
  case custom = "custom"
  case system = "system"
  
  public var uiButtonType: UIButton.ButtonType {
    switch self {
    case .custom: return .custom
    case .system: return .system
    }
  }
}

public enum UIElementType {
  // TODO: Expand this will more element types as needed
  case button(type: ButtonType)
  case collectionView(layoutClass: UICollectionViewLayout.Type)
  case other(elementClass: UIResponder.Type)

  public func createElement() -> UIResponder {
    switch self {
    case .button(let type): return UIButton(type: type.uiButtonType)
    case .collectionView(let layoutClass): return UICollectionView(frame: .zero, collectionViewLayout: layoutClass.init())
    case .other(let elementClass): return elementClass.init()
    }
  }
}

/**
 * AbstractViewTreeNode
 */
public final class AbstractViewTreeNode {
  public var elementType: UIElementType
  public var elementId: String?
  public var styleClasses: [String]?
  public var fileOwnerPropertyName: String?
  public var accessibilityIdentifier: String?
  public var inlineStyle: [ISSPropertyValue]?
  public var addToViewHierarchy: Bool
  
  public lazy var childNodes: [AbstractViewTreeNode] = []
  public var stringContent: String?
  public var rawAttributes: [String: String]
  

  public init(elementType: UIElementType, elementId: String? = nil, styleClasses: [String]? = nil, inlineStyle: [ISSPropertyValue]? = nil, addToViewHierarchy: Bool,
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


/**
 * AbstractViewTreeParser
 */
public final class AbstractViewTreeParser: NSObject {

  public static let rootElementName = "layout"
  public static let styleElementName = "style"

  public enum Attribute: String, StringParsableEnum {
    public var description: String {
      return rawValue
    }

    case useSafeAreaInsets = "useSafeAreaInsets"
    case useDefaultMargins = "useDefaultMargins"

    case id = "id"
    case styleClasses = "class"
    case style = "style"
    case property = "property"
    case addSubview = "addSubview"
    case implementationClass = "implementation"
    case collectionViewLayoutClass = "collectionViewLayout"
    case accessibilityIdentifier = "accessibilityIdentifier"
    
    case buttonType = "type"
    
    case unknownAttribute = "unknownAttribute"
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

  func viewClassFor(elementName: String) -> UIResponder.Type? {
    // Attempt to get UIKit class matching elementName
    let pm = styler.propertyManager
    var viewClass = pm.canonicalTypeClass(forType: elementName) as? UIResponder.Type
    if viewClass == nil {
      // Fallback - use element name as viewClass
      viewClass = ISSRuntimeIntrospectionUtils.class(withName: elementName) as? UIResponder.Type
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
      var viewClass: UIResponder.Type? = nil
      var addToViewHierarchy: Bool = true
      var buttonType: ButtonType = .custom
      var collectionViewLayoutClass: UICollectionViewLayout.Type = UICollectionViewFlowLayout.self

      var rawAttributes: [String: String] = [:]
      for (key, value) in attributeDict {
        let attribute = Attribute.enumValue(from: key)
        
        // "id" or "elementId":
        if attribute == .id {
          elementId = value
        }
        // "class":
        else if attribute == .styleClasses {
          styleClasses = value
        }
        // "style":
        else if attribute == .style {
          inlineStyle = value.split(separator: ";").compactMap {
            return styler.styleSheetManager.parsePropertyNameValuePair(String($0))
          }
        }
        // "property":
        else if attribute == .property {
          propertyName = value
        }
        // "implementation":
        else if attribute == .implementationClass {
          if let clazz = ISSRuntimeIntrospectionUtils.class(withName: value) as? UIResponder.Type {
            viewClass = clazz
          }
        }
        // "collectionViewLayout":
        else if attribute == .collectionViewLayoutClass {
          if let clazz = ISSRuntimeIntrospectionUtils.class(withName: value) as? UICollectionViewLayout.Type {
            collectionViewLayoutClass = clazz
          }
        }
        // "accessibilityIdentifier":
        else if attribute == .accessibilityIdentifier {
          accessibilityIdentifier = value
        }
        // "addSubview":
        else if attribute == .addSubview {
          addToViewHierarchy = (value as NSString).boolValue
        }
        // "type" (button type):
        else if attribute == .buttonType {
          buttonType = ButtonType.enumValue(from: value)
        }
       
        if attribute != .unknownAttribute {
          rawAttributes[attribute.rawValue] = value
        } else {
          rawAttributes[key] = value
        }
      }

      // Set viewClass if not specified by impl attribute
      viewClass = viewClass ?? viewClassFor(elementName: elementName)
      let elementType: UIElementType
      if viewClass == UIButton.self {
        elementType = .button(type: buttonType)
      } else if viewClass == UICollectionView.self {
        elementType = .collectionView(layoutClass: collectionViewLayoutClass )
      } else {
        elementType = .other(elementClass: viewClass ?? UIView.self) // If class not found - fall back to UIView
      }

      var styleClassArray: [String]?
      if let styleClasses = styleClasses {
        styleClassArray = styleClasses.iss_splitOnSpaceOrComma()
      }

      let viewTreeNode = AbstractViewTreeNode(elementType: elementType,
          elementId: elementId, styleClasses: styleClassArray, inlineStyle: inlineStyle, addToViewHierarchy: addToViewHierarchy,
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
