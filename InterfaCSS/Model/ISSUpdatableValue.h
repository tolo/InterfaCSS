//
//  ISSUpdatableValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


extern NSString* const ISSUpdatableValueUpdatedNotification;


@interface ISSUpdatableValue : NSObject

@property (nonatomic, weak, readonly, nullable) id lastValue;

- (void) requestUpdate;

- (void) addValueUpdateObserver:(id)observer selector:(SEL)selector;
- (void) removeValueUpdateObserver:(id)observer;

- (void) valueUpdated;

@end


NS_ASSUME_NONNULL_END
