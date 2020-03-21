//
//  NotificationObserverToken.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

public final class NotificationObserverToken {

  public private (set) var token: NSObjectProtocol?
  
  init(token: NSObjectProtocol) {
    self.token = token
  }
  
  deinit {
    if let token = token {
      NotificationCenter.default.removeObserver(token)
    }
  }
  
  func removeObserver() {
    if let token = token {
      NotificationCenter.default.removeObserver(token)
    }
    token = nil
  }
}
