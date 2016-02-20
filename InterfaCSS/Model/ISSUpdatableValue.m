//
//  ISSUpdatableValue.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
// Created by PMB on 2015-09-14.
// Copyright (c) 2015 Leafnode AB. All rights reserved.
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
