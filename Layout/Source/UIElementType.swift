//
//  UIElementType.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit

public enum UIElementType {
  
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
  
  case button(type: ButtonType, title: String?)
  case imageView(image: UIImage?)
  case label(text: String?)
  case textField(text: String?)
  case textView(text: String?)
  case collectionView(layoutClass: UICollectionViewLayout.Type)
  case tableView
  case tableViewCell(cellLayoutFile: String?, elementClass: LayoutTableViewCell.Type?)
  case viewController(layoutFile: String?, elementClass: UIViewController.Type)
  case other(elementClass: UIResponder.Type)
  
  public func createElement(forNode node: AbstractViewTreeNode, parentView: AnyObject?, viewBuilder: ViewBuilder, fileOwner: AnyObject?) -> UIResponder? {
    guard let element = elementTypeToElement(forNode: node, parentView: parentView, viewBuilder: viewBuilder, fileOwner: fileOwner),
      let stylingProxy = viewBuilder.styler.stylingProxy(for: element) else { return nil }
    
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
    if let stringContent = node.stringContent, stringContent.iss_hasData() {
      if let label = element as? UILabel {
        label.text = stringContent
      } else if let button = element as? UIButton {
        button.setTitle(stringContent, for: .normal)
      } else if let textInput = element as? UITextField {
        textInput.text = stringContent
      } else if let textInput = element as? UITextView {
        textInput.text = stringContent
      } else if let imageView = element as? UIImageView {
        imageView.image = UIImage(named: stringContent)
      }
    }
    return element
  }
}


// MARK: - Private methods - element creation
private extension UIElementType {
  
  private func elementTypeToElement(forNode node: AbstractViewTreeNode, parentView: AnyObject?, viewBuilder: ViewBuilder, fileOwner: AnyObject?) -> UIResponder? {
    switch self {
    case .button(let type, let title):
      let button = UIButton(type: type.uiButtonType)
      button.setTitle(title, for: .normal)
      return button
    case .label(let text):
      let label = UILabel(frame: .zero)
      label.text = text
      return label
    case .textField(let text):
      let textfield = UITextField(frame: .zero)
      textfield.text = text
      return textfield
    case .textView(let text):
      let textview = UITextView(frame: .zero)
      textview.text = text
      return textview
    case .imageView(let image):
      return UIImageView(image: image)
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


// MARK: - Private methods - binding
private extension UIElementType {
  
  private func setPropertyValue(_ value: Any, withName propertyName: String, inParent parent: AnyObject?,
                                          orFileOwner fileOwner: AnyObject?, silent: Bool = false) {
    if let fileOwner = fileOwner, ISSRuntimeIntrospectionUtils.doesClass(type(of: fileOwner), havePropertyWithName: propertyName) {
      ISSRuntimeIntrospectionUtils.invokeSetter(forProperty: propertyName, ignoringCase: true, withValue: value, in: fileOwner)
    } else if let parent = parent, ISSRuntimeIntrospectionUtils.doesClass(type(of: parent), havePropertyWithName: propertyName) {
      ISSRuntimeIntrospectionUtils.invokeSetter(forProperty: propertyName, ignoringCase: true, withValue: value, in: parent)
    } else if !silent {
      if fileOwner != nil && parent != nil {
        Logger.shared.logDebug(message: "Property '\(propertyName)' not found in file owner or parent view!")
      } else if fileOwner != nil {
        Logger.shared.logDebug(message: "Property '\(propertyName)' not found in file owner!")
      } else if parent != nil {
        Logger.shared.logDebug(message: "Property '\(propertyName)' not found in parent view!")
      } else {
        Logger.shared.logDebug(message: "Unable to set property '\(propertyName)' - no file owner or parent view available!")
      }
    }
  }
}
