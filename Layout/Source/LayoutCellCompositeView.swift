//
//  LayoutCellCompositeView.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit


class LayoutCellFactory<CellBaseClass: LayoutCell> {
  public let viewBuilder: ViewBuilder
  public let cellClass: CellBaseClass.Type
  public var prototypeCell: CellBaseClass?
  
  init(viewBuilder: ViewBuilder, cellClass: CellBaseClass.Type) {
    self.viewBuilder = viewBuilder
    self.cellClass = cellClass
  }
}


/**
 * LayoutCellCompositeView
 */
protocol LayoutCellCompositeView {
  associatedtype CellBaseClass: LayoutCell
  typealias LayoutCellFactoryImpl = LayoutCellFactory<CellBaseClass>
  
  var cellFactories: [String: LayoutCellFactoryImpl] { get set }
  
  func registerCellLayout(cellIdentifier: String, cellClass: CellBaseClass.Type, layoutFile: String, parentViewBuilder: ViewBuilder)
  func registerCellLayout(cellIdentifier: String, cellClass: CellBaseClass.Type, viewBuilder: ViewBuilder)
}

extension LayoutCellCompositeView {
  func registerCellLayout(cellIdentifier: String, cellClass: CellBaseClass.Type = CellBaseClass.self, layoutFile: String, parentViewBuilder: ViewBuilder) {
    let parentUrl = parentViewBuilder.layoutFileURL
    let url = URL(fileURLWithPath: layoutFile, relativeTo: parentUrl)
    
    let viewBuilder = type(of: parentViewBuilder).init(layoutFileURL: url, refreshable: parentViewBuilder.refreshable, styler: parentViewBuilder.styler)
    viewBuilder.loadLayout { (layout, error) in
      if layout != nil {
        Logger("LayoutCellView").logTrace(message: "Preloaded cell layout '\(layoutFile)'")
      } else {
        Logger("LayoutCellView").logWarning(message: "Error preloading cell layout '\(layoutFile)' - \(String(describing: error))")
      }
    }
    
    registerCellLayout(cellIdentifier: cellIdentifier, cellClass: cellClass, viewBuilder: viewBuilder)
  }
  
  func configureLayoutCell<T>(_ cell: T, cellIdentifier identifier: String) -> T {
    if let cell = cell as? CellBaseClass, let viewBuilder = cellFactories[identifier]?.viewBuilder {
      cell.configureLayout(withViewBuilder: viewBuilder, didLoadCallback: nil)
      DispatchQueue.main.async {
        cell.layoutContainerView.styler.applyStyling(cell)
      }
    }
    return cell
  }
}


class LayoutTableViewCellFactory: LayoutCellFactory<LayoutTableViewCell> {}

/**
 * LayoutTableView
 */
open class LayoutTableView: UITableView, LayoutCellCompositeView {
  typealias CellBaseClass = LayoutTableViewCell

  var cellFactories: [String: LayoutCellFactoryImpl] = [:]

  public func registerCellLayout(cellIdentifier: String, cellClass: LayoutTableViewCell.Type = LayoutTableViewCell.self, viewBuilder: ViewBuilder) {
    register(cellClass, forCellReuseIdentifier: cellIdentifier)
    cellFactories[cellIdentifier] = LayoutTableViewCellFactory(viewBuilder: viewBuilder, cellClass: cellClass)
  }

  open override func dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
    let cell = super.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    return configureLayoutCell(cell, cellIdentifier: identifier)
  }

  // TODO:
  // open override func dequeueReusableHeaderFooterView(withIdentifier identifier: String) -> UITableViewHeaderFooterView?
}


class LayoutCollectionViewCellFactory: LayoutCellFactory<LayoutCollectionViewCell> {}

/**
 * LayoutCollectionView
 */
open class LayoutCollectionView: UICollectionView, LayoutCellCompositeView {
  typealias CellBaseClass = LayoutCollectionViewCell
  
  var cellFactories: [String: LayoutCellFactoryImpl] = [:]
  
  public func registerCellLayout(cellIdentifier: String, cellClass: LayoutCollectionViewCell.Type = LayoutCollectionViewCell.self, viewBuilder: ViewBuilder) {
    register(cellClass, forCellWithReuseIdentifier: cellIdentifier)
    cellFactories[cellIdentifier] = LayoutCollectionViewCellFactory(viewBuilder: viewBuilder, cellClass: cellClass)
  }
  
  open override func dequeueReusableCell(withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionViewCell {
    let cell = super.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    return configureLayoutCell(cell, cellIdentifier: identifier)
  }
  
  // TODO:
  // open override func dequeueReusableSupplementaryView(ofKind elementKind: String, withReuseIdentifier identifier: String, for indexPath: IndexPath) -> UICollectionReusableView
}
