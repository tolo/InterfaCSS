//
//  AbstractViewTreeParser.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
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

  public enum LayoutAttribute: String, StringParsableEnum {
    public static var defaultEnumValue: LayoutAttribute {
      return .unknownAttribute
    }

    case unknownAttribute = "unknownAttribute"

    case useSafeAreaInsets = "useSafeAreaInsets"
    case useDefaultMargins = "useDefaultMargins"
    case layoutTitle = "layoutTitle"
    case title = "title"
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
      return (nil, parseError)
    }
    guard let layoutAttributes = layoutAttributes else {
      return (nil, AbstractViewTreeParserError.missingLayoutRootElement)
    }
    guard let rootViewTreeNode = rootViewTreeNode else {
      return (nil, AbstractViewTreeParserError.missingViewTreeRootNode)
    }

    var styleSheetContent: StyleSheetContent?
    if let styleNodeContent = styleNodeContent?.content, styleNodeContent.hasData() {
      styleSheetContent = styler.styleSheetManager.parseStyleSheetContent(styleNodeContent)
    }
    let layout = AbstractLayout(rootNode: rootViewTreeNode, title: layoutTitle, layoutStyle: styleSheetContent, layoutAttributes: layoutAttributes)
    return (layout, parseError)
  }
}

extension AbstractViewTreeParser: XMLParserDelegate {

  public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
    let node: Node
    
    if elementName ~= AbstractViewTreeParser.rootElementName {
      guard nodeStack.isEmpty else {
        parser.abortParsing()
        parseError = AbstractViewTreeParserError.invalidLayoutRootElementPosition
        return
      }
      
      layoutAttributes = LayoutAttributes()
      layoutTitle = nil
      for (key, value) in attributeDict {
        guard let attribute = LayoutAttribute.enumValue(from: key) else { continue }
        switch attribute {
        case .useSafeAreaInsets: layoutAttributes?.useSafeAreaInsets = (value as NSString).boolValue
        case .useDefaultMargins: layoutAttributes?.useDefaultMargins = (value as NSString).boolValue
        case .layoutTitle, .title: layoutTitle = value
        default: break
        }
      }
      node = .layoutNode(layoutAttributes: layoutAttributes!)
    }
    else if elementName ~= AbstractViewTreeParser.styleElementName {
      styleNodeContent = StyleNodeContent()
      node = .styleNode(styleNodeContent: styleNodeContent!)
    }
    else {
      // Attributes
      let attributes = ElementAttributes(forElementName: elementName, attributes: attributeDict, withStyler: styler)
      let elementType = UIElementType.typeFrom(elementName: elementName)

      let viewTreeNode = AbstractViewTreeNode(elementType: elementType, attributes: attributes)
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
