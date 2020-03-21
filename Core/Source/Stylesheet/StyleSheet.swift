//
//  StyleSheet.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

public typealias StyleSheetMatcher = (StyleSheet) -> Bool

// TODO: Move into StyleSheet?
public extension Notification.Name {
  static let StyleSheetRefreshedNotification = Notification.Name("InterfaCSS.StyleSheetRefreshedNotification")
  static let StyleSheetRefreshFailedNotification = NSNotification.Name("InterfaCSS.StyleSheetRefreshFailedNotification")
}


public typealias RefreshableStyleSheetObserverBlock = (RefreshableStyleSheet) -> Void

// TODO: Review where these should be placed
public let StyleSheetGroupDefault = "ISSStyleSheetGroupDefault"
public let StyleSheetNoGroup: String? = nil


/**
 * Class representing a scope used for limiting which stylesheets should be used for styling.
 */
public class StyleSheetScope: NSObject {
  public static let defaultGroupScope: StyleSheetScope = {
    StyleSheetScope(matcher: { styleSheet in
      return styleSheet.group == StyleSheetGroupDefault
    })
  }()
  
  public static func defaultGroupScope(includingStyleSheetNames names: [String]) -> StyleSheetScope {
    return StyleSheetScope.defaultGroupScope.including(StyleSheetScope(styleSheetNames: names))
  }
  
  private let matcher: StyleSheetMatcher
  
  public convenience init(styleSheetNames names: [String]) {
    let nameSet = Set<AnyHashable>(names)
    self.init(matcher: { styleSheet in
      return nameSet.contains(styleSheet.name)
    })
  }
  
  public convenience init(styleSheetGroups groups: [String]) {
    let groupsSet = Set<AnyHashable>(groups)
    self.init(matcher: { styleSheet in
      return groupsSet.contains(styleSheet.group ?? "")
    })
  }
  
  public convenience init(defaultStyleSheetGroupAndGroups groups: [String]) {
    self.init(styleSheetGroups: groups + [StyleSheetGroupDefault])
  }
  
  public init(matcher: @escaping StyleSheetMatcher) {
    self.matcher = matcher
  }
  
  public func including(_ otherScope: StyleSheetScope) -> StyleSheetScope {
    return StyleSheetScope(matcher: { styleSheet in
      return self.matcher(styleSheet) || otherScope.matcher(styleSheet)
    })
  }
  
  public func contains(_ styleSheet: StyleSheet) -> Bool {
    return Bool(matcher(styleSheet))
  }
}


/**
 * Represents a loaded stylesheet.
 */
public class StyleSheet: Hashable, CustomStringConvertible, CustomDebugStringConvertible {
  
  public static func == (lhs: StyleSheet, rhs: StyleSheet) -> Bool {
    return lhs.name == rhs.name && lhs.styleSheetURL == rhs.styleSheetURL
  }
  
  public let name: String
  public let group: String?
  public let styleSheetURL: URL
  public var content: StyleSheetContent
  public var active = false
  
  open var refreshable: Bool {
    return false
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name, styleSheetURL)
  }
  
  open var description: String {
    return "StyleSheet[\(styleSheetURL.lastPathComponent), \(content.rulesets.count) decls]"
  }
  
  open var debugDescription: String {
    var str = ""
    for ruleset in content.rulesets {
      var descr = ruleset.debugDescription
      descr = descr.replacingOccurrences(of: "\n", with: "\n\t")
      if str.count == 0 {
        str += "\n\t\(descr)"
      } else {
        str += ", \n\t\(descr)"
      }
    }
    if str.count > 0 {
      str += "\n"
    }
    return "StyleSheet[\(styleSheetURL.lastPathComponent) - \(str)]"
  }
  
  // MARK: - Lifecycle
  
  public required init(styleSheetURL: URL, name: String? = nil, group groupName: String? = nil, content: StyleSheetContent = .empty) {
    self.styleSheetURL = styleSheetURL
    self.content = content
    active = true
    self.name = name ?? styleSheetURL.lastPathComponent
    group = groupName
  }
  
  // MARK: - Matching
  
  public final func rulesets(matching element: ElementStyle, context: StylingContext) -> [Ruleset] {
    if !context.styleSheetScope.contains(self) {
      logError(.stylesheets, "Stylesheet not in scope - skipping for '\(element)'")
      return []
    }
    
    logDebug(.stylesheets, "Getting matching rulesets for '\(element)'")
    
    var matchingRulesets: [Ruleset] = []
    
    for ruleset in content.rulesets {
      if let matchingRuleset = ruleset.ruleset(matching: element, context: context) {
        logDebug(.stylesheets, "Matching rulesets: \(matchingRuleset)")
        matchingRulesets.append(matchingRuleset)
      }
    }
    
    return matchingRulesets
  }
  
  public func findRuleset(with selectorChain: SelectorChain) -> Ruleset? {
    return content.rulesets.first { $0.selectorChains.contains(selectorChain) }
  }
  
  open func unload() {}
}


/**
 * Represents a refreshable stylesheet.
 */
public class RefreshableStyleSheet: StyleSheet {
  public let refreshableResource: RefreshableResource
  
  required init(styleSheetURL: URL, name: String?, group groupName: String?, content: StyleSheetContent = .empty) {
    if styleSheetURL.isFileURL {
      refreshableResource = RefreshableLocalResource(withURL: styleSheetURL)
    } else {
      fatalError("Non-local refreshable stylesheets are not supported yet")
      //      refreshableResource = RefreshableRemoteResource(url: styleSheetURL)
    }
    super.init(styleSheetURL: styleSheetURL, name: name, group: groupName, content: content)
  }
  
  // MARK: - Properties
  
  override open var refreshable: Bool {
    return true
  }
  
  open var styleSheetModificationMonitoringSupported: Bool {
    return refreshableResource.resourceModificationMonitoringSupported
  }
  
  open var styleSheetModificationMonitoringEnabled: Bool {
    return refreshableResource.resourceModificationMonitoringEnabled
  }
  
  // MARK: - StyleSheet overrides
  
  override open func unload() {
    refreshableResource.endMonitoringResourceModification()
  }
  
  // MARK: - Refreshable stylesheet methods
  
  open func startMonitoringStyleSheetModification(_ modificationObserver: @escaping RefreshableStyleSheetObserverBlock) {
    weak var weakSelf: RefreshableStyleSheet? = self
    refreshableResource.startMonitoringResourceModification{ refreshableResource in
      guard let weakSelf = weakSelf else { return }
      modificationObserver(weakSelf)
    }
  }
  
  open func refreshStylesheet(with styleSheetManager: StyleSheetManager, andCompletionHandler completionHandler: @escaping () -> Void, force: Bool) {
    refreshableResource.refresh(intervalDuringError: styleSheetManager.stylesheetAutoRefreshInterval, force: force) { success, responseString, error in
      if success, let responseString = responseString {
        let t: TimeInterval = Date.timeIntervalSinceReferenceDate
        let styleSheetContent: StyleSheetContent? = styleSheetManager.styleSheetParser.parse(responseString)
        if let styleSheetContent = styleSheetContent {
          let hasRulesets: Bool = self.content.rulesets.count > 0
          self.content = styleSheetContent
          
          let parseTime = (Date.timeIntervalSinceReferenceDate - t)
          if hasRulesets {
            logDebug(.stylesheets, "Reloaded stylesheet '\(self.styleSheetURL.lastPathComponent)' in \(parseTime) seconds")
          } else {
            logDebug(.stylesheets, "Loaded stylesheet '\(self.styleSheetURL.lastPathComponent)' in \(parseTime) seconds")
          }
          
          completionHandler()
        } else {
          logDebug(.stylesheets, "Remote stylesheet didn't contain any rulesets!")
        }
        
        NotificationCenter.default.post(name: .StyleSheetRefreshedNotification, object: self)
      } else {
        NotificationCenter.default.post(name: .StyleSheetRefreshFailedNotification, object: self)
      }
    }
  }
}
