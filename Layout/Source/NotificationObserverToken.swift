
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
