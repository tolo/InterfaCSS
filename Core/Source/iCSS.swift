//
//  InterfaCSSCore.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


/// Facade for InterfaCSS
public struct iCSS {
  
  public static let willRefreshStyleSheetsNotification = Notification.Name("InterfaCSS.WillRefreshStyleSheetsNotification")
  public static let didRefreshStyleSheetNotification = Notification.Name("InterfaCSS.DidRefreshStyleSheetNotification")
  public static let styleSheetRefreshFailedNotification = Notification.Name("InterfaCSS.StyleSheetRefreshFailedNotification")
  
  internal static let shouldClearAllCachedStylingInformation = Notification.Name("InterfaCSS.ShouldClearAllCachedStylingInformation")
  internal static let markCachedStylingInformationAsDirtyNotification = NSNotification.Name("InterfaCSS.MarkCachedStylingInformationAsDirtyNotification")
    
  
  static var stylingManager: StylingManager { StylingManager.shared }
  static var propertyManager: PropertyManager { StylingManager.shared.propertyManager }
  static var styleSheetManager: StyleSheetManager { StylingManager.shared.styleSheetManager }
  
  
  // MARK: - StylingManager convenience methods
  
  public static func style(for uiElement: Stylable) -> ElementStyle {
    stylingManager.style(for: uiElement)
  }
  
  public static func applyStyling(_ uiElement: Stylable, includeSubViews: Bool = true, force: Bool = false, styleSheetScope: StyleSheetScope = .all) {
    stylingManager.applyStyling(uiElement, includeSubViews: includeSubViews, force: force, styleSheetScope: styleSheetScope)
  }
  
  public static func clearCachedStylingInformation(for uiElement: Stylable, includeSubViews: Bool = true) {
    stylingManager.clearCachedStylingInformation(for: uiElement, includeSubViews: includeSubViews)
  }
  
  
  // MARK: - StyleSheetManager convenience methods
  
  @discardableResult
  public static func loadStyleSheet(fromMainBundleFile styleSheetFileName: String, name: String? = nil, group groupName: String? = nil) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromMainBundleFile: styleSheetFileName, name: name, group: groupName)
  }
  
  @discardableResult
  public static func loadStyleSheet(fromLocalFile styleSheetFileURL: URL, name: String? = nil, group groupName: String? = nil) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromLocalFile: styleSheetFileURL, name: name, group: groupName)
  }
  
  @discardableResult
  public static func loadStyleSheet(fromRefreshableFile styleSheetFileURL: URL, name: String? = nil, group groupName: String? = nil) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromRefreshableFile: styleSheetFileURL, name: name, group: groupName)
  }
  
  @discardableResult
  public static func loadStyleSheet(fromRefreshableProjectFile projectFile: String, relativeToDirectoryContaining currentFile: String) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromRefreshableProjectFile: projectFile, relativeToDirectoryContaining: currentFile)
  }
  
  @discardableResult
  public static func loadStyleSheet(fromResourceFile resourceFile: ResourceFile) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromResourceFile: resourceFile)
  }
  
  public static func stringValueOf(variableWithName variableName: String, styleSheetScope: StyleSheetScope = .all) -> String? {
    styleSheetManager.valueOfStyleSheetVariable(withName: variableName, scope: styleSheetScope)
  }
  
  public static func valueOf(variableWithName variableName: String, as propertyType: PropertyType, styleSheetScope: StyleSheetScope = .all) -> Any? {
    styleSheetManager.transformedValueOfStyleSheetVariable(withName: variableName, as: propertyType, scope: styleSheetScope)
  }
  
  public static func valueOf<T>(variableWithName variableName: String, as propertyType: TypedPropertyType<T>, styleSheetScope: StyleSheetScope = .all) -> T? {
    styleSheetManager.transformedValueOfStyleSheetVariable(withName: variableName, as: propertyType, scope: styleSheetScope)
  }
}
