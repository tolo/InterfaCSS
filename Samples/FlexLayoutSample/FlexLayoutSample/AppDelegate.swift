//
//  AppDelegate.swift
//  FlexLayoutSample
//
//  Created by PMB on 2018-11-23.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
      window = UIWindow(frame: UIScreen.main.bounds)
      window?.rootViewController = UINavigationController(rootViewController: MainViewController())
      window?.backgroundColor = .white
      window?.makeKeyAndVisible()

      return true
  }
}

