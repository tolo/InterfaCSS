//
//  ElementStyle.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import ObjectiveC
import UIKit


// TODO: Define notification names elsewhere?
let MarkCachedStylingInformationAsDirtyNotification = NSNotification.Name("InterfaCSS.MarkCachedStylingInformationAsDirtyNotification")

/**
 *
 */
public protocol Stylable: AnyObject {
  var interfaCSS: ElementStyle { get set }
}

private var interfaCSSStoredPropertyKey: UInt8 = 0

public extension Stylable {
  
  var interfaCSS: ElementStyle {
    get {
      return objc_getAssociatedObject(self, &interfaCSSStoredPropertyKey) as? ElementStyle ?? {
        let stylingProxy = ElementStyle(uiElement: self)
        self.interfaCSS = stylingProxy
        return stylingProxy
        }()
    }
    set {
      objc_setAssociatedObject(self, &interfaCSSStoredPropertyKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
  }
}

extension UIResponder: Stylable {}
extension UIBarItem: Stylable {}
extension CALayer: Stylable {}


/**
 * A companion class to UI elements, containing information related to styling.
 */
public class ElementStyle: NSObject {
  private(set) weak var uiElement: AnyObject?
  public weak var view: UIView? { return uiElement as? UIView } // uiElement, if instance of UIView, otherwise nil
  private(set) weak var parentView: UIView? // parentElement, if instance of UIView, otherwise nil
  
  private weak var _parentElement: AnyObject?
  public weak var parentElement: AnyObject? {
    if _parentElement == nil {
      if let view = self.view {
        parentView = view.superview // Update cached parentView reference
        _closestViewController = view.closestViewController
        if let closestViewController = _closestViewController, closestViewController.view == view {
          _parentElement = closestViewController
        } else {
          _parentElement = parentView // In case parent element is view - _parentElement is the same as _parentView
        }
      } else if let viewController = uiElement as? UIViewController {
        _parentElement = viewController.view.superview // Use the super view of the view controller root view
      }
      if _parentElement != nil {
        isDirty = true
      }
    }
    return _parentElement
  }
  public var parentElementStyle: ElementStyle? {
    guard let parent = parentElement as? Stylable else { return nil }
    return parent.interfaCSS
  }
  
  private weak var _ownerElement: AnyObject?
  public weak var ownerElement: AnyObject? { // Element holding a property reference (which is defined validNestedElements) to this element, otherwise parentElement
    get {
      return _ownerElement ?? parentElement
    }
    set {
      _ownerElement = newValue
    }
  }
  public var ownerElementStyle: ElementStyle? {
    guard let owner = ownerElement as? Stylable else { return nil }
    return owner.interfaCSS
  }
  
  public weak var parentViewController: UIViewController? { // Direct parent view controller of element, i.e. parentElement, if instance of UIViewController, otherwise nil
    return parentElement as? UIViewController
  }
  
  private weak var _closestViewController: UIViewController?
  public weak var closestViewController: UIViewController? { // Closest ancestor view controller
    if _closestViewController == nil {
      _closestViewController = view?.closestViewController
    }
    return _closestViewController
  }
  
//  private(set) var validNestedElements: [String : String]?
  
  public var elementId: String? {
    didSet {
      isDirty = true
    }
  }
  
  private (set) var canonicalType: AnyClass?
  
  public var styleClasses: Set<String>? {
    didSet {
      isDirty = true
    }
  }
  
  /** Convenience property for cases when only a single style class is required (if more than one style class is set, this property may return any of them) */
  public var styleClass: String? {
    get {
      return styleClasses?.first
    }
    set {
      styleClasses = newValue != nil ? Set([newValue!]) : nil
    }
  }
  
  public var inlineStyle: [PropertyValue]?
  public var styleSheetScope: StyleSheetScope?
  public var nestedElementKeyPath: String? /* The key path / property name by which this element is know as in the ownerElement */
  
  private var elementStyleIdentity: String
  private(set) var elementStyleIdentityPath: String
  private(set) var ancestorHasElementId = false
  private(set) var ancestorUsesCustomElementStyleIdentity = false
  
  public var customElementStyleIdentity: String? {
    didSet {
      isDirty = true
    }
  }
  
  // TODO: Remove?
  //@property (nonatomic, weak, nullable) NSArray<Ruleset*>* cachedRulesets; // Optimization for quick access to cached declarations
  
  public var stylesFullyResolved = false
  /** Indicates if styles have been applied to element  */
  public var stylingApplied = false // TODO: Maybe we don't need this in core...
  /** Indicates that applied styling contains no pseudo classes for instance */
  public var stylingStatic = false
  
  public var addedToViewHierarchy: Bool {
    return parentView?.window != nil || (parentView is UIWindow) || (view is UIWindow)
  }
  
  public var stylesCacheable: Bool {
    return (elementId != nil) || ancestorHasElementId || (customElementStyleIdentity != nil) || ancestorUsesCustomElementStyleIdentity || addedToViewHierarchy
  }
  
  internal var isDirty = false
  
  internal var isApplyingStyle: Bool = false
  
  var appliedStyle: [PropertyValue]?
//  var inheritedStyle: Set<PropertyValue> {
//    var styles = [PropertyValue]()
//    parentElementStyle?.inheritedStyle.in
//    return
//  }
  
  public override var description: String {
    return elementStyleIdentity
  }
  
  
  // MARK: - Lifecycle
  
  public init(uiElement: AnyObject) {
    self.uiElement = uiElement
    elementStyleIdentity = String(describing: type(of: uiElement))
    elementStyleIdentityPath = elementStyleIdentity
    
    super.init()
    //    visitorScope = nil
    isDirty = true // Make as dirty to start with to make sure object is properly configured later (resetWith:)
    _ = parentElement // Make sure weak reference to super view is set directly
    
    NotificationCenter.default.addObserver(self, selector: #selector(ElementStyle.markCachedStylingInformationAsDirty), name: MarkCachedStylingInformationAsDirtyNotification, object: nil)
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self, name: MarkCachedStylingInformationAsDirtyNotification, object: nil)
  }
  
  public func reset(with styler: Styler) {
    guard let element = uiElement else { return }
    let elementClass: AnyClass = type(of: element)
    canonicalType = styler.propertyManager.canonicalTypeClass(for: elementClass) ?? elementClass
//    validNestedElements = nil
    // Identity and structure:
    elementStyleIdentity = createElementStyleIdentity()
    updateElementStyleIdentityPathIfNeeded(forceRevalidate: true) // Will result in re-evaluation of elementStyleIdentityPath, ancestorHasElementId and ancestorUsesCustomElementStyleIdentity in method below:
    _closestViewController = nil
    // Reset fields related to style caching
    stylingApplied = false
    stylesFullyResolved = false
    stylingStatic = false
    //    self.cachedRulesets = nil; // Note: this just clears a weak ref - cache will still remain in class InterfaCSS (unless cleared at the same time)
    isDirty = false
  }
  
  
  // MARK: - Cache invalidation
  
  @discardableResult
  public func checkForUpdatedParentElement() -> Bool {
    var didChangeParent = false
    if view != nil && view?.superview != parentView {
      // Check for updated superview
      _parentElement = nil // Reset parent element to make sure it's re-evaluated
      isDirty = true
      didChangeParent = true
    }
    _ = parentElement // Update parent element, if needed...
    return didChangeParent
  }
  
  public class func markAllCachedStylingInformationAsDirty() {
    NotificationCenter.default.post(name: MarkCachedStylingInformationAsDirtyNotification, object: nil)
  }
  
  @objc func markCachedStylingInformationAsDirty() {
    isDirty = true
  }
  
  
  // MARK: - Style classes
  
  public func addStyleClass(_ styleClass: String) {
    styleClasses = styleClasses?.union([styleClass]) ?? [styleClass]
  }
  
  public func removeStyleClass(_ styleClass: String) {
    styleClasses?.remove(styleClass)
  }
  
  public func hasStyleClass(_ styleClass: String) -> Bool {
    return styleClasses?.contains(styleClass) ?? false
  }
  
  
  // MARK: - Styling
  
  public func style(with styler: Styler) { // TODO: Review name
    guard let element = uiElement as? Stylable else { return }
    styler.applyStyling(element)
  }
  
  public func style() {
    style(with: StylingManager.shared)
  }
  
  
//  // MARK: - Nested elements
//
//  func childElement(forKeyPath keyPath: String) -> Any? {
//    guard let element = uiElement as? NSObject, let validKeyPath = validNestedElements?[keyPath.lowercased()] else { return nil }
//    return element.value(forKeyPath: validKeyPath)
//  }
//
//  @discardableResult
//  func addValidNestedElementKeyPath(_ keyPath: String) -> Bool {
//    guard let element = uiElement else { return false }
//    let lcPath = keyPath.lowercased()
//    if let _ = validNestedElements?[lcPath] { return true }
//
//    guard let validKeyPathForClass = RuntimeIntrospectionUtils.validKeyPath(forCaseInsensitivePath: keyPath, in: type(of: element)) else { return false }
//    validNestedElements = validNestedElements ?? [:]
//    validNestedElements?[lcPath] = validKeyPathForClass
//    return true
//  }
}


// MARK: - Utils / Internals

private extension ElementStyle {
  func classNamesStyleIdentityFragment() -> String {
    if let styleClasses = styleClasses, styleClasses.count > 0 {
      return "[" + styleClasses.sorted().joined(separator: ",") + "]"
    } else {
      return ""
    }
  }
  
  func createElementStyleIdentity() -> String {
    if let customElementStyleIdentity = customElementStyleIdentity {
      elementStyleIdentityPath = "@\(customElementStyleIdentity)\(classNamesStyleIdentityFragment())" // Prefix custom style id with @
      return elementStyleIdentityPath
    } else if let elementId = elementId {
      elementStyleIdentityPath = "#\(elementId)\(classNamesStyleIdentityFragment())" // Prefix element id with #
      return elementStyleIdentityPath
    } else if let nestedElementKeyPath = nestedElementKeyPath {
      elementStyleIdentityPath = "$\(nestedElementKeyPath)" // Prefix nested elements with $
      return elementStyleIdentityPath
    } else if styleClasses != nil {
      var str = canonicalType != nil ? String(describing: canonicalType!) : ""
      str += classNamesStyleIdentityFragment()
      return str
    } else {
      return canonicalType != nil ? String(describing: canonicalType!) : ""
    }
  }
  
  @discardableResult
  func updateElementStyleIdentityPathIfNeeded(forceRevalidate: Bool = false) -> String {
    if !forceRevalidate && elementStyleIdentity != elementStyleIdentityPath { return elementStyleIdentityPath }
    
    if let parentElement = parentElementStyle {
      let parentStyleIdentityPath = parentElement.updateElementStyleIdentityPathIfNeeded()
      // Check if an ancestor has an element id (i.e. style identity path will contain #someParentElementId) - this information will be used to determine if styles can be cacheable or not
      ancestorHasElementId = parentStyleIdentityPath.hasPrefix("#") || parentStyleIdentityPath.rangeOf(" #") != nil
      ancestorUsesCustomElementStyleIdentity = parentStyleIdentityPath.hasPrefix("@") || parentStyleIdentityPath.rangeOf(" @") != nil
      // Concatenate parent elementStyleIdentityPath of parent with the elementStyleIdentity of this element, separated by a space:
      elementStyleIdentityPath = "\(parentStyleIdentityPath) \(elementStyleIdentity)"
    } else {
      ancestorHasElementId = false
      ancestorUsesCustomElementStyleIdentity = false
      elementStyleIdentityPath = elementStyleIdentity
    }
    return elementStyleIdentityPath
  }
}


// TODO: Move
public extension UIView {
  var closestViewController: UIViewController? {
    var currentView = self
    repeat {
      if let viewController = currentView.next as? UIViewController {
        return viewController
      }
      currentView = currentView.superview ?? self
    } while currentView != self
    return nil
  }
}

// TOOD: Remove (experiment)
//protocol ChildElementHost {
//  func childElements() -> [UIView]
//}
//
//extension UIView: ChildElementHost {
//  @objc func childElements() -> [UIView] {
//    return subviews
//  }
//}
//
//extension UIButton {
//  override func childElements() -> [UIView] {
//    guard let titleLabel = titleLabel else { return super.childElements() }
//    return subviews + [titleLabel]
//  }
//}
