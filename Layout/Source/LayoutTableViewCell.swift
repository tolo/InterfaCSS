//
//  LayoutTableViewCell.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit

/**
 * LayoutTableViewCell
 */
open class LayoutTableViewCell: UITableViewCell {

  var layoutContainerView: LayoutContainerView!
  
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
  
  open func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {}

  open func populateCell() {}
  
  public func updateLayout() {
    layoutContainerView.updateLayout()
  }

  open func calculateContentHeightThatFits(_ size: CGSize) -> CGFloat {
    return layoutContainerView.sizeThatFits(size).height
  }
    
  override open func layoutSubviews() {
    layoutContainerView?.frame = contentView.bounds
    super.layoutSubviews()
  }
}
