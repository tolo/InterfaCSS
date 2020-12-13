//
//  StyleSheetScope.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


public enum StyleSheetScope: Hashable {
  case all
  case global
  case names([String], includingGlobal: Bool = true)
  case groups([String], includingGlobal: Bool = true)
  
  public func matches(styleSheet: StyleSheet) -> Bool {
    switch self {
      case .all: return true
      case .global: return styleSheet.group == nil
      case .names(let names, let includingGlobal): return names.contains(styleSheet.name) || (includingGlobal && styleSheet.group == nil)
      case .groups(let groups, let includingGlobal): return groups.contains(styleSheet.group ?? "") || (includingGlobal && styleSheet.group == nil)
    }
  }
  
  public static func using(name: String, includingGlobal: Bool = true) -> StyleSheetScope {
    .names([name], includingGlobal: includingGlobal)
  }
  
  public static func using(group: String, includingGlobal: Bool = true) -> StyleSheetScope {
    .groups([group], includingGlobal: includingGlobal)
  }
}

//public enum StyleSheetScope: Hashable {
//  case all
//  case defaultScope
//  case groups([String])
//  case defaultAndGroups([String])
//
//  public func matches(styleSheet: StyleSheet) -> Bool {
//    switch self {
//      case .all: return true
//      case .defaultScope: styleSheet.scopeName == nil
//      case .groups(let names): names.contains(styleSheet.scopeName)
//      default:
//        <#code#>
//    }
//  }
//}

/**
 * Class representing a scope used for limiting which stylesheets should be used for styling.
 */
/*struct StyleSheetScope: Hashable {
  public static let defaultGroupScope: StyleSheetScope = {
    StyleSheetScope(matcher: { styleSheet in
      return styleSheet.group == StyleSheetGroupDefault
    })
  }()
  
  public static func defaultGroupScope(includingStyleSheetNames names: [String]) -> StyleSheetScope {
    return StyleSheetScope.defaultGroupScope.including(StyleSheetScope(styleSheetNames: names))
  }
  
  private let groups: [String]
  
  public init(styleSheetGroup group: String) {
    self.init(styleSheetGroups: [group])
  }
  
  public init(defaultStyleSheetGroupAndGroups groups: [String]) {
    self.init(styleSheetGroups: groups + [StyleSheetGroupDefault])
  }
  
  public init(styleSheetGroups groups: [String]) {
    let groupsSet = Set<AnyHashable>(groups)
    self.init(matcher: { styleSheet in
      return groupsSet.contains(styleSheet.group ?? "")
    })
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
*/
