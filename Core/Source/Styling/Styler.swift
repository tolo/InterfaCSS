//
//  Styler.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

/**
 * A styler is responsible for applying style to UI elements, possibly in a particular scope.
 *
 * @see StylingManager
 */
public protocol Styler {
  
  var styleSheetScope: StyleSheetScope { get }
  
  var propertyManager: PropertyManager { get }
  var styleSheetManager: StyleSheetManager { get }
  
  func styler(withScope styleSheetScope: StyleSheetScope) -> Styler
  
  func style(for uiElement: Stylable) -> ElementStyle
  
  func applyStyling(_ uiElement: Stylable, includeSubViews: Bool, force: Bool)
  func applyStyling(_ elementStyle: ElementStyle, includeSubViews: Bool, force: Bool)
  
  func clearCachedStylingInformation(for uiElement: Stylable, includeSubViews: Bool)
  
}


// MARK: - Styler/StylingManager convenience methods and methods with default parameters

public extension Styler {
  
  func applyStyling(_ uiElement: Stylable) { applyStyling(uiElement, includeSubViews: true, force: false) }
  func applyStyling(_ uiElement: Stylable, includeSubViews: Bool) { applyStyling(uiElement, includeSubViews: includeSubViews, force: false) }
  func applyStyling(_ uiElement: Stylable, force: Bool) { applyStyling(uiElement, includeSubViews: true, force: force) }
  
}


// MARK: - StyleSheetManager convenience methods

public extension Styler {
  
  @discardableResult
  func loadStyleSheet(fromMainBundleFile styleSheetFileName: String, name: String? = nil, group groupName: String? = nil) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromMainBundleFile: styleSheetFileName, name: name, group: groupName)
  }
  
  @discardableResult
  func loadStyleSheet(fromLocalFile styleSheetFileURL: URL, name: String? = nil, group groupName: String? = nil) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromLocalFile: styleSheetFileURL, name: name, group: groupName)
  }
  
  @discardableResult
  func loadStyleSheet(fromRefreshableFile styleSheetFileURL: URL, name: String? = nil, group groupName: String? = nil) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromRefreshableFile: styleSheetFileURL, name: name, group: groupName)
  }
  
  @discardableResult
  func loadStyleSheet(fromRefreshableProjectFile projectFile: String, relativeToDirectoryContaining currentFile: String) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromRefreshableProjectFile: projectFile, relativeToDirectoryContaining: currentFile)
  }
  
  @discardableResult
  func loadStyleSheet(fromResourceFile resourceFile: ResourceFile) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromResourceFile: resourceFile)
  }
  
  func stringValueOf(variableWithName variableName: String) -> String? {
    styleSheetManager.valueOfStyleSheetVariable(withName: variableName, scope: styleSheetScope)
  }
  
  func valueOf(variableWithName variableName: String, as propertyType: PropertyType) -> Any? {
    styleSheetManager.transformedValueOfStyleSheetVariable(withName: variableName, as: propertyType, scope: styleSheetScope)
  }
  
  func valueOf<T>(variableWithName variableName: String, as propertyType: TypedPropertyType<T>) -> T? {
    styleSheetManager.transformedValueOfStyleSheetVariable(withName: variableName, as: propertyType, scope: styleSheetScope)
  }
}
