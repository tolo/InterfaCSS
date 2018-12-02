//
//  ViewBuilder.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit


public typealias ViewBuilderCompletionHandler = (_ rootView: UIView?, _ layout: AbstractLayout?, _ parseError: Error?) -> Void


open class ViewBuilder {

  public let layoutFileURL: URL
  public let fileOwner: AnyObject?
  public let styleSheetName: String
  public let styleSheetGroupName: String
  public let styler: Styler

  public private(set) var styleSheet: StyleSheet?

  public convenience init(mainBundleFile: String, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared()) {
    guard let url = Bundle.main.url(forResource: mainBundleFile, withExtension: nil) else {
      preconditionFailure("Main bundle file '\(mainBundleFile)' does not exist!")
    }
    self.init(layoutFileURL: url, fileOwner: fileOwner, styler: styler)
  }

  public required init(layoutFileURL: URL, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared()) {
    self.layoutFileURL = layoutFileURL
    self.fileOwner = fileOwner
    self.styleSheetName = layoutFileURL.lastPathComponent
    self.styleSheetGroupName = self.styleSheetName
//    self.styler = styler.withScope(StyleSheetScope(styleSheetNames: [self.styleSheetName]), includeCurrent: true)
    self.styler = styler.withScope(StyleSheetScope(styleSheetGroups: [self.styleSheetGroupName]), includeCurrent: true)
  }


  // MARK: - Main public API

  public final func buildView(completionHandler: @escaping ViewBuilderCompletionHandler) {
    DispatchQueue.global(qos: .background).async { [weak self] in
      if let self = self, let data = try? Data(contentsOf: self.layoutFileURL) {
        DispatchQueue.main.async {
          self.buildView(fromData: data, completionHandler: completionHandler)
        }
      } else {
        completionHandler(nil, nil, nil) // TODO: Error?
      }
    }
  }

  private final func buildView(fromData data: Data, completionHandler: ViewBuilderCompletionHandler) {
    let parser = AbstractViewTreeParser(data: data, fileOwner: fileOwner, styler: styler)
    parser.parse { (layout, error) in
      guard let rootNode = layout?.rootNode, let rootView = createViewTree(withRootNode: rootNode, fileOwner: fileOwner) else {
        completionHandler(nil, layout, error)
        return
      }
      if let styleSheetContent = layout?.layoutStyle {
        if let styleSheet = styleSheet {
          styler.styleSheetManager.unloadStyleSheet(styleSheet)
        }
        styleSheet = StyleSheet(styleSheetURL: layoutFileURL, name: self.styleSheetName, group: self.styleSheetGroupName, content: styleSheetContent)
        styler.styleSheetManager.registerStyleSheet(styleSheet!)
      }
      styler.applyStyling(rootView)
      completionHandler(rootView, layout, error)
    }
  }


  // MARK: - Support methods (for subclasses)

  open func createViewTree(withRootNode root: AbstractViewTreeNode, fileOwner: AnyObject? = nil) -> UIView? {
    return root.visitAbstractViewTree() { (node, parentNode, parentView) in
      guard let view = createViewFrom(node: node, parentView: parentView, fileOwner: fileOwner) else {
        return nil
      }
      if let parentView = parentView as? UIView {
        addViewObject(view, toParentView: parentView)
      }
      return view
    } as? UIView
  }

  open func createViewFrom(node: AbstractViewTreeNode, parentView: AnyObject?, fileOwner: AnyObject?) -> AnyObject? {
    let viewObject = instantiateViewObject(for: node)
    if let viewObject = viewObject, let stylingProxy = styler.stylingProxy(for: viewObject) {
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
      if let viewObject = viewObject as? UIView, let accessibilityIdentifier = node.accessibilityIdentifier {
        viewObject.accessibilityIdentifier = accessibilityIdentifier
      }
      if let stringContent = node.stringContent {
        if let label = viewObject as? UILabel {
          label.text = stringContent
        } else if let button = viewObject as? UIButton {
          button.setTitle(stringContent, for: .normal)
        } else if let textInput = viewObject as? UITextField {
          textInput.text = stringContent
        } else if let textInput = viewObject as? UITextView {
          textInput.text = stringContent
        }
      }
      if let propertyName = node.fileOwnerPropertyName {
        setViewObjectPropertyValue(viewObject, withName: propertyName, inParent: parentView, orFileOwner: fileOwner)
      } else if let propertyName = node.elementId {
        setViewObjectPropertyValue(viewObject, withName: propertyName, inParent: parentView, orFileOwner: fileOwner, silent: true)
      }
    }
    return viewObject
  }

  open func addViewObject(_ viewObject: AnyObject, toParentView parentView: AnyObject) {
    if let view = viewObject as? UIView, let parentView = parentView as? UIView {
      parentView.addSubview(view)
    }
  }

  open func instantiateViewObject(for node: AbstractViewTreeNode) -> AnyObject? {
    return node.elementType.createElement()
  }
}


// MARK: - Private methods
extension ViewBuilder {

  private func setViewObjectPropertyValue(_ value: Any, withName propertyName: String, inParent parent: AnyObject?,
                                          orFileOwner fileOwner: AnyObject?, silent: Bool = false) {
    if let fileOwner = fileOwner, ISSRuntimeIntrospectionUtils.doesClass(type(of: fileOwner), havePropertyWithName: propertyName) {
      ISSRuntimeIntrospectionUtils.invokeSetter(forProperty: propertyName, ignoringCase: true, withValue: value, in: fileOwner)
    } else if let parent = parent, ISSRuntimeIntrospectionUtils.doesClass(type(of: parent), havePropertyWithName: propertyName) {
      ISSRuntimeIntrospectionUtils.invokeSetter(forProperty: propertyName, ignoringCase: true, withValue: value, in: parent)
    } else if !silent {
      if fileOwner != nil && parent != nil {
        print("Property '\(propertyName)' not found in file owner or parent view!")
      } else if fileOwner != nil {
        print("Property '\(propertyName)' not found in file owner!")
      } else if parent != nil {
        print("Property '\(propertyName)' not found in parent view!")
      } else {
        print("Unable to set property '\(propertyName)' - no file owner or parent view available!")
      }
    }
  }
}
