//
//  LayoutCell.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit

/**
 * LayoutCell
 */
public protocol LayoutCell: Stylable {
  var layoutContainerView: LayoutContainerView! { get set }
  var contentView: UIView { get }
  
  func configureLayout(withViewBuilder viewBuilder: ViewBuilder, didLoadCallback: LayoutViewDidLoadCallback?)
  func updateLayout()
  
  func layout(view: UIView, didLoadIn containerView: LayoutContainerView)
  func populateCell()
}

public extension LayoutCell where Self: UIView {
  
  // MARK: - LayoutCell main API
  
  func configureLayout(withViewBuilder viewBuilder: ViewBuilder, didLoadCallback: LayoutViewDidLoadCallback? = nil) {
    guard layoutContainerView == nil else {
      return
    }
    layoutContainerView = viewBuilder.createLayoutView(fileOwner: self) { [weak self] (container, view) in
      didLoadCallback?(container, view)
      self?.layout(view: view, didLoadIn: container)
    }
    layoutContainerView.translatesAutoresizingMaskIntoConstraints = false
    layoutContainerView.frame = contentView.frame
    contentView.addSubview(layoutContainerView)
  }
  
  func updateLayout() {
    layoutContainerView.updateLayout()
  }
  
  // MARK: - Helper methods
  
  func calculateSizeThatFits(_ size: CGSize) -> CGSize {
    let contentViewSize = contentView.sizeThatFits(size)
    let result = layoutContainerView.sizeThatFits(contentViewSize, layoutDimension: .height)
    return CGSize(width: size.width, height: result.height)
  }
  
}


/**
 * LayoutTableViewCell
 */
open class LayoutTableViewCell: UITableViewCell, LayoutCell {

  public var layoutContainerView: LayoutContainerView!

  override open func layoutSubviews() {
    layoutContainerView?.frame = contentView.bounds
    super.layoutSubviews()
  }
  
  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return calculateSizeThatFits(size)
  }
  
  open override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)
    guard let layoutContainerView = layoutContainerView else { return }
    layoutContainerView.styler.applyStyling(self)
  }

  // MARK: - LayoutCell sub class interface
  
  open func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {
    populateCell()
  }
  
  open func populateCell() {}
}


/**
 * LayoutCollectionViewCell
 */
open class LayoutCollectionViewCell: UICollectionViewCell, LayoutCell {
  
  public var layoutContainerView: LayoutContainerView!
  
  override open func layoutSubviews() {
    layoutContainerView?.frame = contentView.bounds
    super.layoutSubviews()
  }
  
  open override func sizeThatFits(_ size: CGSize) -> CGSize {
    return calculateSizeThatFits(size)
  }
  
  // MARK: - LayoutCell sub class interface
  
  open func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {
    populateCell()
  }
  
  open func populateCell() {}
}
