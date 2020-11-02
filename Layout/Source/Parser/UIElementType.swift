//
//  UIElementType.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit

public enum UIElementType: String, StringParsableEnum {
  
  public static var defaultEnumValue: UIElementType { .view }
  
  public enum ButtonType: String, StringParsableEnum {
    case custom
    case system
    
    public var uiButtonType: UIButton.ButtonType {
      switch self {
      case .custom: return .custom
      case .system: return .system
      }
    }
  }
  
  case view
  case button
  case text /// i.e. label
  case image
  case textInput
  case textArea
  case scrollView
  
  case collectionView
  case collectionViewCell // TODO: Remove?
  case tableView // TODO: Remove?
  case tableViewCell // TODO: Remove?
  case viewController // TODO: Rename? "Widget" instead?
  
  // TODO: ActivityIndicator
  // TODO: Picker
  // TODO: Switch
  // TODO: ScrollView
  // TODO: "Slot"?
  
  // TODO: Gesture recognizers
  
  static func typeFrom(elementName _elementName: String) -> UIElementType {
    var elementName = _elementName.lowercased()
    elementName = elementName.hasPrefix("ui") ? String(elementName.substring(from: 2)) : elementName
    if let value = enumValue(from: elementName) {
      return value
    } else { // Handle aliases
      switch elementName {
        case "label": return .text
        case "imageview": return .image
        case "textfield": return .textInput
        case "textview": return .textArea
        
        default: return .view
      }
    }
  }
  
  public func createElement(forNode node: AbstractViewTreeNode, parentView: AnyObject?, viewBuilder: ViewBuilder, fileOwner: AnyObject?) -> UIResponder? {
    let bodyContent = (node.stringContent?.hasData() ?? false) ? node.stringContent : nil
    
    guard let element = elementTypeToElement(forNode: node, bodyContent: bodyContent, parentView: parentView,
                                             viewBuilder: viewBuilder, fileOwner: fileOwner) else { return nil }
    let stylingProxy = viewBuilder.styler.style(for: element)
    
    if let elementId = node.elementId {
      stylingProxy.elementId = elementId
    }
    if let styleClasses = node.styleClasses {
      styleClasses.forEach {
        stylingProxy.addStyleClass($0)
      }
    }
    if let inlineStyle = node.inlineStyle {
      stylingProxy.inlineStyle = inlineStyle;
    }
    
    if let propertyName = node.fileOwnerPropertyName {
      setPropertyValue(element, withName: propertyName, inParent: parentView, orFileOwner: fileOwner)
    } else if let propertyName = node.elementId {
      setPropertyValue(element, withName: propertyName, inParent: parentView, orFileOwner: fileOwner, silent: true)
    }
    
    if let element = element as? UIView, let accessibilityIdentifier = node.accessibilityIdentifier {
      element.accessibilityIdentifier = accessibilityIdentifier
    }

    return element
  }
}


// MARK: - Private methods - element creation
private extension UIElementType {
  
  private func elementTypeToElement(forNode node: AbstractViewTreeNode, bodyContent: String?, parentView: AnyObject?, viewBuilder: ViewBuilder, fileOwner: AnyObject?) -> UIResponder? {
    let attributes = node.attributes
    
    switch self {
      case .button:
        let button = UIButton(type: attributes.buttonType.uiButtonType)
        button.setTitle(bodyContent ?? attributes.text, for: .normal)
        return button
      case .text:
        let label = UILabel(frame: .zero)
        label.text = bodyContent ?? attributes.text
        return label
      case .textInput:
        let textfield = UITextField(frame: .zero)
        textfield.text = bodyContent ?? attributes.text
        return textfield
      case .textArea:
        let textview = UITextView(frame: .zero)
        textview.text = bodyContent ?? attributes.text
        return textview
      case .image:
        var image: UIImage?
        if let name = bodyContent ?? attributes.src { image = UIImage(named: name) }
        return UIImageView(image: image)
      
      case .scrollView:
        let scroll = UIScrollView()
        if let delegate = fileOwner as? UIScrollViewDelegate {
          scroll.delegate = delegate
        }
        return scroll
      
      case .collectionView:
        return createCollectionView(layoutClass: attributes.collectionViewLayoutClass, fileOwner: fileOwner)
      case .collectionViewCell:
        if let elementClass = node.nodeViewClass(withStyler: viewBuilder.styler) as? LayoutCollectionViewCell.Type {
          registerCollectionViewCellClass(forNode: node, parentView: parentView, viewBuilder: viewBuilder, cellLayoutFile:attributes.layoutFile, elementClass: elementClass)
        } else {
          error(.layout, "Unable to register invalid UICollectionView cell class: \(attributes)")
        }
        return nil
      
      case .tableView:
        return createTableView(fileOwner: fileOwner)
      case .tableViewCell:
        if let elementClass = node.nodeViewClass(withStyler: viewBuilder.styler) as? LayoutTableViewCell.Type {
          registerTableViewCellClass(forNode: node, parentView: parentView, viewBuilder: viewBuilder, cellLayoutFile: attributes.layoutFile, elementClass: elementClass)
        } else {
          error(.layout, "Unable to register invalid UITableView cell class: \(attributes)")
        }
        return nil
      
      case .viewController:
        let elementClass = node.nodeViewClass(withStyler: viewBuilder.styler) as? UIViewController.Type
        return createViewController(viewBuilder: viewBuilder, fileOwner: fileOwner, layoutFile: attributes.layoutFile, elementClass: elementClass ?? UIViewController.self)
      
      default: /// i.e. view
        return node.nodeViewClass(withStyler: viewBuilder.styler).init()
    }
  }
}


// MARK: - Table view and collection view
private extension UIElementType {
  
  private func createCollectionView(layoutClass: UICollectionViewLayout.Type, fileOwner: AnyObject?) -> UICollectionView {
    let collectionView = LayoutCollectionView(frame: .zero, collectionViewLayout: layoutClass.init())
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
  
  private func registerCollectionViewCellClass(forNode node: AbstractViewTreeNode, parentView: AnyObject?, viewBuilder: ViewBuilder, cellLayoutFile: String?, elementClass: LayoutCollectionViewCell.Type?) {
    registerCellCompositeViewCellClass(forNode: node, parentView: parentView as? LayoutCollectionView, viewBuilder: viewBuilder, cellLayoutFile: cellLayoutFile, elementClass: elementClass)
  }
  
  private func registerTableViewCellClass(forNode node: AbstractViewTreeNode, parentView: AnyObject?, viewBuilder: ViewBuilder, cellLayoutFile: String?, elementClass: LayoutTableViewCell.Type?) {
    registerCellCompositeViewCellClass(forNode: node, parentView: parentView as? LayoutTableView, viewBuilder: viewBuilder, cellLayoutFile: cellLayoutFile, elementClass: elementClass)
  }
  
  private func registerCellCompositeViewCellClass<CellClass, CellCompositeView: LayoutCellCompositeView>(forNode node: AbstractViewTreeNode,
                                                                                                         parentView: CellCompositeView?, viewBuilder: ViewBuilder, cellLayoutFile: String?, elementClass: CellClass.Type?) where CellCompositeView.CellBaseClass == CellClass {
    if let cellId = node.elementId, let cellLayoutFile = cellLayoutFile, let cellCompositeView = parentView {
      if let elementClass = elementClass {
        cellCompositeView.registerCellLayout(cellIdentifier: cellId, cellClass: elementClass, layoutFile: cellLayoutFile, parentViewBuilder: viewBuilder)
      } else {
        cellCompositeView.registerCellLayout(cellIdentifier: cellId, layoutFile: cellLayoutFile, parentViewBuilder: viewBuilder)
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
      viewBuilder.logger.error("Cannot create child view controller - fileOwner must be a UIViewController!")
      return nil
    }
  }
}


// MARK: - Binding
private extension UIElementType {
  
  private func setPropertyValue(_ value: Any, withName propertyName: String, inParent parent: AnyObject?,
                                          orFileOwner fileOwner: AnyObject?, silent: Bool = false) {
    if let fileOwner = fileOwner, RuntimeIntrospectionUtils.doesClass(type(of: fileOwner), havePropertyWithName: propertyName) {
      RuntimeIntrospectionUtils.invokeSetter(forProperty: propertyName, ignoringCase: true, withValue: value, in: fileOwner)
    } else if let parent = parent, RuntimeIntrospectionUtils.doesClass(type(of: parent), havePropertyWithName: propertyName) {
      RuntimeIntrospectionUtils.invokeSetter(forProperty: propertyName, ignoringCase: true, withValue: value, in: parent)
    } else if !silent {
      if fileOwner != nil && parent != nil {
        Logger.layout.trace("Property '\(propertyName)' not found in file owner or parent view!")
      } else if fileOwner != nil {
        Logger.layout.trace("Property '\(propertyName)' not found in file owner!")
      } else if parent != nil {
        Logger.layout.trace("Property '\(propertyName)' not found in parent view!")
      } else {
        Logger.layout.trace("Unable to set property '\(propertyName)' - no file owner or parent view available!")
      }
    }
  }
}
