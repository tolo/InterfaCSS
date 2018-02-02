//
//  ISSNotificationObserver.h
//  InterfaCSS
//
//  Created by PMB on 2018-02-01.
//  Copyright © 2018 Leafnode AB. All rights reserved.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


@interface ISSNotificationObserver : NSObject

@property (nonatomic, strong, nullable) id<NSObject> observer;

- (instancetype) initWithObserver:(id<NSObject>)observer;

- (void) removeObserver;

@end


NS_ASSUME_NONNULL_END
