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
  public let title: String?
  public let layoutStyle: StyleSheetContent?
  public let layoutAttributes: LayoutAttributes
}

public class LayoutAttributes {
  public var useSafeAreaInsets: Bool = true
  public var useDefaultMargins: Bool = false
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
  case tableView
  case tableViewCell(cellLayoutFile: String?, elementClass: LayoutTableViewCell.Type?)
  case viewController(layoutFile: String?, elementClass: UIViewController.Type)
  case other(elementClass: UIResponder.Type)

  public func createElement(forNode node: AbstractViewTreeNode, parentView: AnyObject?, viewBuilder: ViewBuilder, fileOwner: AnyObject?) -> UIResponder? {
    switch self {
    case .button(let type):
      return UIButton(type: type.uiButtonType)
    case .collectionView(let layoutClass):
      return createCollectionView(layoutClass: layoutClass, fileOwner: fileOwner)
    case .tableView:
      return createTableView(fileOwner: fileOwner)
    case .tableViewCell(let cellLayoutFile, let elementClass):
      registerTableViewCellClass(forNode: node, parentView: parentView, viewBuilder: viewBuilder, cellLayoutFile: cellLayoutFile, elementClass: elementClass)
      return nil
    case .viewController(let layoutFile, let elementClass):
      return createViewController(viewBuilder: viewBuilder, fileOwner: fileOwner, layoutFile: layoutFile, elementClass: elementClass)
    case .other(let elementClass):
      return elementClass.init()
    }
  }

  private func createCollectionView(layoutClass: UICollectionViewLayout.Type, fileOwner: AnyObject?) -> UICollectionView {
    let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layoutClass.init())
    if let dataSource = fileOwner as? UICollectionViewDataSource {
      collectionView.dataSource = dataSource
    }
    if let delegate = fileOwner as? UICollectionViewDelegate {
      collectionView.delegate = delegate
    }
    return collectionView
  }

  private func createTableView(fileOwner: AnyObject?) -> UITableView {
    let tableView = LayoutTableView(frame: .zero)
    if let dataSource = fileOwner as? UITableViewDataSource {
      tableView.dataSource = dataSource
    }
    if let delegate = fileOwner as? UITableViewDelegate {
      tableView.delegate = delegate
    }
    
    return tableView
  }
  
  private func registerTableViewCellClass(forNode node: AbstractViewTreeNode, parentView: AnyObject?, viewBuilder: ViewBuilder, cellLayoutFile: String?, elementClass: LayoutTableViewCell.Type?) {
    if let cellId = node.elementId, let cellLayoutFile = cellLayoutFile, let tableView = parentView as? LayoutTableView {
      if let elementClass = elementClass {
        tableView.registerCellLayout(cellIdentifier: cellId, cellClass: elementClass, layoutFile: cellLayoutFile, parentViewBuilder: viewBuilder)
      } else {
        tableView.registerCellLayout(cellIdentifier: cellId, layoutFile: cellLayoutFile, parentViewBuilder: viewBuilder)
      }
    }
  }

  private func createViewController(viewBuilder: ViewBuilder, fileOwner: AnyObject?, layoutFile: String?, elementClass: UIViewController.Type) -> UIViewController? {
    if fileOwner is UIViewController {
      if let layoutFile = layoutFile, let elementClass = elementClass as? LayoutViewController.Type {
        let parentUrl = viewBuilder.layoutFileURL
        let url = URL(fileURLWithPath: layoutFile, relativeTo: parentUrl)
        return elementClass.init(layoutFileURL: url, refreshable: viewBuilder.refreshable, styler: viewBuilder.styler)
      } else {
        return elementClass.init()
      }
    } else {
      viewBuilder.logger.logWarning(message: "Cannot create child view controller - fileOwner must be a UIViewController!")
      return nil
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
    case layoutTitle = "title"

    case id = "id"
    case styleClasses = "class"
    case style = "style"
    case property = "property"
    case addSubview = "addSubview"
    case implementationClass = "implementation"
    case collectionViewLayoutClass = "collectionViewLayout"
    case accessibilityIdentifier = "accessibilityIdentifier"
    
    case type = "type"
    
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
    let layout = AbstractLayout(rootNode: rootViewTreeNode, title: layoutTitle, layoutStyle: styleSheetContent, layoutAttributes: layoutAttributes)
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
      layoutTitle = nil
      for (key, value) in attributeDict {
        guard let attribute = Attribute.enumValue(from: key) else { continue }
        switch attribute {
        case .useSafeAreaInsets: layoutAttributes?.useSafeAreaInsets = (value as NSString).boolValue
        case .useDefaultMargins: layoutAttributes?.useSafeAreaInsets = (value as NSString).boolValue
        case .layoutTitle: layoutTitle = value
        default: break
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
      var inlineStyle: [PropertyValue]? = nil
      var accessibilityIdentifier: String? = nil
      var viewClass: UIResponder.Type? = nil
      var addToViewHierarchy: Bool = true
      var collectionViewLayoutClass: UICollectionViewLayout.Type = UICollectionViewFlowLayout.self
      var layoutFile: String? = nil
      var buttonType: ButtonType = .custom

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
          if let clazz = ISSRuntimeIntrospectionUtils.class(withName: value) as? UIResponder.Type {
            viewClass = clazz
          }
        case .collectionViewLayoutClass: // "collectionViewLayout"
          if let clazz = ISSRuntimeIntrospectionUtils.class(withName: value) as? UICollectionViewLayout.Type {
            collectionViewLayoutClass = clazz
          }
        case .accessibilityIdentifier: accessibilityIdentifier = value
        case .addSubview: addToViewHierarchy = (value as NSString).boolValue
        case .layout: layoutFile = value
        case .type: buttonType = ButtonType.enumValueWithDefault(from: value) // "type" (button type):
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
      if elementName.caseInsensitiveCompare("button") == .orderedSame {
        elementType = .button(type: buttonType)
      } else if viewClass is UICollectionView.Type {
        elementType = .collectionView(layoutClass: collectionViewLayoutClass )
      } else if viewClass is UITableView.Type {
        elementType = .tableView
      } else if (viewClass is UITableViewCell.Type || elementName.caseInsensitiveCompare("cell") == .orderedSame),
        let parentType = parentViewNode?.elementType, case .tableView = parentType {
        elementType = .tableViewCell(cellLayoutFile: layoutFile, elementClass: viewClass as? LayoutTableViewCell.Type)
      } else if let viewClass = viewClass as? UIViewController.Type {
        elementType = .viewController(layoutFile: layoutFile, elementClass: viewClass)
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
