//
//  LayoutTableViewController.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit

open class LayoutTableViewController: LayoutViewController, UITableViewDataSource, LayoutTableViewDelegate {
  private var logger = Logger("LayoutTableViewController")

  @objc public var tableView: LayoutTableView!
  private var tableViewInitialized = false
  private var tableViewReloadQueued = false

  public var shouldCacheRowHeights: Bool = true
  private var contentViewWidthForCellTypeCache: [String: CGFloat] = [:]
  private var rowHeightCache: [String: CGFloat] = [:]

  private func cellTypeIdentifier(forCell cell: LayoutTableViewCell, indexPath: IndexPath) -> String {
    return "\(cellReuseIdentifier(forIndexPath: indexPath))-\(cell.accessoryType.rawValue)"
  }


  // MARK: - LayoutTableViewDelegate

  public func didLoadPrototypeCellLayout(withIdentifier identifier: String, containerView: LayoutContainerView, view: UIView) {
    if tableViewInitialized { // Handle hot reload
      clearCachedRowHeights()
      tableView.reloadData()
    }
  }

  
  // MARK: - LayoutViewController main API
  
  open func cellReuseIdentifier(forIndexPath indexPath: IndexPath) -> String {
    return ""
  }
    
  private func uniqueCellIdentifier(forIndexPath indexPath: IndexPath, andCellIdentifier cellId: String) -> String {
    return uniqueCellModelIdentifier(forIndexPath: indexPath) ?? "\(cellId)-\(indexPath)"
  }
  
  open func uniqueCellModelIdentifier(forIndexPath indexPath: IndexPath) -> String? {
    return nil
  }
  
  open func populate(cell: LayoutTableViewCell, atIndexPath indexPath: IndexPath) {}
  
  public final func clearCachedRowHeights() {
    rowHeightCache.removeAll()
  }
  
  
  // MARK: - LayoutViewController
  
  override open func layout(view: UIView, didLoadIn containerView: LayoutContainerView) {
    super.layout(view: view, didLoadIn: containerView)
    tableView.dataSource = nil
    tableView.rowHeight = UITableView.automaticDimension
    tableView.loadPrototypeCells() {
      self.logger.logDebug(message: "Cell prototypes loeaded")
      self.tableViewInitialized = true
      self.clearCachedRowHeights()
      self.tableView.dataSource = self
      self.tableView.reloadData()
    }
  }
  
  
  // MARK: - UITableViewDataSource / UITableViewDelegate
  
  open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 0
  }
  
  open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard let prototypeCell = self.tableView.prototypeCell(withIdentifier: cellReuseIdentifier(forIndexPath: indexPath)) as? LayoutTableViewCell else {
      return 44
    }

    let cellTypeId = cellTypeIdentifier(forCell: prototypeCell, indexPath: indexPath)
    let uniqueCellId = uniqueCellIdentifier(forIndexPath: indexPath, andCellIdentifier: cellTypeId)
    if let cachedHeight = rowHeightCache[uniqueCellId] {
        return cachedHeight
    }

    prototypeCell.prepareForReuse()
    populate(cell: prototypeCell, atIndexPath: indexPath)

    let contentWidth = contentViewWidthForCellTypeCache[cellTypeId] ?? tableView.bounds.width
    let height = prototypeCell.calculateContentHeightThatFits(CGSize(width: contentWidth, height: .greatestFiniteMagnitude))
    if shouldCacheRowHeights {
      rowHeightCache[uniqueCellId] = height
    }
    logger.logTrace(message: "heightForRowAt \(indexPath): \(height) - content view width for cell type ('\(cellTypeId)'): \(contentWidth)")
    return height
  }
  
  open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cellId = cellReuseIdentifier(forIndexPath: indexPath)
    let tableViewCell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath)
    guard let cell = tableViewCell as? LayoutTableViewCell else {
      return tableViewCell
    }
    populate(cell: cell, atIndexPath: indexPath)
    cell.updateLayout()
    return cell
  }
  
  open func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    guard let cell = cell as? LayoutTableViewCell, tableView.rowHeight == UITableView.automaticDimension else {
      return
    }

    let cellTypeId = cellTypeIdentifier(forCell: cell, indexPath: indexPath)
    let contentViewWidth  = cell.contentView.frame.width
    let lastContentViewWidth = contentViewWidthForCellTypeCache[cellTypeId] ?? tableView.bounds.width

    if lastContentViewWidth != contentViewWidth {
      logger.logTrace(message: "Content view width changed for cell type '\(cellTypeId)': \(contentViewWidth) - last: \(lastContentViewWidth)")
      contentViewWidthForCellTypeCache[cellTypeId] = cell.contentView.frame.width

      clearCachedRowHeights()
      if tableViewInitialized {
        DispatchQueue.main.async {
          tableView.reloadRows(at: [indexPath], with: .none)
        }
      }
    }
  }
}
