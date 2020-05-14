//
//  StyleSheetRepository.swift
//  InterfaCSS
//
//  Created by Tobias Löfstrand on 2020-05-07.
//  Copyright © 2020 Leafnode AB. All rights reserved.
//

import Foundation

final class StyleSheetRepository {
  private var timer: Timer?
  
  weak var styleSheetManager: StyleSheetManager!
  
  var styleSheets: [StyleSheet] = []
  
  var activeStylesheets: [StyleSheet] { styleSheets.filter { $0.active } }
  
  private var _stylesheetAutoRefreshInterval: TimeInterval = 0.0
  var stylesheetAutoRefreshInterval: TimeInterval {
    get {
      return _stylesheetAutoRefreshInterval
    }
    set {
      _stylesheetAutoRefreshInterval = newValue
      if timer != nil {
        disableAutoRefreshTimer()
        enableAutoRefreshTimer()
      }
    }
  }
  
  
  // MARK: - Utilities
  
  func activeStylesheets(in scope: StyleSheetScope) -> [StyleSheet] {
    return styleSheets.filter { $0.active && scope.contains($0) }
  }
  
  
  // MARK: - Stylesheets loading
  
  @discardableResult
  func loadNamedStyleSheet(_ name: String?, group groupName: String, fromMainBundleFile styleSheetFileName: String) -> StyleSheet? {
    if let url = Bundle.main.url(forResource: styleSheetFileName, withExtension: nil) {
      return loadStyleSheet(fromLocalFileURL: url, withName: name, group: groupName)
    } else {
      //            ISSLogWarning("Unable to load stylesheet '%@' - file not found in main bundle!", styleSheetFileName) // TODO:
      return nil
    }
  }
  
  @discardableResult
  func loadNamedStyleSheet(_ name: String?, group groupName: String?, fromFileURL styleSheetFileURL: URL) -> StyleSheet? {
    if FileManager.default.fileExists(atPath: styleSheetFileURL.path) {
      return loadStyleSheet(fromLocalFileURL: styleSheetFileURL, withName: name, group: groupName)
    } else {
      //            ISSLogWarning("Unable to load stylesheet '%@' - file not found!", styleSheetFileURL)
      return nil
    }
  }
  
  @discardableResult
  func loadRefreshableNamedStyleSheet(_ name: String?, group groupName: String, from styleSheetURL: URL) -> StyleSheet {
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
  func loadStyleSheet(fromLocalFileURL styleSheetFile: URL, withName name: String?, group groupName: String?) -> StyleSheet? {
    var styleSheet: StyleSheet? = nil
    for existingStyleSheet in styleSheets {
      if existingStyleSheet.styleSheetURL == styleSheetFile {
        //                ISSLogDebug("Stylesheet %@ already loaded", styleSheetFile) // TODO:
        return existingStyleSheet
      }
    }
    
    if let styleSheetData = try? String(contentsOf: styleSheetFile) {
      //            let t: TimeInterval = Date.timeIntervalSinceReferenceDate
      if let styleSheetContent = styleSheetManager.styleSheetParser.parse(styleSheetData) {
        //            ISSLogDebug("Loaded stylesheet '%@' in %f seconds", styleSheetFile.lastPathComponent, (Date.timeIntervalSinceReferenceDate - t)) // TODO:
        styleSheet = StyleSheet(styleSheetURL: styleSheetFile, name: name, group: groupName, content: styleSheetContent)
        if let styleSheet = styleSheet {
          styleSheets.append(styleSheet)
        }
//        stylingManager?.clearAllCachedStyles() // TODO: Notification instead
      }
    } else {
      //            ISSLogWarning("Error loading stylesheet data from '%@' - %@", styleSheetFile, error) // TODO:
    }
    return styleSheet
  }
  
  func register(_ styleSheet: StyleSheet) {
    styleSheets.append(styleSheet)
    //    stylingManager?.clearAllCachedStyles() // TODO: Notification instead
  }
  
  
  // MARK: - Reload and unload
  
  /// Reloads all (remote) refreshable stylesheets. If force is `YES`, stylesheets will be reloaded even if they haven't been modified.
  func reloadRefreshableStyleSheets(_ force: Bool) {
    NotificationCenter.default.post(name: StyleSheetManager.WillRefreshStyleSheetsNotification, object: nil)
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
    NotificationCenter.default.post(name: StyleSheetManager.WillRefreshStyleSheetsNotification, object: styleSheet)
    doReload(styleSheet, force: force)
  }
  
  private func doReload(_ styleSheet: RefreshableStyleSheet, force: Bool) {
    styleSheet.refreshStylesheet(with: styleSheetManager, andCompletionHandler: {
      //        [self.styleSheets removeObject:styleSheet];
      //        [self.styleSheets addObject:styleSheet]; // Make stylesheet "last added/updated"
      //      self.stylingManager?.clearAllCachedStyles() // TODO: Notification instead
      NotificationCenter.default.post(name: StyleSheetManager.DidRefreshStyleSheetNotification, object: styleSheet)
    }, force: force)
  }
  
  /**
   * Unloads the specified styleSheet.
   * @param styleSheet the stylesheet to unload.
   */
  func unload(_ styleSheet: StyleSheet) {
    styleSheets.removeAll { $0 == styleSheet }
    styleSheet.unload()
    //stylingManager?.clearAllCachedStyles() // TODO: Notification instead
  }
  
  /**
   * Unloads all loaded stylesheets, effectively resetting the styling of all views.
   */
  func unloadAllStyleSheets() {
    styleSheets.removeAll()
    //stylingManager?.clearAllCachedStyles() // TODO: Notification instead
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
