//
//  LayoutViewController.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit

/**
 * LayoutViewController
 */
open class LayoutViewController: UIViewController {
  
  public class var layoutContainerViewClass: LayoutContainerView.Type { return LayoutContainerView.self }
  
  public private(set) var layoutContainerView: LayoutContainerView!
  
  open override func loadView() {
    layoutContainerView = loadLayoutContainerView()
    self.view = layoutContainerView
  }
  
  open func loadLayoutContainerView() -> LayoutContainerView {
    let className = String(describing: type(of: self))
    return createLayoutContainerView(mainBundleFile: "\(className).xml")
  }
  
  public final func createLayoutContainerView(mainBundleFile: String, styler: Styler = StylingManager.shared()) -> LayoutContainerView {
    guard let url = Bundle.main.url(forResource: mainBundleFile, withExtension: nil) else {
      preconditionFailure("Main bundle file '\(mainBundleFile)' does not exist!")
    }
    return createLayoutContainerView(layoutFileURL: url, refreshable: false, styler: styler)
  }
  
  public final func createLayoutContainerView(bundleFile: BundleFile, styler: Styler = StylingManager.shared()) -> LayoutContainerView {
    guard let url = bundleFile.fileURL else {
      preconditionFailure("Bundle file '\(bundleFile.filename)' does not exist!")
    }
    return createLayoutContainerView(layoutFileURL: url, refreshable: bundleFile.refreshable, styler: styler)
  }
  
  public final func createLayoutContainerView(layoutFileURL: URL, refreshable: Bool, styler: Styler = StylingManager.shared()) -> LayoutContainerView {
    if title == nil {
        title = layoutFileURL.lastPathComponent
    }
    return type(of: self).layoutContainerViewClass.init(layoutFileURL: layoutFileURL, refreshable: refreshable, fileOwner: self, styler: styler, didLoadCallback: layoutViewDidLoadCallback())
  }
  
  
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator);
    coordinator.animate(alongsideTransition: { _ in
      self.layoutContainerView.updateLayout()
    }, completion: nil)
  }
  
  
  private func layoutViewDidLoadCallback() -> (LayoutContainerView, UIView) -> Void {
    return { [weak self] (container, view) in self?.layout(view: view, didLoadIn: container) }
  }
  
  open func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {}
}

/**
 * FlexLayoutViewController
 */
open class FlexLayoutViewController: LayoutViewController {
  public class override var layoutContainerViewClass: LayoutContainerView.Type { return FlexLayoutContainerView.self }
}
