//
//  StyleSheetManager.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


public class StyleSheetManager: NSObject {
  
  /// Dependenies
  weak var propertyManager: PropertyManager!
  
  private let styleSheetRepository = StyleSheetRepository()
  private let variableRepository = VariableRepository();
  
  let styleSheetParser: StyleSheetParser
  let pseudoClassFactory: PseudoClassFactoryType
  
  /**
   * All currently active stylesheets (`StyleSheet`).
   */
  public var styleSheets: [StyleSheet] { styleSheetRepository.styleSheets }
  
  var activeStylesheets: [StyleSheet] { styleSheetRepository.activeStylesheets }
  
  /**
   * The interval at which refreshable stylesheets are refreshed. Default is 5 seconds. If value is set to <= 0, automatic refresh is disabled. Note: this is only use for stylesheets loaded from a remote URL.
   */
  public var stylesheetAutoRefreshInterval: TimeInterval {
    get { styleSheetRepository.stylesheetAutoRefreshInterval }
    set { styleSheetRepository.stylesheetAutoRefreshInterval = newValue }
  }
  
  
  /**
   * Gets the shared StyleSheetManager instance (via the shared ISSStylingManager).
   */
  public static var shared: StyleSheetManager {
    return StylingManager.shared.styleSheetManager
  }
  
  required init(styleSheetParser parser: StyleSheetParser? = nil, pseudoClassFactory: PseudoClassFactoryType? = nil) {
    self.styleSheetParser = parser ?? StyleSheetParser()
    self.pseudoClassFactory = pseudoClassFactory ?? PseudoClassFactory()
    
    super.init()
    
    styleSheetParser.styleSheetManager = self
    styleSheetRepository.styleSheetManager = self
    variableRepository.styleSheetManager = self
  }
  
  
  // MARK: - Stylesheets loading
  
  /**
   * Loads a stylesheet from the main bundle.
   */
  @discardableResult
  public func loadStyleSheet(fromMainBundleFile styleSheetFileName: String) -> StyleSheet? {
    return loadNamedStyleSheet(nil, group: StyleSheetGroupDefault, fromMainBundleFile: styleSheetFileName)
  }

  @discardableResult
  public func loadNamedStyleSheet(_ name: String?, group groupName: String, fromMainBundleFile styleSheetFileName: String) -> StyleSheet? {
    return styleSheetRepository.loadNamedStyleSheet(name, group: groupName, fromMainBundleFile: styleSheetFileName)
  }

  /**
   * Loads a stylesheet from an absolute file path.
   */
  @discardableResult
  public func loadStyleSheet(fromFileURL styleSheetFileURL: URL) -> StyleSheet? {
    return loadNamedStyleSheet(nil, group: StyleSheetGroupDefault, fromFileURL: styleSheetFileURL)
  }

  @discardableResult
  public func loadNamedStyleSheet(_ name: String?, group groupName: String?, fromFileURL styleSheetFileURL: URL) -> StyleSheet? {
    return styleSheetRepository.loadNamedStyleSheet(name, group: groupName, fromFileURL: styleSheetFileURL)
  }

  /**
   * Loads an auto-refreshable stylesheet from a URL (both file and http URLs are supported).
   * Note: Refreshable stylesheets are only intended for use during development, and not in production.
   */
  @discardableResult
  public func loadRefreshableStyleSheet(from styleSheetURL: URL) -> StyleSheet {
    return loadRefreshableNamedStyleSheet(nil, group: StyleSheetGroupDefault, from: styleSheetURL)
  }

  @discardableResult
  public func loadRefreshableNamedStyleSheet(_ name: String?, group groupName: String, from styleSheetURL: URL) -> StyleSheet {
    return styleSheetRepository.loadRefreshableNamedStyleSheet(name, group: groupName, from: styleSheetURL)
  }

  @discardableResult
  public func loadStyleSheet(fromLocalFileURL styleSheetFile: URL, withName name: String?, group groupName: String?) -> StyleSheet? {
    return styleSheetRepository.loadStyleSheet(fromLocalFileURL: styleSheetFile, withName: name, group: groupName)
  }
  
  public func register(_ styleSheet: StyleSheet) {
    styleSheetRepository.register(styleSheet);
  }
  
  
  // MARK: - Reload and unload

  /// Reloads all (remote) refreshable stylesheets. If force is `YES`, stylesheets will be reloaded even if they haven't been modified.
  public func reloadRefreshableStyleSheets(_ force: Bool) {
    styleSheetRepository.reloadRefreshableStyleSheets(force);
  }

  //* Reloads a refreshable stylesheet. If force is `YES`, the stylesheet will be reloaded even if is hasn't been modified.
  public func reload(_ styleSheet: RefreshableStyleSheet, force: Bool) {
    styleSheetRepository.reload(styleSheet, force: force);
  }

  /**
   * Unloads the specified styleSheet.
   * @param styleSheet the stylesheet to unload.
   */
  public func unload(_ styleSheet: StyleSheet) {
    styleSheetRepository.unload(styleSheet);
  }

  /**
   * Unloads all loaded stylesheets, effectively resetting the styling of all views.
   */
  public func unloadAllStyleSheets() {
    styleSheetRepository.unloadAllStyleSheets();
  }
  

  // MARK: - Parsing and matching
  
  /**
   * Parses the specified stylesheet data and returns an object (`StyleSheetContent`) representing the stylesheet content (rulesets and variables).
   */
  public func parseStyleSheetContent(_ styleSheetData: String) -> StyleSheetContent? {
    return styleSheetParser.parse(styleSheetData)
  }
  
  public func rulesets(matchingElement element: ElementStyle, context: StylingContext) -> [Ruleset] {
    var rulesets: [Ruleset] = []
    for styleSheet in activeStylesheets {
      if styleSheet.refreshable {
        context.stylesCacheable = false
      }
      // Find all matching (or potentially matching, i.e. pseudo class) rulesets
      let styleSheetRulesets = styleSheet.rulesets(matching: element, context: context)
      for ruleset in styleSheetRulesets {
        // Get reference to inherited rulesets, if any:
        if let extendedDeclarationSelectorChain = ruleset.extendedDeclarationSelectorChain, ruleset.extendedDeclaration == nil {
          for s in activeStylesheets {
            // TODO: Review caching of extendedDeclaration
            ruleset.extendedDeclaration = s.findRuleset(with: extendedDeclarationSelectorChain)
            if ruleset.extendedDeclaration != nil {
              break
            }
          }
        }
      }
      rulesets.append(contentsOf: styleSheetRulesets)
    }
    return rulesets
  }
  
  
  // MARK: - Variables
  
  /**
   * Returns the raw value of the stylesheet variable with the specified name.
   */
  public func valueOfStyleSheetVariable(withName variableName: String, scope: StyleSheetScope = .defaultGroupScope) -> String? {
    return variableRepository.valueOfStyleSheetVariable(withName: variableName, scope: scope)
  }
  
  /**
   * Sets the raw value of the stylesheet variable with the specified name.
   */
  public func setValue(_ value: String, forStyleSheetVariableWithName variableName: String) {
    return variableRepository.setValue(value, forStyleSheetVariableWithName: variableName)
  }
  
  public func replaceVariableReferences(_ inPropertyValue: String, scope: StyleSheetScope = .defaultGroupScope) -> String {
    var didReplace: Bool = false
    return replaceVariableReferences(inPropertyValue, scope: scope, didReplace: &didReplace)
  }
  
  public func replaceVariableReferences(_ inPropertyValue: String, scope: StyleSheetScope = .defaultGroupScope, didReplace: inout Bool) -> String {
    return variableRepository.replaceVariableReferences(inPropertyValue, scope: scope, didReplace: &didReplace)
  }
  
  /**
   * Returns the value of the stylesheet variable with the specified name, transformed to the specified type.
   */
  public func transformedValueOfStyleSheetVariable(withName variableName: String, as propertyType: PropertyType, scope: StyleSheetScope = .defaultGroupScope) -> Any? {
    return variableRepository.transformedValueOfStyleSheetVariable(withName: variableName, as: propertyType, scope: scope)
  }
  
  
  // MARK: - Property parsing
  
  public func parsePropertyNameValuePair(_ nameAndValue: String) -> PropertyValue? {
    return styleSheetParser.parsePropertyNameValuePair(nameAndValue)
  }
  
  public func parsePropertyNameValuePairs(_ propertyPairsString: String) -> [PropertyValue]? {
    return styleSheetParser.parsePropertyNameValuePairs(propertyPairsString)
  }
  
  
  // MARK: - Selector creation support
  
  public func createSelector(withType type: String? = nil, elementId: String? = nil, styleClasses: [String]? = nil, pseudoClasses: [PseudoClass]? = nil) -> Selector? {
    var selectorType: SelectorType? = nil
    var wildcardType = false
    if let typeName = type, typeName.hasData() {
      if typeName == "*" {
        wildcardType = true
      } else {
        let clazz: AnyClass = propertyManager.canonicalTypeClass(forType: typeName, registerIfNotFound: true) ?? AnyObject.self
        selectorType = SelectorType(typeName: typeName, type: clazz)
      }
    }
    
    if wildcardType {
      return .wildcardType(elementId: elementId, styleClasses: styleClasses, pseudoClasses: pseudoClasses)
    } else if selectorType != nil || elementId != nil || styleClasses?.count != 0 {
      return .selector(type: selectorType, elementId: elementId, styleClasses: styleClasses, pseudoClasses: pseudoClasses)
    } else if let type = type, type.hasData() {
      //            ISSLogWarning("Unrecognized type: '%@' - Have you perhaps forgotten to register a valid type selector class?", type)
    } else {
      //            ISSLogWarning("Invalid selector - type and style class missing!")
    }
    return nil
  }
  
  
  // MARK: - Debugging support
  
  public func logMatchingRulesets(forElement element: ElementStyle, context: StylingContext) {
    guard let uiElement = element.uiElement else { return }
    var existingSelectorChains: Set<SelectorChain> = []
    var match = false
    for styleSheet in activeStylesheets {
      let matchingDeclarations = styleSheet.rulesets(matching: element, context: context)
      var descriptions: [String] = []
      if matchingDeclarations.count > 0 {
        matchingDeclarations.forEach { ruleset in
          var chainDescriptions: [String] = []
          ruleset.selectorChains.forEach{ chain in
            if existingSelectorChains.contains(chain) {
              chainDescriptions.append("\(chain.debugDescription) (WARNING - DUPLICATE)")
            } else {
              chainDescriptions.append(chain.debugDescription)
            }
            existingSelectorChains.insert(chain)
          }
          descriptions.append("\(chainDescriptions.joined(separator: ", ")) {...}")
        }
        
        print("Rulesets in '\(styleSheet.styleSheetURL.lastPathComponent)' matching \(uiElement): [\n\t\(descriptions.joined(separator: ", \n\t"))\n]")
        match = true
      }
    }
    if !match {
      print("No rulesets match \(uiElement)")
    }
  }
}
