//
//  ISSUpdatableValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
// Created by PMB on 2015-09-14.
// Copyright (c) 2015 Leafnode AB. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString* const ISSUpdatableValueUpdatedNotification;


@interface ISSUpdatableValue : NSObject

@property (nonatomic, weak, readonly) id lastValue;

- (void) requestUpdate;

- (void) addValueUpdateObserver:(id)observer selector:(SEL)selector;
- (void) removeValueUpdateObserver:(id)observer;

- (void) valueUpdated;

@end
