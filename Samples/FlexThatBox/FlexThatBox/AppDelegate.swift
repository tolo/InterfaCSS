//
//  AppDelegate.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit
import InterfaCSS

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // If you have styles that are shared throught the app (which you most likely do), a good place to load these are here
    // StylingManager.shared().loadStyleSheet(fromRefreshableProjectFile: "common.css", relativeToDirectoryContaining: #file)
    
    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = UINavigationController(rootViewController: MainViewController())
    window?.backgroundColor = .white
    window?.makeKeyAndVisible()

    return true
  }
}
