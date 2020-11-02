//
//  NotificationObserverToken.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation


public final class NotificationObserverToken {

  public private (set) var token: NSObjectProtocol?
  
  init(token: NSObjectProtocol) {
    self.token = token
  }
  
  deinit {
    removeObserer(token)
  }
  
  func removeObserver() {
    removeObserer(token)
    token = nil
  }
  
  func disposedBy(_ bag: NotificationObserverTokenBag) {
    bag.add(self)
  }
}


public final class NotificationObserverTokenBag {
  
  private var tokens: [NotificationObserverToken] = []
  
  func add(_ token: NotificationObserverToken) {
    tokens.append(token)
  }
  
  deinit {
    tokens.forEach { $0.removeObserver() }
  }
  
  func removeObservers() {
    tokens.forEach { $0.removeObserver() }
    tokens = []
  }
}


fileprivate func removeObserer(_ token: NSObjectProtocol?) {
  if let token = token {
    NotificationCenter.default.removeObserver(token)
  }
}
