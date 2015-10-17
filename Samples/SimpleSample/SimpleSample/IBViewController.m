//
//  IBViewController.m
//  SimpleSample
//
//  Created by PMB on 2015-10-17.
//  Copyright © 2015 Leafnode AB. All rights reserved.
//

#import "IBViewController.h"

#import <InterfaCSS/ISSStyleSheet.h>

@implementation IBViewController

- (instancetype) initWithNibName:(NSString*)nibNameOrNil bundle:(NSBundle*)nibBundleOrNil {
    if( [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] ) {
        self.title = @"iBuilder";
        
        // To prevent a lot of up front loading when application starts, loading of a stylesheet can be postponed until it's actually needed.
        // Additionally, a scope can be attached to the stylesheet, to limit styles to only be processed while in a particular view controller for instance
        ISSStyleSheetScope* scope = [ISSStyleSheetScope scopeWithViewControllerClass:self.class];
        [[InterfaCSS interfaCSS] loadStyleSheetFromMainBundleFile:@"IBViewController.css" withScope:scope];
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    
}

@end
