//
//  ViewBuilder.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit


public typealias ViewBuilderCompletionHandler = (_ rootView: UIView?, _ layout: AbstractLayout?, _ parseError: Error?) -> Void

public typealias ViewBuilderLayoutRefreshedObserver = NSObjectProtocol

extension Notification.Name {
  public static let ViewBuilderLayoutRefreshed = Notification.Name(rawValue: "ISSViewBuilderLayoutRefreshedNotification")
}

open class ViewBuilder {

  let logger: Logger

  public static let defaultViewBuilderClass: ViewBuilder.Type = FlexViewBuilder.self
  
  typealias ViewBuilderLayoutRefreshedData = (abstractLayout: AbstractLayout?, parseError: Error?)
  static let ViewBuilderLayoutRefreshedDataKay = "layout"

  public let layoutFileURL: URL
  public let refreshable: Bool
  public weak var defaultFileOwner: AnyObject?
  public let styleSheetName: String
  public let styleSheetGroupName: String
  public let styler: Styler
  
  public private (set) var refresher: RefreshableResource?
  public private (set) var embeddedStyleSheet: StyleSheet?

  public private (set) var lastLayout: AbstractLayout?

  private let dispatchQueue: DispatchQueue

  public required init(layoutFileURL: URL, refreshable: Bool = false, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared()) {
    self.layoutFileURL = layoutFileURL
    self.refreshable = refreshable
    self.defaultFileOwner = fileOwner
    self.styleSheetName = layoutFileURL.lastPathComponent
    self.styleSheetGroupName = self.styleSheetName
    self.styler = styler.withScope(StyleSheetScope(styleSheetGroups: [self.styleSheetGroupName]), includeCurrent: true)

    if refreshable {
      if layoutFileURL.isFileURL {
        refresher = RefreshableLocalResource(url: layoutFileURL)
      }
//      else { // TODO: Support remote reloadable layout files?
//        refresher = RefreshableRemoteResource(url: url)
//      }
    }

    self.dispatchQueue = DispatchQueue(label: "ViewBuilder", qos: .background)
    self.logger = Logger("\(type(of:self))(\(layoutFileURL.lastPathComponent))")
  }

  deinit {
    refresher?.endMonitoringResourceModification()
  }


  // MARK: - Main public API
  
  public final func buildView(forceRefresh: Bool = false, fileOwner: AnyObject? = nil, completionHandler: @escaping ViewBuilderCompletionHandler) -> NotificationObserverToken? {
    weak var effectiveFileOwner = fileOwner ?? defaultFileOwner

    var layoutExists = false
    if !forceRefresh {
      layoutExists = buildViewFromLastLayout(fileOwner: effectiveFileOwner, completionHandler: completionHandler) == true
      logger.logTrace(message: "buildViewFromLastLayout - layoutExists: \(layoutExists)")
    }
    if !layoutExists {
      self.dispatchQueue.async { [weak self] in
        var layoutExists = false
        if !forceRefresh {
          DispatchQueue.main.sync {
            self?.logger.logDebug(message: "buildViewFromLastLayout")
            layoutExists = self?.buildViewFromLastLayout(fileOwner: effectiveFileOwner, completionHandler: completionHandler) == true
          }
        }
        if layoutExists { return }

        if let self = self, let data = try? Data(contentsOf: self.layoutFileURL) {
          DispatchQueue.main.sync { [weak self] in
            self?.logger.logDebug(message: "building initial view")
            self?.buildInitialView(fromData: data, fileOwner: effectiveFileOwner, completionHandler: completionHandler)
            self?.startRefresherIfSupported()
          }
        } else {
          DispatchQueue.main.sync {
            completionHandler(nil, nil, nil) // TODO: Error?
          }
        }
      }
    }
    
    return addRefreshObserverIfSupported(fileOwner: effectiveFileOwner, completionHandler: completionHandler)
  }
  
  public final func addRefreshObserverIfSupported(fileOwner: AnyObject? = nil, completionHandler: @escaping ViewBuilderCompletionHandler) -> NotificationObserverToken? {
    weak var effectiveFileOwner = fileOwner ?? defaultFileOwner
    if let refresher = refresher, refresher.resourceModificationMonitoringSupported {
      let token = NotificationCenter.default.addObserver(forName: .ViewBuilderLayoutRefreshed, object: self, queue: nil) { [weak self] notification in
        guard let self = self, let (_, _) = notification.userInfo?[ViewBuilder.ViewBuilderLayoutRefreshedDataKay] as? ViewBuilderLayoutRefreshedData else {
          completionHandler(nil, nil, nil) // TODO: Error?
          return
        }
        self.buildViewFromLastLayout(fileOwner: effectiveFileOwner, notifyOnError: true, completionHandler: completionHandler)
      }
      return NotificationObserverToken(token: token)
    } else {
      return nil
    }
  }

  open func createLayoutView(fileOwner: AnyObject? = nil, didLoadCallback: LayoutViewDidLoadCallback? = nil) -> LayoutContainerView {
    return LayoutContainerView(viewBuilder: self, fileOwner: fileOwner, didLoadCallback: didLoadCallback)
  }
  
  open func applyLayout(onView view: UIView) {}
  
  open func calculateLayoutSize(forView view: UIView, fittingSize size: CGSize) -> CGSize {
    return view.sizeThatFits(size)
  }
  
  
  // MARK: - Internal layout/view building methods
  
  private final func buildInitialView(fromData data: Data, fileOwner: AnyObject?, completionHandler: @escaping ViewBuilderCompletionHandler) {
    buildLayout(fromData: data) { (parsedLayout, parseError) in
      guard let layout = parsedLayout, let rootView = buildView(fromLayout: layout, fileOwner: fileOwner) else {
        completionHandler(nil, parsedLayout, parseError)
        return
      }
      completionHandler(rootView, layout, parseError)
    }
  }
  
  @discardableResult
  private final func buildViewFromLastLayout(fileOwner: AnyObject?, notifyOnError: Bool = false, completionHandler: @escaping ViewBuilderCompletionHandler) -> Bool {
    if let lastLayout = lastLayout {
      let rootView = buildView(fromLayout: lastLayout, fileOwner: fileOwner)
      completionHandler(rootView, lastLayout, nil)
      return true
    } else if notifyOnError {
      completionHandler(nil, nil, nil) // TODO: Error?
    }
    return false
  }
  
  private final func startRefresherIfSupported() {
    // Start refresher, if not started:
    if let refresher = refresher, refresher.resourceModificationMonitoringSupported, !refresher.resourceModificationMonitoringEnabled {
      refresher.startMonitoringResourceModification({ [weak self] resource in
        self?.refreshLayout()
      })
    }
  }
  
  private final func refreshLayout() {
    dispatchQueue.async { [weak self] in
      guard let self = self, let data = try? Data(contentsOf: self.layoutFileURL) else { return }
      DispatchQueue.main.sync {
        self.buildLayout(fromData: data) { (parsedLayout, parseError) in
          NotificationCenter.default.post(name: .ViewBuilderLayoutRefreshed, object: self, userInfo: [ViewBuilder.ViewBuilderLayoutRefreshedDataKay: (parsedLayout, parseError)])
        }
      }
    }
  }
  
  private final func buildLayout(fromData data: Data, completionHandler: AbstractLayoutCompletionHandler) {
    let parser = AbstractViewTreeParser(data: data, styler: styler)
    parser.parse { [weak self] (parsedLayout, parseError) in
      if let parsedLayout = parsedLayout {
        self?.lastLayout = parsedLayout
      }
      if let self = self, let styleSheetContent = parsedLayout?.layoutStyle {
        if let styleSheet = embeddedStyleSheet {
          styler.styleSheetManager.unloadStyleSheet(styleSheet)
        }
        embeddedStyleSheet = StyleSheet(styleSheetURL: layoutFileURL, name: self.styleSheetName, group: self.styleSheetGroupName, content: styleSheetContent)
        styler.styleSheetManager.registerStyleSheet(embeddedStyleSheet!)
      }
        
      completionHandler(parsedLayout, parseError)
    }
  }

  private final func buildView(fromLayout layout: AbstractLayout, fileOwner: AnyObject?) -> UIView? {
    guard let rootView = createViewTree(withRootNode: layout.rootNode, fileOwner: fileOwner) else {
      return nil
    }

    styler.applyStyling(rootView)
    return rootView
  }


  // MARK: - Support methods (for subclasses)

  open func createViewTree(withRootNode root: AbstractViewTreeNode, fileOwner: AnyObject? = nil) -> UIView? {
    return root.visitAbstractViewTree() { (node, parentNode, parentView) in
      guard let view = createViewFrom(node: node, parentView: parentView, fileOwner: fileOwner) else {
        return nil
      }
      if let parentView = parentView as? UIView, node.addToViewHierarchy {
        addViewObject(view, toParentView: parentView)
      }
      return view
    } as? UIView
  }

  open func createViewFrom(node: AbstractViewTreeNode, parentView: AnyObject?, fileOwner: AnyObject?) -> AnyObject? {
    let viewObject = instantiateViewObject(for: node, parentView: parentView, fileOwner: fileOwner)
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

  open func instantiateViewObject(for node: AbstractViewTreeNode, parentView: AnyObject?, fileOwner: AnyObject?) -> AnyObject? {
    return node.elementType.createElement(forNode: node, parentView: parentView, viewBuilder: self, fileOwner: fileOwner)
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
        logger.logDebug(message: "Property '\(propertyName)' not found in file owner or parent view!")
      } else if fileOwner != nil {
        logger.logDebug(message: "Property '\(propertyName)' not found in file owner!")
      } else if parent != nil {
        logger.logDebug(message: "Property '\(propertyName)' not found in parent view!")
      } else {
        logger.logDebug(message: "Unable to set property '\(propertyName)' - no file owner or parent view available!")
      }
    }
  }
}
