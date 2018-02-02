//
//  ISSUpdatableValue.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSUpdatableValue.h"

#import "ISSNotificationObserver.h"


NSNotificationName const ISSUpdatableValueUpdatedNotification = @"ISSUpdatableValueUpdatedNotification";


@implementation ISSUpdatableValueObserver

- (instancetype) initWithValue:(ISSUpdatableValue*)value observer:(id<NSObject>)observer {
    if (self = [super initWithObserver:observer]) {
        _value = value;
    }
    return self;
}

- (void) removeObserver {
    _value = nil;
    [super removeObserver];
}

@end


@implementation ISSUpdatableValue

- (void) requestUpdate {}

- (ISSUpdatableValueObserver*) addValueUpdateObserverWithBlock:(void (^)(NSNotification* note))block {
    id<NSObject> observer = [[NSNotificationCenter defaultCenter] addObserverForName:ISSUpdatableValueUpdatedNotification object:self queue:nil usingBlock:block];
    return [[ISSUpdatableValueObserver alloc] initWithValue:self observer:observer];
}

- (void) valueUpdated {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSUpdatableValueUpdatedNotification object:self];
}

@end
