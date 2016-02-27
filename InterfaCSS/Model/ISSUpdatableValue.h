//
//  ISSUpdatableValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
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
