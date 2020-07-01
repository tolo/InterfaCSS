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
  
  func styler(with styleSheetScope: StyleSheetScope, includeCurrent: Bool) -> Styler
  
  func stylingProxy(for uiElement: Stylable) -> ElementStyle
  
  //func applyStyling(_ uiElement: Stylable, includeSubViews: Bool, force: Bool, styleSheetScope: StyleSheetScope)
  func applyStyling(_ uiElement: Stylable, includeSubViews: Bool, force: Bool, styleSheetScope: StyleSheetScope?)
  
  func clearCachedStylingInformation(for uiElement: Stylable, includeSubViews: Bool)
}


public extension Styler {
  
  // MARK: - Convenience methods with default parameters
  
  
  func styler(with styleSheetScope: StyleSheetScope, includeCurrent: Bool = true) -> Styler {
    return styler(with: styleSheetScope, includeCurrent: includeCurrent)
  }
  
  //func applyStyling(_ uiElement: Stylable, includeSubViews: Bool = true, force: Bool = false, styleSheetScope: StyleSheetScope = .defaultGroupScope) {
  func applyStyling(_ uiElement: Stylable, includeSubViews: Bool = true, force: Bool = false, styleSheetScope: StyleSheetScope? = nil) {
    applyStyling(uiElement, includeSubViews: includeSubViews, force: force, styleSheetScope: styleSheetScope ?? self.styleSheetScope)
  }
  
  // MARK: - StyleSheetManager convenience methods
  
  @discardableResult
  func loadStyleSheet(fromMainBundleFile styleSheetFileName: String) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromMainBundleFile: styleSheetFileName)
  }
  
  @discardableResult
  func loadStyleSheet(fromFileURL styleSheetFileURL: URL) -> StyleSheet? {
    return styleSheetManager.loadStyleSheet(fromFileURL: styleSheetFileURL)
  }
  
  @discardableResult
  func loadRefreshableStyleSheet(from styleSheetFileURL: URL) -> StyleSheet? {
    return styleSheetManager.loadRefreshableStyleSheet(from: styleSheetFileURL)
  }
  
  @discardableResult
  func loadStyleSheet(fromRefreshableProjectFile projectFile: String, relativeToDirectoryContaining currentFile: String) -> StyleSheet? {
    let resourceFile = ResourceFile.refreshableProjectFile(projectFile, relativeToDirectoryContaining: currentFile)
    return loadStyleSheet(fromResourceFile: resourceFile)
  }
  
  @discardableResult
  func loadStyleSheet(fromResourceFile resourceFile: ResourceFile) -> StyleSheet? {
    if resourceFile.refreshable {
      return loadRefreshableStyleSheet(from: resourceFile.fileURL)
    } else {
      return loadStyleSheet(fromFileURL: resourceFile.fileURL)
    }
  }
}
