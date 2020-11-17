//
//  StylingManager.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation
import UIKit

public typealias ViewHierarchyVisitorBlock = (Any?, ElementStyle, UnsafeMutablePointer<ObjCBool>?) -> Any?

/**
 * The heart, core and essence of InterfaCSS. Handles loading of stylesheets and keeps track of all style information.
 */
public class StylingManager: Styler { // TODO: Does it need to be NSObject?
  
  /// Gets the shared StylingManager instance.
  public static let shared: StylingManager = { StylingManager() }()
  
  public var styleSheetScope: StyleSheetScope { return .all }
  public let propertyManager: PropertyManager
  public let styleSheetManager: StyleSheetManager
  
  /// Style identity path to array of cached rulesets
  private var cachedElementRulesets: [String: [Ruleset]] = [:]
  
  private let notificationObserverTokenBag = NotificationObserverTokenBag();
  
  // MARK: - Creation & destruction
  
  required init(propertyManager: PropertyManager? = nil, styleSheetManager: StyleSheetManager? = nil) {
    self.propertyManager = propertyManager ?? PropertyManager()
    self.styleSheetManager = styleSheetManager ?? StyleSheetManager()
    self.propertyManager.styleSheetManager = self.styleSheetManager
    self.styleSheetManager.propertyManager = self.propertyManager
    
    InterfaCSS.ShouldClearAllCachedStylingInformation.observe { [weak self] _ in
      self?.clearAllCachedStyles()
    }.disposedBy(notificationObserverTokenBag)
    
    UIApplication.didReceiveMemoryWarningNotification.observe { [weak self] _ in
      self?.clearAllCachedStyles()
    }.disposedBy(notificationObserverTokenBag)
  }
    
  deinit {
    notificationObserverTokenBag.removeObservers()
  }
    
  
  // MARK: - Styler
  
//  @discardableResult
//  public func loadStyleSheet(fromMainBundleFile styleSheetFileName: String) -> StyleSheet? {
//    return styleSheetManager.loadStyleSheet(fromMainBundleFile: styleSheetFileName)
//  }
//
//  @discardableResult
//  public func loadStyleSheet(fromLocalFile styleSheetFileURL: URL) -> StyleSheet? {
//    return styleSheetManager.loadStyleSheet(fromLocalFile: styleSheetFileURL)
//  }
//
//  @discardableResult
//  public func loadStyleSheet(fromRefreshableFile styleSheetFileURL: URL) -> StyleSheet? {
//    return styleSheetManager.loadStyleSheet(fromRefreshableFile: styleSheetFileURL)
//  }
  
  
  // MARK: - Styling - Style matching and application
  
  private func buildRulesets(for element: ElementStyle, styleSheetScope: StyleSheetScope, styler: Styler) -> [Ruleset] {
    trace(.styling, "FULL stylesheet scan for '\(element.elementStyleIdentityPath)'")
    
    element.stylingApplied = false // Reset 'stylingApplied' flag if declaration cache has been cleared, to make sure element is re-styled
    
    // Perform full stylesheet scan to get matching style classes, but ignore pseudo classes at this stage
    let stylingContext = StylingContext(styler: styler, styleSheetScope: styleSheetScope, ignorePseudoClasses: true)
    var rulesets = styleSheetManager.rulesets(matchingElement: element, context: stylingContext)
    
    if stylingContext.containsPartiallyMatchedDeclarations {
      trace(.styling, "Found \(rulesets.count) matching declarations, and at least one partially matching declaration, for '\(element.elementStyleIdentityPath)'.")
    } else {
      trace(.styling, "Found \(rulesets.count) matching declarations for '\(element.elementStyleIdentityPath)'.")
    }
    
    // ...sort declarations on specificity (ascending)
    rulesets = rulesets.sorted { ruleset1, ruleset2 in
      return ruleset1.specificity < ruleset2.specificity
    }
    
    // If there are no style declarations that only partially matches the element - consider the styles fully resolved for the element
    element.stylesFullyResolved = !stylingContext.containsPartiallyMatchedDeclarations
    // Only add declarations to cache if styles are cacheable for element (i.e. either added to window, or part of a view hierachy that has an root element with an element Id), or,
    // if there were no styles that would match if the element was placed under a different parent (i.e. partial matches)
    if stylingContext.stylesCacheable && (element.stylesCacheable || element.stylesFullyResolved) {
      cachedElementRulesets[element.elementStyleIdentityPath] = rulesets
    } else {
      trace(.styling, "Can NOT cache styles for '\(element.elementStyleIdentityPath)'")
    }
    
    return rulesets
  }
  
  private func effectiveStyles(for element: ElementStyle, force: Bool, styleSheetScope: StyleSheetScope, styler: Styler) -> [PropertyValue] {
    let cachedRulesets = force ? nil : cachedElementRulesets[element.elementStyleIdentityPath]
    let rulesets = cachedRulesets ?? buildRulesets(for: element, styleSheetScope: styleSheetScope, styler: styler)
    
    if !force && element.stylingApplied && element.stylingStatic {
      // Current styling information has already been applied, and declarations contain no pseudo classes
      trace(.styling, "Styles aleady applied for '\(element.elementStyleIdentityPath)'")
      return []
    } else {
      // Styling information has not been applied, or declarations contains pseudo classes (in which case we need to re-evaluate the styles every time styling is initiated), or is forced
      trace(.styling, "Processing style declarations for '\(element.elementStyleIdentityPath)'")
      
      // Process declarations to see which styles currently match
      var containsPseudoClassSelector = false
      let stylingContext = StylingContext(styler: styler, styleSheetScope: styleSheetScope)
      var viewStyles: [PropertyValue] = []
      for ruleset in rulesets {
        // Add styles if declarations doesn't contain pseudo selector, or if matching against pseudo class selector is successful
        if !ruleset.containsPseudoClassSelector || ruleset.matches(element, context: stylingContext) {
          viewStyles.addAndReplace(ruleset.properties)
        }
        containsPseudoClassSelector = containsPseudoClassSelector || ruleset.containsPseudoClassSelector
      }
      if let inlineStyles = element.inlineStyle, inlineStyles.count > 0 {
        viewStyles.addAndReplace(inlineStyles)
      }
      element.stylingStatic = !containsPseudoClassSelector // Record in element if declarations contain pseudo classes, and thus needs constant re-evaluation (i.e. not static)
      
      // Set 'stylingApplied' flag to indicate that styles have been fully applied, but only if element is part of a defined view
      // hierarchy (i.e. either added to window, or part of a view hierachy that has an root element with an element Id)
      if element.stylesCacheable || element.stylesFullyResolved {
        element.stylingApplied = true
      } else {
        trace(.styling, "Cannot mark element '\(element.elementStyleIdentityPath)' as styled")
      }
      return viewStyles
    }
  }
  
  private func style(element: ElementStyle, force: Bool, styleSheetScope: StyleSheetScope, styler: Styler) {
    var styles = effectiveStyles(for: element, force: force, styleSheetScope: styleSheetScope, styler: styler)
    guard styles.count > 0 else { return } // If 'styles' is empty, current styling information has already been applied
    
    styles = propertyManager.preProcess(propertyValues: styles, styleSheetScope: styleSheetScope)
    
    for propertyValue in styles {
      propertyManager.apply(propertyValue, onTarget: element, styleSheetScope: styleSheetScope)
    }
  }
  
  
  // MARK: - Styling - Elememt styling proxy
  
  public func style(for uiElement: Stylable) -> ElementStyle {
    return style(for: uiElement, resetIfNeeded: true)
  }
  
  func style(for uiElement: Stylable, resetIfNeeded: Bool = true) -> ElementStyle {
    let proxy = uiElement.interfaCSS
    if proxy.isDirty && resetIfNeeded {
      proxy.reset(with: self)
    }
    return proxy
  }
  
  // MARK: - Subscripting support (alias for stylingProxyFor:)
  public subscript(stylable: Stylable) -> ElementStyle {
    return style(for: stylable)
  }
  
  
  // MARK: - Styling - Caching
  
  private func reset(element: ElementStyle) {
    self.cachedElementRulesets[element.elementStyleIdentityPath] = nil
    element.reset(with: self)
  }
  
  public func clearCachedStylingInformation(for uiElement: Stylable, includeSubViews: Bool = true) {
    clearCachedStylingInformation(for: uiElement.interfaCSS, includeSubViews: includeSubViews)
  }
  
  public func clearCachedStylingInformation(for element: ElementStyle, includeSubViews: Bool = true) {
    if includeSubViews {
      visitViewHierarchy(from: element) { e in
        self.cachedElementRulesets[e.elementStyleIdentityPath] = nil
        e.markCachedStylingInformationAsDirty()
      }
    } else {
      self.cachedElementRulesets[element.elementStyleIdentityPath] = nil
      element.markCachedStylingInformationAsDirty()
    }
  }
  
  /// Clears all cached style information, but does not initiate re-styling.
  public func clearAllCachedStyles() {
    if cachedElementRulesets.count > 0 {
      debug(.styling, "Clearing all cached styles")
      cachedElementRulesets.removeAll()
      ElementStyle.markAllCachedStylingInformationAsDirty()
    }
  }
  
  
  // MARK: - Styling
  
  /// From protocol Styler
  public func applyStyling(_ stylable: Stylable, includeSubViews: Bool = true, force: Bool = false) {
    applyStyling(stylable.interfaCSS, includeSubViews: includeSubViews, force: force, styleSheetScope: nil, styler: nil)
  }
  
  /// Applies styling of the specified UI object and optionally also all its children.
  public func applyStyling(_ stylable: Stylable, includeSubViews: Bool = true, force: Bool = false, styleSheetScope: StyleSheetScope? = nil) {
    applyStyling(stylable.interfaCSS, includeSubViews: includeSubViews, force: force, styleSheetScope: styleSheetScope, styler: nil)
  }
  
  // Main styling method (stylable element version)
  /// Applies styling of the specified UI object and optionally also all its children.
  public func applyStyling(_ element: ElementStyle, includeSubViews: Bool = true, force: Bool = false, styleSheetScope: StyleSheetScope? = nil) {
    applyStyling(element, includeSubViews: includeSubViews, force: force, styleSheetScope: styleSheetScope, styler: nil)
  }
  
  internal func applyStyling(_ element: ElementStyle, includeSubViews: Bool = true, force: Bool = false, styleSheetScope: StyleSheetScope? = nil, styler: Styler? = nil) {
    guard let uiElement = element.uiElement else { return }
    // Prevent loops during styling
    guard !element.isApplyingStyle else {
      info(.styling, "Warning: already styling '\(uiElement)' - aborting.")
      return
    }
    element.isApplyingStyle = true
    defer { element.isApplyingStyle = false }
    
    applyStylingInternal(element, includeSubViews: includeSubViews, force: force, styleSheetScope: styleSheetScope ?? self.styleSheetScope, styler: styler ?? self)
  }
  
  // Internal styling method ("inner") - should only be called by applyStyling above
  private func applyStylingInternal(_ element: ElementStyle, includeSubViews: Bool, force: Bool, styleSheetScope: StyleSheetScope, styler: Styler) {
    guard let uiElement = element.uiElement else { return }
    trace(.styling, "Applying style to '\(uiElement)'")
// TODO: Review if this is something we want
//    let styleSheetScope = element.styleSheetScope ?? styleSheetScope // Use styleSheetScope on element first, if set
//    if styleSheetScope != StyleSheetScope.defaultGroupScope {
//      element.styleSheetScope = styleSheetScope
//    }
    
    element.checkForUpdatedParentElement() // Reset cached styles if parent/superview has changed...
    
    let dirty = element.isDirty
    if dirty {
      trace(.styling, "Cached styling information for element of '\(element)' dirty - resetting cached styling information")
      reset(element: element)
      
      // If not including subviews, make sure child elements are marked dirty
      if !includeSubViews {
        childElements(for: element, resetIfNeeded: false).forEach { $0.isDirty = true }
      }
    }
    
    style(element: element, force: force, styleSheetScope: styleSheetScope, styler: styler)
    
    if includeSubViews {
      // Process subviews
      for child in childElements(for: element, resetIfNeeded: false) { // Don't reset element here, wait until element itself is styled (i.e. applyStyling below)
        if dirty {
          child.isDirty = true
        }
        applyStyling(child, includeSubViews: true, force: force, styleSheetScope: styleSheetScope)
      }
    }
    
    // Invoke potential implementation of StylingAware after sub view styling has been applied (to let StylingAware override if needed)
    if let stylingAware = element.uiElement as? StylingAware {
      stylingAware.didApplyStyling(withStyler: styler)
    }
  }
  
  public func styler(withScope styleSheetScope: StyleSheetScope) -> DelegatingStyler {
    DelegatingStyler(stylingManager: self, styleSheetScope: styleSheetScope)
  }
  
  
  // MARK: - View hierarchy traversing
  
  public func visitViewHierarchy(from element: ElementStyle, visitor: (ElementStyle) -> Void) {
    var visited = Set<ElementStyle>()
    visitViewHierarchyInternal(from: element, visitor: visitor, visited: &visited)
  }
  
  private func visitViewHierarchyInternal(from element: ElementStyle, visitor: (ElementStyle) -> Void, visited: inout Set<ElementStyle>) {
    guard !visited.contains(element) else { return }
    visitor(element)
    visited.insert(element)
    childElements(for: element).forEach { visitViewHierarchyInternal(from: $0, visitor: visitor, visited: &visited) }
  }
  
  private func childElements(for element: ElementStyle, resetIfNeeded: Bool = true) -> [ElementStyle] {
    guard let _ = element.uiElement else { return [] }
    let childElements = NSMutableOrderedSet()
    
    if let view = element.view {
      childElements.addObjects(from: view.subviews)
      childElements.add(view.layer)
    }
    
    #if os(iOS)
    // Special case: UIToolbar - add toolbar items to "subview" list
    if let toolbar = element.view as? UIToolbar, let items = toolbar.items {
      childElements.addObjects(from: items)
    }
    #endif
    // Special case: UINavigationBar - add nav bar items to "subview" list
    if let navigationBar = element.view as? UINavigationBar, let navItems = navigationBar.items {
      var additionalSubViews: [Any] = []
      for navItem in navItems {
        #if os(iOS)
        if let backItem = navItem.backBarButtonItem {
          additionalSubViews.append(backItem)
        }
        #endif
        if let leftItems = navItem.leftBarButtonItems {
          additionalSubViews.append(contentsOf: leftItems)
        }
        if let titleView = navItem.titleView {
          additionalSubViews.append(titleView)
        }
        if let rightItems = navItem.rightBarButtonItems {
          additionalSubViews.append(contentsOf: rightItems)
        }
      }
      childElements.addObjects(from: additionalSubViews)
    }
    // Special case: UITabBar - add tab bar items to "subview" list
    else if let tabBar = element.view as? UITabBar, let items = tabBar.items {
      childElements.addObjects(from: items)
    }
    else if let cell = element.view as? UITableViewCell {
      if let view = cell.backgroundView { childElements.add(view) }
      if let view = cell.selectedBackgroundView { childElements.add(view) }
    }
    else if let cell = element.view as? UITableViewHeaderFooterView {
      if let view = cell.backgroundView { childElements.add(view) }
    }
    else if let cell = element.view as? UICollectionViewCell {
      if let view = cell.backgroundView { childElements.add(view) }
      if let view = cell.selectedBackgroundView { childElements.add(view) }
    }
    
    // TODO: Add more special cases (as replacement for removed element.validNestedElements...)?
    
    return childElements.compactMap { $0 as? Stylable }.map {
      let childStyle = self.style(for: $0, resetIfNeeded: resetIfNeeded)
      if childStyle.parentElement == nil { // If element doesn't have a parent view (i.e. super view)...
        childStyle.ownerElement = element.uiElement // ... assign an owner instead
      }
      return childStyle
    }
  }
  
  
  // MARK: - Debugging support
  
  /**
   * Logs the active rulesets for the specified UI element.
   */
  public func logMatchingRulesets(for uiElement: Stylable, styleSheetScope: StyleSheetScope) {
    let context = StylingContext(styler: self, styleSheetScope: styleSheetScope)
    styleSheetManager.logMatchingRulesets(forElement: uiElement.interfaCSS, context: context)
  }
}
