//
//  ISSNotificationObserver.m
//  InterfaCSS
//
//  Created by PMB on 2018-02-01.
//  Copyright © 2018 Leafnode AB. All rights reserved.
//

#import "ISSNotificationObserver.h"

@implementation ISSNotificationObserver

- (instancetype) initWithObserver:(id<NSObject>)observer {
    if (self = [super init]) {
        _observer = observer;
    }
    return self;
}

- (void) removeObserver {
    if (self.observer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.observer];
    }
    self.observer = nil;
}

- (void) dealloc {
    if (self.observer) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.observer];
    }
}

@end
