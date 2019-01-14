
import UIKit

private class LayoutTableViewCellFactory {
  public let viewBuilder: ViewBuilder
  public let cellClass: LayoutTableViewCell.Type
  public var prototypeCell: LayoutTableViewCell?
    
  init(viewBuilder: ViewBuilder, cellClass: LayoutTableViewCell.Type) {
    self.viewBuilder = viewBuilder
    self.cellClass = cellClass
  }
}

public protocol LayoutTableViewDelegate: UITableViewDelegate {
  func didLoadPrototypeCellLayout(withIdentifier identifier: String, containerView: LayoutContainerView, view: UIView)
}

open class LayoutTableView: UITableView {

  private var cellFactories: [String: LayoutTableViewCellFactory] = [:]
  private var prototypesLoaded = false

  private var layoutTableViewDelegate: LayoutTableViewDelegate? { return delegate as? LayoutTableViewDelegate }

  public func registerCellLayout(cellIdentifier: String, cellClass: LayoutTableViewCell.Type = LayoutTableViewCell.self, layoutFile: String, parentViewBuilder: ViewBuilder) {
    let parentUrl = parentViewBuilder.layoutFileURL
    let url = URL(fileURLWithPath: layoutFile, relativeTo: parentUrl)

    let viewBuilder = type(of: parentViewBuilder).init(layoutFileURL: url, refreshable: parentViewBuilder.refreshable, styler: parentViewBuilder.styler)

    registerCellLayout(cellIdentifier: cellIdentifier, cellClass: cellClass, viewBuilder: viewBuilder)
  }

  public func registerCellLayout(cellIdentifier: String, cellClass: LayoutTableViewCell.Type = LayoutTableViewCell.self, viewBuilder: ViewBuilder) {
    register(cellClass, forCellReuseIdentifier: cellIdentifier)
    cellFactories[cellIdentifier] = LayoutTableViewCellFactory(viewBuilder: viewBuilder, cellClass: cellClass)
  }
  
  @discardableResult
  private func createPrototypeCell(withFactory cellFactory: LayoutTableViewCellFactory, identifier: String, didLoadCallback: LayoutViewDidLoadCallback? = nil) -> LayoutTableViewCell {
    let cell = cellFactory.cellClass.init(frame: CGRect(origin: .zero, size: CGSize(width: bounds.width, height: 44)))
    cell.configureLayout(withViewBuilder: cellFactory.viewBuilder) { [layoutTableViewDelegate] (container, view) in
      didLoadCallback?(container, view)
      layoutTableViewDelegate?.didLoadPrototypeCellLayout(withIdentifier: identifier, containerView: container, view: view)
    }
    cellFactory.prototypeCell = cell
    return cell
  }

  public func prototypeCell(withIdentifier identifier: String) -> UITableViewCell {
    guard let cellFactory = cellFactories[identifier] else {
        return UITableViewCell()
    }
    if let prototype = cellFactory.prototypeCell {
        return prototype
    }

    return createPrototypeCell(withFactory: cellFactory, identifier: identifier)
  }
  
  public func loadPrototypeCells(completion: @escaping () -> Void) {
    guard !prototypesLoaded else {
      completion()
      return
    }

    let dispatchGroup = DispatchGroup()
    
    for (identifier, factory) in cellFactories {
      dispatchGroup.enter()
      createPrototypeCell(withFactory: factory, identifier: identifier) { [weak self] _, _ in
        if self?.prototypesLoaded == false {
          dispatchGroup.leave()
        }
      }
    }
    
    dispatchGroup.notify(queue: .main) {
      self.prototypesLoaded = true
      completion()
    }
  }

  open override func dequeueReusableCell(withIdentifier identifier: String, for indexPath: IndexPath) -> UITableViewCell {
    let cell = super.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
    if let cell = cell as? LayoutTableViewCell, let viewBuilder = cellFactories[identifier]?.viewBuilder {
      cell.configureLayout(withViewBuilder: viewBuilder)
    }
    return cell
  }
}
