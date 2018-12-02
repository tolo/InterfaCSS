//
//  LayoutContainerView.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation
import YogaKit

/**
 * LayoutContainerView
 */
open class LayoutContainerView: UIView {
  public typealias DidLoadCallback = (LayoutContainerView, UIView) -> Void

  public let layoutFileURL: URL
  public private (set) var viewBuilder: ViewBuilder!
  public var styler: Styler { return viewBuilder.styler }
  public let didLoadCallback: DidLoadCallback?

  public private (set) var refresher: RefreshableResource?
  public private (set) var stylesheet: StyleSheet?
  public private (set) var stylesheetObserver: AnyObject?

  public private (set) var viewBuilt = false
  public private (set) var currentLayoutView: UIView?

  public var addLayoutConstraints: Bool = true
  public var useSafeAreaConstraints: Bool = true
  public var useDefaultMargins: Bool = false

  public class var viewBuilderClass: ViewBuilder.Type { return ViewBuilder.self }
  
  open func createViewBuilder(layoutFileURL: URL, fileOwner: AnyObject?, styler: Styler) -> ViewBuilder {
    return type(of: self).viewBuilderClass.init(layoutFileURL: layoutFileURL, fileOwner: fileOwner, styler: styler)
  }

  
  public convenience init(mainBundleFile: String, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared(), didLoadCallback: DidLoadCallback? = nil) {
    guard let url = Bundle.main.url(forResource: mainBundleFile, withExtension: nil) else {
      preconditionFailure("Main bundle file '\(mainBundleFile)' does not exist!")
    }
    self.init(layoutFileURL: url, fileOwner: fileOwner, styler: styler, didLoadCallback: didLoadCallback)
  }
  
  public convenience init(bundleFile: BundleFile, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared(), didLoadCallback: DidLoadCallback? = nil) {
    guard let url = bundleFile.fileURL else {
      preconditionFailure("Bundle file '\(bundleFile.filename)' does not exist!")
    }
    self.init(layoutFileURL: url, refreshable: bundleFile.refreshable, fileOwner: fileOwner, styler: styler, didLoadCallback: didLoadCallback)
  }

  public required init(layoutFileURL: URL, refreshable: Bool = false, fileOwner: AnyObject? = nil, styler: Styler = StylingManager.shared(), didLoadCallback: DidLoadCallback? = nil) {
    self.layoutFileURL = layoutFileURL
    self.didLoadCallback = didLoadCallback

    super.init(frame: .zero)
    
    self.viewBuilder = createViewBuilder(layoutFileURL: layoutFileURL, fileOwner: fileOwner, styler: styler)

    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    
    if refreshable {
      if layoutFileURL.isFileURL {
        refresher = RefreshableLocalResource(url: layoutFileURL)
      }
//      else { // TODO: Support remote reloadable layout files?
//        refresher = RefreshableRemoteResource(url: url)
//      }
    }
    
    if layoutFileURL.isFileURL {
      var cssFileName = layoutFileURL.lastPathComponent
      if cssFileName.iss_hasData(), let lastDot = cssFileName.lastIndex(of: ".") {
        cssFileName = cssFileName[..<lastDot] + ".css"
        
        var components = layoutFileURL.pathComponents
        components.removeLast()
        components.append(cssFileName)
        let cssFilePath = components.joined(separator: "/")
        if FileManager.default.fileExists(atPath: cssFilePath) {
          let cssFileURL = URL(fileURLWithPath: cssFilePath)
          if refreshable {
            stylesheet = styler.styleSheetManager.loadRefreshableNamedStyleSheet(cssFileName, group: viewBuilder.styleSheetGroupName, from: cssFileURL)
          } else {
            stylesheet = styler.styleSheetManager.loadNamedStyleSheet(cssFileName, group: viewBuilder.styleSheetGroupName, fromFileURL: cssFileURL)
          }

          stylesheetObserver = NotificationCenter.default.addObserver(forName: .StyleSheetRefreshed, object: stylesheet, queue: nil) { [weak self] _ in
            self?.updateLayout()
          }
        }
      }
    }
  }

  required public init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  deinit {
    refresher?.endMonitoringResourceModification()
  }

  open override func didMoveToSuperview() {
    super.didMoveToSuperview()
    buildView()
  }

  override open func layoutSubviews() {
    super.layoutSubviews()
    var rect = bounds
    if self.useSafeAreaConstraints {
      rect = rect.inset(by: self.safeAreaInsets)
    }
    else if self.useDefaultMargins {
      rect = rect.inset(by: self.layoutMargins)
    }
    currentLayoutView?.frame = rect
  }


  private func viewSetupCallback() -> (UIView?, AbstractLayout?, Error?) -> Void {
    return { [weak self] (view, layout, error) in self?.setup(view: view, layout: layout, error: error) }
  }

  private func setup(view: UIView?, layout: AbstractLayout?, error: Error?) {
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
  }


  public func buildView(addLayoutConstraints: Bool = true, useSafeAreaConstraints: Bool = true) {
    guard !viewBuilt else {
      return
    }
    viewBuilder.buildView(completionHandler: self.viewSetupCallback())
    viewBuilt = true

    if refresher?.resourceModificationMonitoringSupported == true {
      refresher?.startMonitoringResourceModification({ [unowned self] resource in
        self.viewBuilder.buildView(completionHandler: self.viewSetupCallback())
      })
    }
  }

  open func updateLayout() {}
}


/**
 * FlexLayoutContainerView
 */
open class FlexLayoutContainerView: LayoutContainerView {
  
  public override class var viewBuilderClass: ViewBuilder.Type { return FlexLayoutViewBuilder.self }

  override open func layoutSubviews() {
    super.layoutSubviews()
    currentLayoutView?.yoga.applyLayout(preservingOrigin: true)
  }

  override open func didLoadCurrentLayoutView(view: UIView) {
    super.didLoadCurrentLayoutView(view: view)
    view.yoga.applyLayout(preservingOrigin: true)
  }

  override open func updateLayout() {
    super.updateLayout()
    guard let currentLayoutView = currentLayoutView else {
      return
    }
    styler.applyStyling(currentLayoutView)
    currentLayoutView.yoga.applyLayout(preservingOrigin: true)
  }
}
