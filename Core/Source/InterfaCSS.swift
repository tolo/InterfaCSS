//
//  InterfaCSS.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


public struct InterfaCSS {
  
  public static let ShouldClearAllCachedStylingInformation = Notification.Name("InterfaCSS.ShouldClearAllCachedStylingInformation")
  
  public static let WillRefreshStyleSheetsNotification = Notification.Name("InterfaCSS.WillRefreshStyleSheetsNotification")
  public static let DidRefreshStyleSheetNotification = Notification.Name("InterfaCSS.DidRefreshStyleSheetNotification")
  
  static let StyleSheetRefreshedNotification = Notification.Name("InterfaCSS.StyleSheetRefreshedNotification")
  static let StyleSheetRefreshFailedNotification = Notification.Name("InterfaCSS.StyleSheetRefreshFailedNotification")
  
  static let MarkCachedStylingInformationAsDirtyNotification = NSNotification.Name("InterfaCSS.MarkCachedStylingInformationAsDirtyNotification")
}

