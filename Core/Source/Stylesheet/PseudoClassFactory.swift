//
//  PseudoClassFactory.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit

public protocol PseudoClassFactoryType {
  func createPseudoClass(ofType type: String, parameters: Any?) -> PseudoClass?
}

public extension PseudoClassFactoryType {
  
  // MARK - Convenience creation methods
  
  func createStructuralPseudoClass(ofType type: String, a: Int, b: Int) -> PseudoClass? {
    return createPseudoClass(ofType: type, parameters: (a, b))
  }
  
  func createPseudoClass(ofType type: String, withParameter parameter: String) -> PseudoClass? {
    return createPseudoClass(ofType: type, parameters: parameter)
  }
  
  func createSimplePseudoClass(ofType type: String) -> PseudoClass? {
    return createPseudoClass(ofType: type, parameters: nil)
  }
}


// TODO:
//public struct PseudoClassType: Hashable, Equatable, RawRepresentable {
//  public let rawValue: String
//  public init(rawValue: String) {
//    self.rawValue = rawValue
//  }
//  public init(_ rawValue: String) {
//    self.rawValue = rawValue
//  }
//}

open class PseudoClassFactory: PseudoClassFactoryType {
  
  private (set) var pseudoMatchers: [String: PseudoClassMatcherBuilder]
  
  init() {
    self.pseudoMatchers = [
      "root": .simple { (e, _) in e.parentViewController != nil },
      "nthchild": .structural { (a, b, e, _) in matchesIndex(a, b, e, false) },
      "nthlastchild": .structural { (a, b, e, _) in matchesIndex(a, b, e, true) },
      "onlychild": .simple { (e, _) in e.parentView?.subviews.count == 1 },
      "firstchild": .simple { (e, _) in matchesIndex(0, 1, e, false) },
      "lastchild": .simple { (e, _) in matchesIndex(0, 1, e, true) },
      "nthoftype": .structural { (a, b, e, c) in matchesTypeQualifiedIndex(a, b, e, c, false) },
      "nthlastoftype": .structural { (a, b, e, c) in matchesTypeQualifiedIndex(a, b, e, c, true) },
      "onlyoftype": .structural { (a, b, e, c) in onlyOfType(a, b, e, c) },
      "firstoftype": .simple { (e, c) in matchesTypeQualifiedIndex(0, 1, e, c, false) },
      "lastoftype": .simple { (e, c) in matchesTypeQualifiedIndex(0, 1, e, c, true) },
      "empty": .structural { (_, _, e, _) in e.view?.subviews.count == 0 },
      
      "pad": .simple { (_,_) in UI_USER_INTERFACE_IDIOM() == .pad },
      "tablet": .simple { (_,_) in UI_USER_INTERFACE_IDIOM() == .pad },
      "phone": .simple { (_,_) in UI_USER_INTERFACE_IDIOM() == .phone },
      "tv": .simple { (_,_) in UI_USER_INTERFACE_IDIOM() == .tv },
      
      "landscape": .simple { (e, _) in checkOrientation(e, isLandscape: true) },
      "portrait": .simple { (e, _) in checkOrientation(e, isLandscape: false) },
      
      "minosversion": .singleParameter { (p, e, _) in UIDevice.versionGreaterOrEqual(to: p) },
      "maxosversion": .singleParameter { (p, e, _) in UIDevice.versionLessOrEqual(to: p) },
      
      "screenwidth": .singleParameter { (p, e, _) in screenWidth.isEqualToWithScreenPrecision(Double(p) ?? 0) },
      "screenwidthlessthan": .singleParameter { (p, e, _) in screenWidth < (Double(p) ?? 0) },
      "screenwidthgreaterthan": .singleParameter { (p, e, _) in screenWidth > (Double(p) ?? .greatestFiniteMagnitude) },
      
      "screenheight": .singleParameter { (p, e, _) in screenHeight.isEqualToWithScreenPrecision(Double(p) ?? 0) },
      "screenheightlessthan": .singleParameter { (p, e, _) in screenHeight < (Double(p) ?? 0) },
      "screenheightgreaterthan": .singleParameter { (p, e, _) in screenHeight > (Double(p) ?? .greatestFiniteMagnitude) },
      
      
      "regularwidth": .simple { (e, _) in traitCollection(for: e.uiElement)?.horizontalSizeClass == .regular },
      "compactwidth": .simple { (e, _) in traitCollection(for: e.uiElement)?.horizontalSizeClass == .compact },
      "regularheight": .simple { (e, _) in traitCollection(for: e.uiElement)?.verticalSizeClass == .regular },
      "compactheight": .simple { (e, _) in traitCollection(for: e.uiElement)?.verticalSizeClass == .compact },
      
      "enabled": .simple { (e, _) in return (e.uiElement as? UIElementState)?.isEnabled ?? true },
      "disabled": .simple { (e, _) in return !((e.uiElement as? UIElementState)?.isEnabled ?? true) },
      "selected": .simple { (e, _) in return (e.uiElement as? UIElementState)?.isSelected ?? false },
      "highlighted": .simple { (e, _) in return (e.uiElement as? UIElementState)?.isHighlighted ?? false }
    ]
    
  }
  
  public func registerPseudoClassMatcher(_ pseudoClassMatcherBuilder: PseudoClassMatcherBuilder, for name: String) {
    pseudoMatchers[name.lowercased()] = pseudoClassMatcherBuilder
  }
  
  open func createPseudoClass(ofType type: String, parameters: Any?) -> PseudoClass? {
    let typeCleaned = type.lowercased().replacingOccurrences(of: "-", with: "")
    guard let matcherBuilder = pseudoMatchers[typeCleaned] else {
      logError(.stylesheets, "Invalid pseudo class: '\(type)'")
      return nil
    }
    
    guard let matcher = matcherBuilder.matcher(withParameters: parameters) else {
      logError(.stylesheets, "Invalid pseudo class: '\(type)'")
      return nil
    }
    
    return PseudoClass(type: typeCleaned, matcher: matcher)
  }
}


// MARK: - Internal pseudo class matching helpers

private protocol UIElementState {
  var isEnabled: Bool { get }
  var isHighlighted: Bool { get }
  var isSelected: Bool { get }
}
extension UIElementState {
  var isEnabled: Bool { return false }
  var isHighlighted: Bool { return false }
  var isSelected: Bool { return false }
}
extension UIControl: UIElementState {}
extension UIBarButtonItem: UIElementState {}
extension UIImageView: UIElementState {}
extension UILabel: UIElementState {}
extension UITextView: UIElementState {}

private func traitCollection(for element: AnyObject?) -> UITraitCollection? {
  if let uiElement = element as? UITraitEnvironment {
    return uiElement.traitCollection
  }
  return nil
}

private var screenWidth: Double { return Double(UIScreen.main.nativeBounds.width / UIScreen.main.nativeScale) }
private var screenHeight: Double { return Double(UIScreen.main.nativeBounds.height / UIScreen.main.nativeScale) }

private func checkOrientation(_ element: ElementStyle, isLandscape: Bool) -> Bool {
  if let bounds = element.view?.bounds {
    if isLandscape { return bounds.width > bounds.height }
    else { return bounds.width < bounds.height }
  } else {
    return false
  }
}

private func onlyOfType(_ a: Int, _ b: Int, _ element: ElementStyle, _ context: StylingContext) -> Bool {
  var position: Int = NSNotFound, count: Int = 0
  PseudoClassFactory.typeQualifiedPositionInParent(forElement: element, position: &position, count: &count, propertyManager: context.styler.propertyManager)
  return position == 0 && count == 1
}

private func matchesTypeQualifiedIndex(_ a: Int, _ b: Int, _ element: ElementStyle, _ context: StylingContext, _ reverse: Bool) -> Bool {
  var position: Int = NSNotFound, count: Int = 0
  PseudoClassFactory.typeQualifiedPositionInParent(forElement: element, position: &position, count: &count, propertyManager: context.styler.propertyManager)
  return matchesIndex(a, b, position, count, reverse) //(pseudoClassType == issPseudoClassTypeNthLastOfType || pseudoClassType == issPseudoClassTypeLastOfType))
}

private func matchesIndex(_ a: Int, _ b: Int, _ element: ElementStyle, _ reverse: Bool) -> Bool {
  if let parentView = element.parentView, let uiElement = element.uiElement as? UIView, let indexInParent = parentView.subviews.firstIndex(of: uiElement) {
    return matchesIndex(a, b, indexInParent, parentView.subviews.count, reverse)
  } else {
    return false
  }
}

private func matchesIndex(_ a: Int, _ b: Int, _ indexInParent: Int, _ n: Int, _ reverse: Bool) -> Bool {
  if indexInParent != NSNotFound {
    for i in 1...n {
      var index: Int = (i - 1) * a + b - 1
      if reverse {
        index = n - 1 - index
      }
      if index == indexInParent {
        return true
      }
    }
  }
  return false
}


private extension PseudoClassFactory {
  static func typeQualifiedPositionInParent(forElement element: ElementStyle, position: inout Int, count: inout Int, propertyManager: PropertyManager) {
    position = NSNotFound
    count = 0
    guard let uiElement = element.uiElement else { return }
    
    if let cell = uiElement as? UITableViewCell, let tv: UITableView = findParent(element.parentView) {
      var indexPath = tv.indexPath(for: cell)
      if indexPath == nil {
        indexPath = tv.indexPathForRow(at: cell.center)
      }
      if let indexPath = indexPath {
        position = indexPath.row
        count = tv.numberOfRows(inSection: indexPath.section)
      }
    }
    else if let cell = uiElement as? UICollectionViewCell, let cv: UICollectionView = findParent(element.parentView) {
      var indexPath = cv.indexPath(for: cell)
      if indexPath == nil {
        indexPath = cv.indexPathForItem(at: cell.center)
      }
      if let indexPath = indexPath {
        position = indexPath.item
        count = cv.numberOfItems(inSection: indexPath.section)
      }
    }
    else if let reusableView = uiElement as? UICollectionReusableView, let cv: UICollectionView = findParent(element.parentView) {
      if let indexPath = cv.indexPathForItem(at: reusableView.center) {
        position = indexPath.item
        count = cv.numberOfItems(inSection: indexPath.section)
      }
    }
    else if let barButton = uiElement as? UIBarButtonItem, let navBar = element.parentView as? UINavigationBar {
      var items: [NSObject] = []
      if let left = navBar.topItem?.leftBarButtonItems { items.append(contentsOf: left) }
      if let title = navBar.topItem?.titleView { items.append(title) }
      if let right = navBar.topItem?.rightBarButtonItems { items.append(contentsOf: right) }
      position = items.firstIndex(of: barButton) ?? NSNotFound
      count = items.count
    }
    else if let barButton = uiElement as? UIBarButtonItem, let toolbar = element.parentView as? UIToolbar, let items = toolbar.items {
      position = items.firstIndex(of: barButton) ?? NSNotFound
      count = items.count
    }
    else if let barItem = uiElement as? UITabBarItem, let tabbar = element.parentView as? UITabBar, let items = tabbar.items {
      position = items.firstIndex(of: barItem) ?? NSNotFound
      count = items.count
    }
    else if let parentView = element.parentView {
      guard let uiKitClass = propertyManager.canonicalTypeClass(for: type(of: uiElement)) else { return }
      
      for v in parentView.subviews {
        if isObject(v, instanceOf: uiKitClass) {
          if v === uiElement {
            position = count
          }
          count = count + 1
        }
      }
    }
  }
  
  static func isObject(_ obj: AnyObject, instanceOf clazz: Any.Type) -> Bool {
    var currentMirror: Mirror?  = Mirror(reflecting: obj)
    while let mirror = currentMirror {
      if mirror.subjectType == clazz {
        return true
      }
      currentMirror = mirror.superclassMirror
    }
    return false
  }
  
  static func findParent<T>(_ parentView: UIView?) -> T? {
    guard let parentView = parentView else { return nil }
    if let parentView = parentView as? T {
      return parentView
    } else {
      if let superview = parentView.superview {
        return findParent(superview)
      }
      return nil
    }
  }
}
