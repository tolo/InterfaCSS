//
//  AppDelegate.swift
//  ISSLayout
//
//  Created by Tobias Löfstrand on 2015-05-01.
//  Copyright (c) 2015 Leafnode. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        let iss:InterfaCSS = InterfaCSS.sharedInstance()
        
        iss.loadStyleSheetFromMainBundleFile("styles.css")
        
        let mainWindow = UIWindow(frame: UIScreen.mainScreen().bounds)
        mainWindow.rootViewController = ViewController()
        mainWindow.makeKeyAndVisible()
        
        window = mainWindow
        
        return true
    }
}
