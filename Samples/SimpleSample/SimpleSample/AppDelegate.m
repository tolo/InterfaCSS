//
//  AppDelegate.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-24.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "AppDelegate.h"

#import <InterfaCSS.h>
#import <InterfaCSS/UIView+InterfaCSS.h>
#import <InterfaCSS/NSObject+ISSLogSupport.h>
#import "SimpleSampleViewController.h"
#import "PrototypeExampleViewController.h"

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // If you really want to get the log messages flowing, uncomment below:
    //[NSObject iss_setLogLevel:ISS_LOG_LEVEL_TRACE];
    
    [[InterfaCSS interfaCSS] loadStyleSheetFromMainBundleFile:@"constants.css"];
    [[InterfaCSS interfaCSS] loadStyleSheetFromMainBundleFile:@"main.css"];
    
    // When developing your app, consider using an auto refreshable stylesheet that is loaded from a web server (or perhaps a cloud service like Dropbox,
    // Sugarsync etc) or the local file system.
//#if DEBUG
//#if TARGET_IPHONE_SIMULATOR
//    [[InterfaCSS interfaCSS] loadRefreshableStyleSheetFromLocalFile:@"/Users/user/Documents/myprettystyles.css"];
//#else
//    [[InterfaCSS interfaCSS] loadRefreshableStyleSheetFromURL:[NSURL URLWithString:@"http://someserver/myprettystyles.css"]];
//#endif
//#endif
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    SimpleSampleViewController* viewController = [[SimpleSampleViewController alloc] init];
    PrototypeExampleViewController* prototypeExampleViewController = [[PrototypeExampleViewController alloc] init];
    
    UITabBarController* tabBarController = [[UITabBarController alloc] init];
    tabBarController.tabBar.translucent = NO;
    tabBarController.tabBar.styleClassISS = @"tabBarStyle1";
    tabBarController.viewControllers = @[viewController, prototypeExampleViewController];
    tabBarController.selectedIndex = 0;
    
    self.window.rootViewController = tabBarController;
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
