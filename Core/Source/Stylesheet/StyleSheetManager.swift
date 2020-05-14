//
//  StyleSheetManager.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


public class StyleSheetManager: NSObject {
  public static let WillRefreshStyleSheetsNotification = NSNotification.Name("InterfaCSS.WillRefreshStyleSheetsNotification")
  public static let DidRefreshStyleSheetNotification = NSNotification.Name("InterfaCSS.DidRefreshStyleSheetNotification")
  
  private let styleSheetRepository = StyleSheetRepository()
  private let variableRepository = VariableRepository();
  
  weak var stylingManager: StylingManager? // TODO: Review if this dependency can be removed
  
  let styleSheetParser: StyleSheetParser
  let pseudoClassFactory: PseudoClassFactoryType
  
  /**
   * All currently active stylesheets (`StyleSheet`).
   */
  public var styleSheets: [StyleSheet] { styleSheetRepository.styleSheets }
  //private(set) var styleSheets: [StyleSheet] = []
  
  var activeStylesheets: [StyleSheet] { styleSheetRepository.activeStylesheets }
//  private var activeStylesheets: [StyleSheet] {
//    return styleSheets.filter { $0.active }
//  }
  
//  private var runtimeStyleSheetsVariables: [String : String] = [:]

//  private var timer: Timer?
  
  /**
   * The interval at which refreshable stylesheets are refreshed. Default is 5 seconds. If value is set to <= 0, automatic refresh is disabled. Note: this is only use for stylesheets loaded from a remote URL.
   */
  public var stylesheetAutoRefreshInterval: TimeInterval {
    get { styleSheetRepository.stylesheetAutoRefreshInterval }
    set { styleSheetRepository.stylesheetAutoRefreshInterval = newValue }
  }
//  private var _stylesheetAutoRefreshInterval: TimeInterval = 0.0
//  var stylesheetAutoRefreshInterval: TimeInterval {
//    get {
//      return _stylesheetAutoRefreshInterval
//    }
//    set {
//      _stylesheetAutoRefreshInterval = newValue
//      if timer != nil {
//        disableAutoRefreshTimer()
//        enableAutoRefreshTimer()
//      }
//    }
//  }
  
  
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
//    if let url = Bundle.main.url(forResource: styleSheetFileName, withExtension: nil) {
//      return loadStyleSheet(fromLocalFileURL: url, withName: name, group: groupName)
//    } else {
//      //            ISSLogWarning("Unable to load stylesheet '%@' - file not found in main bundle!", styleSheetFileName) // TODO:
//      return nil
//    }
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
//    if FileManager.default.fileExists(atPath: styleSheetFileURL.path) {
//      return loadStyleSheet(fromLocalFileURL: styleSheetFileURL, withName: name, group: groupName)
//    } else {
//      //            ISSLogWarning("Unable to load stylesheet '%@' - file not found!", styleSheetFileURL)
//      return nil
//    }
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
//    let styleSheet = RefreshableStyleSheet(styleSheetURL: styleSheetURL, name: name, group: groupName)
//    styleSheets.append(styleSheet)
//    reload(styleSheet, force: false)
//    var usingStyleSheetModificationMonitoring = false
//    if styleSheet.styleSheetModificationMonitoringSupported {
//      // Attempt to use file monitoring instead of polling, if supported
//      weak var weakSelf: StyleSheetManager? = self
//      styleSheet.startMonitoringStyleSheetModification({ refreshed in
//        weakSelf?.reload(styleSheet, force: true)
//      })
//      usingStyleSheetModificationMonitoring = styleSheet.styleSheetModificationMonitoringEnabled
//    }
//    if !usingStyleSheetModificationMonitoring {
//      enableAutoRefreshTimer()
//    }
//    return styleSheet
    return styleSheetRepository.loadRefreshableNamedStyleSheet(name, group: groupName, from: styleSheetURL)
  }

  @discardableResult
  public func loadStyleSheet(fromLocalFileURL styleSheetFile: URL, withName name: String?, group groupName: String?) -> StyleSheet? {
//    var styleSheet: StyleSheet? = nil
//    for existingStyleSheet in styleSheets {
//      if existingStyleSheet.styleSheetURL == styleSheetFile {
//        //                ISSLogDebug("Stylesheet %@ already loaded", styleSheetFile) // TODO:
//        return existingStyleSheet
//      }
//    }
//
//    if let styleSheetData = try? String(contentsOf: styleSheetFile) {
//      //            let t: TimeInterval = Date.timeIntervalSinceReferenceDate
//      if let styleSheetContent = styleSheetParser.parse(styleSheetData) {
//        //            ISSLogDebug("Loaded stylesheet '%@' in %f seconds", styleSheetFile.lastPathComponent, (Date.timeIntervalSinceReferenceDate - t)) // TODO:
//        styleSheet = StyleSheet(styleSheetURL: styleSheetFile, name: name, group: groupName, content: styleSheetContent)
//        if let styleSheet = styleSheet {
//          styleSheets.append(styleSheet)
//        }
//        stylingManager?.clearAllCachedStyles()
//      }
//    } else {
//      //            ISSLogWarning("Error loading stylesheet data from '%@' - %@", styleSheetFile, error) // TODO:
//    }
//    return styleSheet
    return styleSheetRepository.loadStyleSheet(fromLocalFileURL: styleSheetFile, withName: name, group: groupName)
  }
  
  public func register(_ styleSheet: StyleSheet) {
    //    styleSheets.append(styleSheet)
    //    stylingManager?.clearAllCachedStyles()
    styleSheetRepository.register(styleSheet);
  }
  
  
  // MARK: - Reload and unload

  /// Reloads all (remote) refreshable stylesheets. If force is `YES`, stylesheets will be reloaded even if they haven't been modified.
  public func reloadRefreshableStyleSheets(_ force: Bool) {
//    NotificationCenter.default.post(name: Self.WillRefreshStyleSheetsNotification, object: nil)
//    for styleSheet: StyleSheet in styleSheets {
//      guard let refreshableStylesheet = styleSheet as? RefreshableStyleSheet else { continue }
//      if refreshableStylesheet.active && !refreshableStylesheet.styleSheetModificationMonitoringEnabled {
//        // Attempt to get updated stylesheet
//        doReload(refreshableStylesheet, force: force)
//      }
//    }
    styleSheetRepository.reloadRefreshableStyleSheets(force);
  }

  //* Reloads a refreshable stylesheet. If force is `YES`, the stylesheet will be reloaded even if is hasn't been modified.
  public func reload(_ styleSheet: RefreshableStyleSheet, force: Bool) {
//    NotificationCenter.default.post(name: Self.WillRefreshStyleSheetsNotification, object: styleSheet)
//    doReload(styleSheet, force: force)
    styleSheetRepository.reload(styleSheet, force: force);
  }

  /**
   * Unloads the specified styleSheet.
   * @param styleSheet the stylesheet to unload.
   */
  public func unload(_ styleSheet: StyleSheet) {
//    styleSheets.removeAll { $0 == styleSheet }
//    styleSheet.unload()
//    stylingManager?.clearAllCachedStyles()
    styleSheetRepository.unload(styleSheet);
  }

  /**
   * Unloads all loaded stylesheets, effectively resetting the styling of all views.
   */
  public func unloadAllStyleSheets() {
//    styleSheets.removeAll()
//    stylingManager?.clearAllCachedStyles()
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
  //    var value: String? = runtimeStyleSheetsVariables[variableName]
  //    if value == nil {
  //      for styleSheet in activeStylesheets.reversed() {
  //        value = styleSheet.content.variables[variableName] // TODO: Review access
  //        if value != nil {
  //          break
  //        }
  //      }
  //    }
  //    return value
  }
  
  /**
   * Sets the raw value of the stylesheet variable with the specified name.
   */
  public func setValue(_ value: String, forStyleSheetVariableWithName variableName: String) {
    return variableRepository.setValue(value, forStyleSheetVariableWithName: variableName)
//    runtimeStyleSheetsVariables[variableName] = value
  }
  
  public func replaceVariableReferences(_ inPropertyValue: String, scope: StyleSheetScope = .defaultGroupScope, didReplace: inout Bool) -> String {
    return variableRepository.replaceVariableReferences(inPropertyValue, scope: scope, didReplace: &didReplace)
  //    var location: Int = 0
  //    var propertyValue = inPropertyValue
  //    while location < propertyValue.count {
  //      // Replace any variable references
  //      var varPrefixLength = 2
  //      var varBeginLocation = propertyValue.index(ofString: "--", from: location)
  //      if (varBeginLocation == NSNotFound) {
  //        varPrefixLength = 1
  //        varBeginLocation = propertyValue.index(ofChar: "@", from: location)
  //      }
  //
  //      if varBeginLocation != NSNotFound {
  //        location = varBeginLocation + varPrefixLength
  //
  //        let variableNameRangeEnd = propertyValue.index(ofCharInSet: notValidIdentifierCharsSet, from: location)
  //        let variableNameRange = propertyValue.range(from: location, to: variableNameRangeEnd)
  //
  //        var variableValue: String? = nil
  //        if !variableNameRange.isEmpty {
  //          let variableName = propertyValue[variableNameRange]
  //          variableValue = valueOfStyleSheetVariable(withName: String(variableName), scope: scope)
  //        }
  //        if let variableValue = variableValue {
  //          var variableValue = variableValue.trimQuotes()
  //          variableValue = replaceVariableReferences(variableValue, scope: scope, didReplace: &didReplace) // Resolve nested variables
  //          // Replace variable occurrence in propertyValue string with variableValue string
  //          propertyValue = propertyValue.replaceCharacterInRange(from: varBeginLocation, to: variableNameRangeEnd, with: variableValue)
  //          location += variableValue.count
  //          didReplace = true
  //        } else  {
  //          // ISSLogWarning("Unrecognized property variable: %@ (property value: %@)", variableName, propertyValue)
  //          location = variableNameRangeEnd
  //        }
  //      } else {
  //        break
  //      }
  //    }
  //    return propertyValue
  }
  
  /**
   * Returns the value of the stylesheet variable with the specified name, transformed to the specified type.
   */
  public func transformedValueOfStyleSheetVariable(withName variableName: String, as propertyType: PropertyType, scope: StyleSheetScope = .defaultGroupScope) -> Any? {
    return variableRepository.transformedValueOfStyleSheetVariable(withName: variableName, as: propertyType, scope: scope)
//    if let rawValue = valueOfStyleSheetVariable(withName: variableName, scope: scope) {
//      var didReplace = false
//      let value = replaceVariableReferences(rawValue, scope: scope, didReplace: &didReplace)
//      return propertyType.parser.parse(propertyValue: PropertyValue(propertyName: variableName, value: value))
////      return styleSheetParser.parsePropertyValue(modValue, as: propertyType)
//    }
//    return nil
  }
  
  
  // MARK: - Property parsing
  


//  public func parsePropertyValue(_ value: String, as type: PropertyType, scope: StyleSheetScope = .defaultGroupScope) -> Any? {
//    var didReplace = false
//    return parsePropertyValue(value, as: type, scope: scope, didReplaceVariableReferences: &didReplace)
//  }
//
//  public func parsePropertyValue(_ value: String, as type: PropertyType, scope: StyleSheetScope = .defaultGroupScope, didReplaceVariableReferences didReplace: inout Bool) -> Any? {
//    let modValue = replaceVariableReferences(value, scope: scope, didReplace: &didReplace)
//    return styleSheetParser.parsePropertyValue(modValue, as: type)
//  }
  
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
      } else if let propertyManager = stylingManager?.propertyManager,
        let clazz = propertyManager.canonicalTypeClass(forType: typeName) {
        selectorType = SelectorType(typeName: typeName, type: clazz)
      } else {
        selectorType = SelectorType(typeName: typeName, type: AnyObject.self)
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
  
  public func logMatchingRulesets(forElement element: ElementStyle, styleSheetScope: StyleSheetScope) {
    guard let uiElement = element.uiElement, let stylingManager = stylingManager else { return }
    var existingSelectorChains: Set<SelectorChain> = []
    var match = false
    let stylingContext = StylingContext(styler: stylingManager, styleSheetScope: styleSheetScope)
    for styleSheet in activeStylesheets {
      let matchingDeclarations = styleSheet.rulesets(matching: element, context: stylingContext)
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
  
//
//  // MARK: - Properties
//  // MARK: - Timer
//  func enableAutoRefreshTimer() {
//    if timer == nil && stylesheetAutoRefreshInterval > 0 {
//      timer = Timer.scheduledTimer(timeInterval: stylesheetAutoRefreshInterval, target: self, selector: #selector(StyleSheetManager.autoRefreshTimerTick), userInfo: nil, repeats: true)
//    }
//  }
//  func disableAutoRefreshTimer() {
//    timer?.invalidate()
//    timer = nil
//  }
//  @objc func autoRefreshTimerTick() {
//    reloadRefreshableStyleSheets(false)
//  }
//  func doReload(_ styleSheet: RefreshableStyleSheet, force: Bool) {
//    styleSheet.refreshStylesheet(with: self, andCompletionHandler: {
//      //        [self.styleSheets removeObject:styleSheet];
//      //        [self.styleSheets addObject:styleSheet]; // Make stylesheet "last added/updated"
//      self.stylingManager?.clearAllCachedStyles()
//      NotificationCenter.default.post(name: Self.DidRefreshStyleSheetNotification, object: styleSheet)
//    }, force: force)
//  }
//  //- (void) unloadStyleSheet:(StyleSheet*)styleSheet refreshStyling:(BOOL)refreshStyling {
//  //- (void) unloadAllStyleSheets:(BOOL)refreshStyling {
//  func activeStylesheets(in scope: StyleSheetScope) -> [Any] {
//    return styleSheets.filter { styleSheet in
//      return styleSheet.active && scope.contains(styleSheet)
//    }
//  }
  // MARK: - Variables
  // MARK: - Selector creation support
  // MARK: - Pseudo class customization support
  // MARK: - Debugging support
}
