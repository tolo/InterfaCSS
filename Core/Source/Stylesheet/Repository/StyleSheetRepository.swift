//
//  StyleSheetRepository.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

final class StyleSheetRepository {
  private var timer: Timer?
  
  weak var styleSheetManager: StyleSheetManager!
  
  var styleSheets: [StyleSheet] = []
  
  var stylesheetAutoRefreshInterval: TimeInterval = 10.0 {
    didSet {
      if timer != nil {
        disableAutoRefreshTimer()
        enableAutoRefreshTimer()
      }
    }
  }
  
  
  // MARK: - Utilities
  
  func activeStylesheets(in scope: StyleSheetScope) -> [StyleSheet] {
    return styleSheets.filter { $0.active && scope.matches(styleSheet: $0) }
  }
  
  func findStyleSheet(withURL url: URL) -> StyleSheet? {
    for existingStyleSheet in styleSheets {
      if existingStyleSheet.styleSheetURL == url {
        return existingStyleSheet
      }
    }
    return nil
  }
  
  
  // MARK: - Stylesheets loading
  
  @discardableResult
  func loadStyleSheet(fromMainBundleFile styleSheetFileName: String, name: String?, group groupName: String?) -> StyleSheet? {
    if let url = Bundle.main.url(forResource: styleSheetFileName, withExtension: nil) {
      return loadStyleSheet(fromLocalFile: url, name: name, group: groupName)
    } else {
      error(.stylesheets, "Unable to load stylesheet '\(styleSheetFileName)' - file not found in main bundle!")
      return nil
    }
  }
  
  @discardableResult
  func loadStyleSheet(fromRefreshableFile styleSheetURL: URL, name: String?, group groupName: String?) -> StyleSheet? {
    if let existing = findStyleSheet(withURL: styleSheetURL) {
      debug(.stylesheets, "Stylesheet '\(styleSheetURL)' already loaded")
      return existing
    }
    
    let styleSheet = RefreshableStyleSheet(styleSheetURL: styleSheetURL, name: name, group: groupName)
    styleSheets.append(styleSheet)
    reload(styleSheet, force: false)
    var usingStyleSheetModificationMonitoring = false
    if styleSheet.styleSheetModificationMonitoringSupported {
      // Attempt to use file monitoring instead of polling, if supported
      styleSheet.startMonitoringStyleSheetModification({ [weak self] refreshed in
        self?.reload(styleSheet, force: true)
      })
      usingStyleSheetModificationMonitoring = styleSheet.styleSheetModificationMonitoringEnabled
    }
    if !usingStyleSheetModificationMonitoring {
      enableAutoRefreshTimer()
    }
    return styleSheet
  }
  
  @discardableResult
  func loadStyleSheet(fromLocalFile styleSheetFile: URL, name: String?, group groupName: String?) -> StyleSheet? {
    guard FileManager.default.fileExists(atPath: styleSheetFile.path) else {
      error(.stylesheets, "Unable to load stylesheet '\(styleSheetFile)' - file not found!")
      return nil
    }
    if let existing = findStyleSheet(withURL: styleSheetFile) {
      debug(.stylesheets, "Stylesheet '\(styleSheetFile)' already loaded")
      return existing
    }
    
    if let styleSheetData = try? String(contentsOf: styleSheetFile) {
      let t: TimeInterval = Date.timeIntervalSinceReferenceDate
      if let content = styleSheetManager.styleSheetParser.parse(styleSheetData) {
        debug(.stylesheets, "Loaded stylesheet '\(styleSheetFile.lastPathComponent)' (\(content.rulesets.count) rulesets, \(content.variables.count) variables) in \((Date.timeIntervalSinceReferenceDate - t)) seconds")
        let styleSheet = StyleSheet(styleSheetURL: styleSheetFile, name: name, group: groupName, content: content)
        styleSheets.append(styleSheet)
        iCSS.shouldClearAllCachedStylingInformation.post()
        return styleSheet
      }
    } else {
      error(.stylesheets, "Error loading stylesheet data from '\(styleSheetFile)'")
    }
    return nil
  }
  
  func register(_ styleSheet: StyleSheet) {
    styleSheets.append(styleSheet)
    iCSS.shouldClearAllCachedStylingInformation.post()
  }
  
  
  // MARK: - Reload and unload
  
  /// Reloads all (remote) refreshable stylesheets. If force is `YES`, stylesheets will be reloaded even if they haven't been modified.
  func reloadRefreshableStyleSheets(_ force: Bool) {
    iCSS.willRefreshStyleSheetsNotification.post()
    for styleSheet: StyleSheet in styleSheets {
      guard let refreshableStylesheet = styleSheet as? RefreshableStyleSheet else { continue }
      if refreshableStylesheet.active && !refreshableStylesheet.styleSheetModificationMonitoringEnabled {
        // Attempt to get updated stylesheet
        doReload(refreshableStylesheet, force: force)
      }
    }
  }
  
  /// Reloads a refreshable stylesheet. If force is `YES`, the stylesheet will be reloaded even if is hasn't been modified.
  func reload(_ styleSheet: RefreshableStyleSheet, force: Bool) {
    iCSS.willRefreshStyleSheetsNotification.post(object: styleSheet)
    doReload(styleSheet, force: force)
  }
  
  private func doReload(_ styleSheet: RefreshableStyleSheet, force: Bool) {
    styleSheet.refreshStylesheet(with: styleSheetManager, andCompletionHandler: { _, success in
      iCSS.shouldClearAllCachedStylingInformation.post()
      if success { iCSS.didRefreshStyleSheetNotification.post(object: styleSheet) }
      else { iCSS.didRefreshStyleSheetNotification.post(object: styleSheet) }
    }, force: force)
  }
  
  /**
   * Unloads the specified styleSheet.
   * @param styleSheet the stylesheet to unload.
   */
  func unload(_ styleSheet: StyleSheet) {
    styleSheets.removeAll { $0 == styleSheet }
    styleSheet.unload()
    iCSS.shouldClearAllCachedStylingInformation.post()
  }
  
  /**
   * Unloads all loaded stylesheets, effectively resetting the styling of all views.
   */
  func unloadAllStyleSheets() {
    styleSheets.removeAll()
    iCSS.shouldClearAllCachedStylingInformation.post()
  }
  

  // MARK: - Timer / Autorefresh
  
  func enableAutoRefreshTimer() {
    if timer == nil && stylesheetAutoRefreshInterval > 0 {
      timer = Timer.scheduledTimer(timeInterval: stylesheetAutoRefreshInterval, target: self, selector: #selector(autoRefreshTimerTick), userInfo: nil, repeats: true)
    }
  }
  
  func disableAutoRefreshTimer() {
    timer?.invalidate()
    timer = nil
  }
  
  @objc func autoRefreshTimerTick() {
    reloadRefreshableStyleSheets(false)
  }
}
