//
//  NotificationCenter+Additions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

internal extension Notification.Name {
  
  func observe(object: Any? = nil, using block: @escaping (Notification) -> Void) -> NotificationObserverToken {
    let token = NotificationCenter.default.addObserver(forName: self, object: object, queue: .main, using: block)
    return NotificationObserverToken(token: token)
  }
  
  func observe(object: Any? = nil, using block: @escaping () -> Void) -> NotificationObserverToken {
    return observe(object: object) { _ in block() }
  }
  
  func post(object: Any? = nil, userInfo: [AnyHashable : Any]? = nil) {
    NotificationCenter.default.post(name: self, object: object, userInfo: userInfo)
  }
  
}
