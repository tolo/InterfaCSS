//
//  AbstractViewTreeParser.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit


public typealias AbstractLayoutCompletionHandler = (_ abstractLayout: AbstractLayout?, _ parseError: Error?) -> Void


public enum AbstractViewTreeParserError: Error {
  case missingLayoutRootElement
  case invalidLayoutRootElementPosition
  case missingViewTreeRootNode
}


public struct AbstractLayout {
  public let rootNode: AbstractViewTreeNode
  public let title: String?
  public let layoutStyle: StyleSheetContent?
  public let layoutAttributes: LayoutAttributes
}

public class LayoutAttributes {
  public var useSafeAreaInsets: Bool = true
  public var useDefaultMargins: Bool = false
}


/**
 * AbstractViewTreeParser
 */
public final class AbstractViewTreeParser: NSObject {

  public static let rootElementName = "layout"
  public static let styleElementName = "style"

  public enum Attribute: String, StringParsableEnum {
    public static var defaultEnumValue: Attribute {
      return .unknownAttribute
    }

    public var description: String {
      return rawValue
    }

    case unknownAttribute = "unknownAttribute"

    case useSafeAreaInsets = "useSafeAreaInsets"
    case useDefaultMargins = "useDefaultMargins"
    case layoutTitle = "layoutTitle"

    case id = "id"
    case styleClasses = "class"
    case style = "style"
    case property = "property"
    case addSubview = "addSubview"
    case implementationClass = "implementation"
    case collectionViewLayoutClass = "collectionViewLayout"
    case accessibilityIdentifier = "accessibilityIdentifier"
    
    case type = "type"
    case image = "image"
    case title = "title"
    case text = "text"
    
    case layout = "layout"
  }

  private class StyleNodeContent {
    var content: String = ""
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
  private var layoutTitle: String?
  private var styleNodeContent: StyleNodeContent?

  private (set) var styler: Styler


  public init(data: Data, styler: Styler) {
    parser = XMLParser(data: data)
    self.styler = styler

    super.init()

    parser.delegate = self
  }

  /**
   * Returns 'AbstractViewTreeParserError' or Error
   */
  public func parse() -> (abstractLayout: AbstractLayout?, parseError: Error?) {
    parser.parse()

    guard parseError == nil else {
//      completion(nil, parseError)
      return (nil, parseError)
    }
    guard let layoutAttributes = layoutAttributes else {
//      completion(nil, AbstractViewTreeParserError.missingLayoutRootElement)
      return (nil, AbstractViewTreeParserError.missingLayoutRootElement)
    }
    guard let rootViewTreeNode = rootViewTreeNode else {
//      completion(nil, AbstractViewTreeParserError.missingViewTreeRootNode)
      return (nil, AbstractViewTreeParserError.missingViewTreeRootNode)
    }

    var styleSheetContent: StyleSheetContent?
    if let styleNodeContent = styleNodeContent?.content, styleNodeContent.hasData() {
      styleSheetContent = styler.styleSheetManager.parseStyleSheetData(styleNodeContent)
    }
    let layout = AbstractLayout(rootNode: rootViewTreeNode, title: layoutTitle, layoutStyle: styleSheetContent, layoutAttributes: layoutAttributes)
//    completion(layout, parseError)
    return (layout, parseError)
  }
}

extension AbstractViewTreeParser: XMLParserDelegate {

  public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {

    let node: Node
    
    if (elementName ==⇧ (AbstractViewTreeParser.rootElementName)) {
      guard nodeStack.isEmpty else {
        parser.abortParsing()
        parseError = AbstractViewTreeParserError.invalidLayoutRootElementPosition
        return
      }
      
      layoutAttributes = LayoutAttributes()
      layoutTitle = nil
      for (key, value) in attributeDict {
        guard let attribute = Attribute.enumValue(from: key) else { continue }
        switch attribute {
        case .useSafeAreaInsets: layoutAttributes?.useSafeAreaInsets = (value as NSString).boolValue
        case .useDefaultMargins: layoutAttributes?.useDefaultMargins = (value as NSString).boolValue
        case .layoutTitle, .title: layoutTitle = value
        default: break
        }
      }
      node = .layoutNode(layoutAttributes: layoutAttributes!)
    }
    else if (elementName ==⇧ (AbstractViewTreeParser.styleElementName)) {
      styleNodeContent = StyleNodeContent()
      node = .styleNode(styleNodeContent: styleNodeContent!)
    }
    else {
      // Attributes
      var elementId: String? = nil
      var styleClasses: String? = nil
      var propertyName: String? = nil
      var inlineStyle: [PropertyValue]? = nil
      var accessibilityIdentifier: String? = nil
      var viewClass: UIResponder.Type? = nil
      var addToViewHierarchy: Bool = true
      var collectionViewLayoutClass: UICollectionViewLayout.Type = UICollectionViewFlowLayout.self
      var layoutFile: String? = nil
      var buttonType: UIElementType.ButtonType = .custom
      var image: UIImage? = nil
      var text: String? = nil

      var rawAttributes: [String: String] = [:]
      for (key, value) in attributeDict {
        let attribute = Attribute.enumValueWithDefault(from: key)

        switch attribute {
        case .id: elementId = value // "id" or "elementId":
        case .styleClasses: styleClasses = value // "class":
        case .style:
          if let style = styler.styleSheetManager.parsePropertyNameValuePairs(value) {
            inlineStyle = (inlineStyle ?? []) + style
          }
        case .property: propertyName = value
        case .implementationClass: // "implementation"
          if let clazz = RuntimeIntrospectionUtils.class(withName: value) as? UIResponder.Type {
            viewClass = clazz
          }
        case .collectionViewLayoutClass: // "collectionViewLayout"
          if let clazz = RuntimeIntrospectionUtils.class(withName: value) as? UICollectionViewLayout.Type {
            collectionViewLayoutClass = clazz
          }
        case .accessibilityIdentifier: accessibilityIdentifier = value
        case .addSubview: addToViewHierarchy = (value as NSString).boolValue
        case .layout: layoutFile = value
        case .type: buttonType = UIElementType.ButtonType.enumValueWithDefault(from: value) // "type" (button type):
        case .image: image = UIImage(named: value)
        case .text, .title: text = value
        default: break
        }

        if attribute != .unknownAttribute {
          rawAttributes[attribute.rawValue] = value
        } else {
          // Attempt to convert unrecognized attribute into inline style:
          if let style = styler.styleSheetManager.parsePropertyNameValuePair("\(key): \"\(value)\"") {
            inlineStyle = (inlineStyle ?? []) + [style]
          }
          rawAttributes[key] = value
        }
      }
      
      var parentViewNode: AbstractViewTreeNode?
      if let parentNode = nodeStack.last, case .viewNode(let node) = parentNode {
        parentViewNode = node
      }

      // Set viewClass if not specified by impl attribute
      viewClass = viewClass ?? viewClassFor(elementName: elementName)
      let elementType: UIElementType
      if elementName.isCaseInsensitiveEqualWithOptionalPrefix("button") {
        elementType = .button(type: buttonType, title: text)
      } else if elementName.isCaseInsensitiveEqualWithOptionalPrefix("label") {
        elementType = .label(text: text)
      } else if elementName.isCaseInsensitiveEqualWithOptionalPrefix("imageView") {
        elementType = .imageView(image: image)
      } else if elementName.isCaseInsensitiveEqualWithOptionalPrefix("textField") {
        elementType = .textField(text: text)
      } else if elementName.isCaseInsensitiveEqualWithOptionalPrefix("textView") {
        elementType = .textView(text: text)
      } else if viewClass is UICollectionView.Type {
        elementType = .collectionView(layoutClass: collectionViewLayoutClass )
      } else if (viewClass is UICollectionViewCell.Type || elementName.isCaseInsensitiveEqual("cell")),
        let parentType = parentViewNode?.elementType, case .collectionView = parentType {
        elementType = .collectionViewCell(cellLayoutFile: layoutFile, elementClass: viewClass as? LayoutCollectionViewCell.Type)
      } else if viewClass is UITableView.Type {
        elementType = .tableView
      } else if (viewClass is UITableViewCell.Type || elementName.isCaseInsensitiveEqual("cell")),
        let parentType = parentViewNode?.elementType, case .tableView = parentType {
        elementType = .tableViewCell(cellLayoutFile: layoutFile, elementClass: viewClass as? LayoutTableViewCell.Type)
      } else if let viewClass = viewClass as? UIViewController.Type {
        elementType = .viewController(layoutFile: layoutFile, elementClass: viewClass)
      } else {
        elementType = .other(elementClass: viewClass ?? UIView.self) // If class not found - fall back to UIView
      }

      var styleClassArray: [String]?
      if let styleClasses = styleClasses {
        styleClassArray = styleClasses.splitOnSpaceOrComma()
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
    guard string.trim().count > 0 else { return}
    guard let currentNode = nodeStack.last else { return }

    if case .styleNode(let styleNodeContent) = currentNode {
      styleNodeContent.content += string
    }
    else if case .viewNode(let abstractViewTreeNode) = currentNode {
      abstractViewTreeNode.stringContent = (abstractViewTreeNode.stringContent ?? "") + string
    }
  }

  public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    if case .viewNode(let abstractViewTreeNode)? = nodeStack.last, let stringContent = abstractViewTreeNode.stringContent {
      abstractViewTreeNode.stringContent = stringContent.trim()
    }
    nodeStack.removeLast()
  }

  public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
    self.parseError = parseError
  }
}

private extension AbstractViewTreeParser {
  private func viewClassFor(elementName: String) -> UIResponder.Type? {
    // Attempt to get UIKit class matching elementName
    let pm = styler.propertyManager
    var viewClass = pm.canonicalTypeClass(forType: elementName) as? UIResponder.Type
    if viewClass == nil {
      // Fallback - use element name as viewClass
      viewClass = RuntimeIntrospectionUtils.class(withName: elementName) as? UIResponder.Type
    }
    return viewClass
  }
}

private extension String {
  func isCaseInsensitiveEqualWithOptionalPrefix(_ otherString: String) -> Bool {
    return isCaseInsensitiveEqual(otherString, withOptionalPrefix: "UI")
  }
}
