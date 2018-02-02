//
//  ISSUpdatableValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

#import "ISSNotificationObserver.h"

@class ISSNotificationObserver, ISSUpdatableValue;


NS_ASSUME_NONNULL_BEGIN


extern NSNotificationName const ISSUpdatableValueUpdatedNotification;



@interface ISSUpdatableValueObserver : ISSNotificationObserver

@property (nonatomic, weak, readonly, nullable) ISSUpdatableValue* value;

@end


@interface ISSUpdatableValue : NSObject

@property (nonatomic, weak, readonly, nullable) id lastValue;

- (void) requestUpdate;

- (ISSUpdatableValueObserver*) addValueUpdateObserverWithBlock:(void (^)(NSNotification* note))block;

- (void) valueUpdated;

@end


NS_ASSUME_NONNULL_END
