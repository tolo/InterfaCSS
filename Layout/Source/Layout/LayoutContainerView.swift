//
//  LayoutContainerView.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation
import YogaKit

public typealias LayoutViewDidLoadCallback = (LayoutContainerView, UIView) -> Void

/**
 * LayoutContainerView
 */
open class LayoutContainerView: UIView {

  override open var description: String {
    return "\(type(of: self))(\(viewBuilder.layoutFileURL.lastPathComponent))"
  }
  
  public private (set) var viewBuilder: ViewBuilder!
  public var layoutFileURL: URL { return viewBuilder.layoutFileURL }
  public private (set) var fileOwner: AnyObject?
  public var styler: Styler { return viewBuilder.styler }
  public let didLoadCallback: LayoutViewDidLoadCallback?

  public private (set) var layoutRefreshObserver: NotificationObserverToken?
  public private (set) var stylesheet: StyleSheet?
  public private (set) var stylesheetObserver: AnyObject?

  public private (set) var viewBuilt = false
  public private (set) var currentLayoutView: UIView?

  public var useSafeAreaConstraints: Bool = true
  public var useDefaultMargins: Bool = false

    
  public convenience init(mainBundleFile: String, viewBuilderClass: ViewBuilder.Type = ViewBuilder.defaultViewBuilderClass, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared, didLoadCallback: LayoutViewDidLoadCallback? = nil) {
    self.init(layoutFileURL: ResourceFile.mainBundeFile(filename: mainBundleFile).fileURL, fileOwner: fileOwner, styler: styler, didLoadCallback: didLoadCallback)
  }
  
  public convenience init(resourceFile: ResourceFile, viewBuilderClass: ViewBuilder.Type = ViewBuilder.defaultViewBuilderClass, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared, didLoadCallback: LayoutViewDidLoadCallback? = nil) {
    self.init(layoutFileURL: resourceFile.fileURL, refreshable: resourceFile.refreshable, fileOwner: fileOwner, styler: styler, didLoadCallback: didLoadCallback)
  }

  public required convenience init(layoutFileURL: URL, viewBuilderClass: ViewBuilder.Type = ViewBuilder.defaultViewBuilderClass, refreshable: Bool = false, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared, didLoadCallback: LayoutViewDidLoadCallback? = nil) {
    let viewBuilder = viewBuilderClass.init(layoutFileURL: layoutFileURL, refreshable: refreshable, fileOwner: fileOwner, styler: styler)
    self.init(viewBuilder: viewBuilder, fileOwner: fileOwner, didLoadCallback: didLoadCallback)
  }

  public required init(viewBuilder: ViewBuilder, fileOwner: AnyObject? = nil, didLoadCallback: LayoutViewDidLoadCallback? = nil) {
    self.viewBuilder = viewBuilder
    self.fileOwner = fileOwner
    self.didLoadCallback = didLoadCallback

    super.init(frame: .zero)

    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    
    let layoutFileURL = viewBuilder.layoutFileURL
    let refreshable = viewBuilder.refreshable
    if layoutFileURL.isFileURL {
      var cssFileName = layoutFileURL.lastPathComponent
      if cssFileName.hasData(), let lastDot = cssFileName.lastIndex(of: ".") {
        cssFileName = cssFileName[..<lastDot] + ".css"
        
        var components = layoutFileURL.pathComponents
        components.removeLast()
        components.append(cssFileName)
        let cssFilePath = components.joined(separator: "/")
        if FileManager.default.fileExists(atPath: cssFilePath) {
          let cssFileURL = URL(fileURLWithPath: cssFilePath)
          if refreshable {
            stylesheet = styler.loadStyleSheet(fromRefreshableFile: cssFileURL, name: cssFileName, group: viewBuilder.styleSheetGroupName)
          } else {
            stylesheet = styler.loadStyleSheet(fromLocalFile: cssFileURL, name: cssFileName, group: viewBuilder.styleSheetGroupName)
          }

          stylesheetObserver = iCSS.didRefreshStyleSheetNotification.observe { [weak self] in
            self?.updateLayout()
          }
        }
      }
    }
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override func didMoveToSuperview() {
    super.didMoveToSuperview()
    if superview != nil {
        buildView()
    }
  }
  
  open override func didMoveToWindow() {
    super.didMoveToWindow()
    if window == nil {
      layoutRefreshObserver = nil // Unregister any refresh observer when moving out of view hieararchy
    }
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    guard let currentLayoutView = currentLayoutView else { return }
    
    var rect = bounds
    if self.useSafeAreaConstraints {
      rect = rect.inset(by: self.safeAreaInsets)
    }
    else if self.useDefaultMargins {
      rect = rect.inset(by: self.layoutMargins)
    }
    currentLayoutView.frame = rect
    viewBuilder.applyLayout(onView: currentLayoutView)
  }


  private func viewSetupCallback() -> (UIView?, [UIViewController]?, AbstractLayout?, Error?) -> Void {
    return { [weak self] (view, childViewControllers, layout, error) in self?.setup(view: view, childViewControllers: childViewControllers, layout: layout, error: error) }
  }

  private func setup(view: UIView?, childViewControllers: [UIViewController]?, layout: AbstractLayout?, error: Error?) {
    guard let view = view else {
      // TODO: Log error
      return
    }
    
    if let layout = layout {
      useSafeAreaConstraints = layout.layoutAttributes.useSafeAreaInsets
      useDefaultMargins = layout.layoutAttributes.useDefaultMargins
    }

    currentLayoutView?.removeFromSuperview()
    currentLayoutView = view

    view.frame = self.bounds
    self.addSubview(view)

    styler.applyStyling(self)
    
    self.didLoadCurrentLayoutView(view: view)

    setNeedsLayout()
    layoutIfNeeded()
  }


  open func didLoadCurrentLayoutView(view: UIView) {
    didLoadCallback?(self, view)
    viewBuilder.applyLayout(onView: view)
  }


  open func buildView() {
    guard !viewBuilt else {
      if layoutRefreshObserver == nil {
        layoutRefreshObserver = viewBuilder.addRefreshObserverIfSupported(completionHandler: self.viewSetupCallback())
      }
      return
    }
    layoutRefreshObserver = viewBuilder.buildView(fileOwner: fileOwner, completionHandler: self.viewSetupCallback())
    viewBuilt = true
  }

  open func updateLayout() {
    guard let currentLayoutView = currentLayoutView else { return }
    
    styler.applyStyling(currentLayoutView)
    setNeedsLayout()
    layoutIfNeeded()
  }
  
  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return sizeThatFits(size, layoutDimension: .both)
  }
  
  open func sizeThatFits(_ size: CGSize, layoutDimension: LayoutDimension) -> CGSize {
    guard let currentLayoutView = currentLayoutView else {
      return super.sizeThatFits(size)
    }

    var tempRect = CGRect(origin: .zero, size: size)
    if self.useSafeAreaConstraints {
      tempRect = tempRect.inset(by: self.safeAreaInsets)
    }
    else if self.useDefaultMargins {
      tempRect = tempRect.inset(by: self.layoutMargins)
    }

    return viewBuilder.calculateLayoutSize(forView: currentLayoutView, fittingSize: tempRect.size, layoutDimension: layoutDimension)
  }
}
