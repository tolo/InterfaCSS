//
//  ISSUpdatableValue.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSUpdatableValue.h"


NSString* const ISSUpdatableValueUpdatedNotification = @"ISSUpdatableValueUpdatedNotification";


@implementation ISSUpdatableValue

- (void) requestUpdate {}

- (void) addValueUpdateObserver:(id)observer selector:(SEL)selector {
    [[NSNotificationCenter defaultCenter] addObserver:observer selector:selector name:ISSUpdatableValueUpdatedNotification object:self];
}

- (void) removeValueUpdateObserver:(id)observer {
    [[NSNotificationCenter defaultCenter] removeObserver:observer name:ISSUpdatableValueUpdatedNotification object:self];
}

- (void) valueUpdated {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSUpdatableValueUpdatedNotification object:self];
}

@end
