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
  
  public private(set) var layoutContainerView: LayoutContainerView!
  
  // MARK: - UIViewController
  
  open override func loadView() {
    layoutContainerView = loadLayoutContainerView()
    self.view = layoutContainerView
  }
  
  open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator);
    coordinator.animate(alongsideTransition: { _ in
      self.layoutContainerView.updateLayout()
    }, completion: nil)
  }
  
  
  // MARK: - LayoutViewController main API
  
  open func loadLayoutContainerView() -> LayoutContainerView {
    let className = String(describing: type(of: self))
    return createLayoutContainerView(mainBundleFile: "\(className).xml")
  }
  
  private func layoutViewDidLoadCallback() -> (LayoutContainerView, UIView) -> Void {
    return { [weak self] (container, view) in self?.layout(view: view, didLoadIn: container) }
  }
  
  open func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {
    if title == nil {
      title = layoutContainerView.layoutFileURL.lastPathComponent
    }
  }
  
  
  // MARK: - LayoutContainerView creation support
  
  public final func createLayoutContainerView(mainBundleFile: String, styler: Styler = StylingManager.shared()) -> LayoutContainerView {
    return createLayoutContainerView(layoutFileURL: BundleFile.mainBundeFile(filename: mainBundleFile).fileURL, refreshable: false, styler: styler)
  }
  
  public final func createLayoutContainerView(refreshableProjectFile projectFile: String, relativeToDirectoryContaining currentFile: String, styler: Styler = StylingManager.shared()) -> LayoutContainerView {
    let bundleFile = BundleFile.refreshableProjectFile(projectFile, relativeToDirectoryContaining: currentFile)
    return createLayoutContainerView(layoutFileURL: bundleFile.fileURL, refreshable: bundleFile.refreshable, styler: styler)
  }
  
  public final func createLayoutContainerView(bundleFile: BundleFile, styler: Styler = StylingManager.shared()) -> LayoutContainerView {
    return createLayoutContainerView(layoutFileURL: bundleFile.fileURL, refreshable: bundleFile.refreshable, styler: styler)
  }
  
  public final func createLayoutContainerView(layoutFileURL: URL, refreshable: Bool = false, styler: Styler = StylingManager.shared(),
                                              viewBuilderClass: ViewBuilder.Type = ViewBuilder.defaultViewBuilderClass) -> LayoutContainerView {
    return LayoutContainerView(layoutFileURL: layoutFileURL, viewBuilderClass: viewBuilderClass, refreshable: refreshable, fileOwner: self, styler: styler, didLoadCallback: layoutViewDidLoadCallback())
  }
}
