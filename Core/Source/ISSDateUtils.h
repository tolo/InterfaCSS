//
//  ISSDateUtils.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ISSDateUtils : NSObject

+ (nullable NSDate*) parseHttpDate:(NSString*)string;

+ (NSString*) formatHttpDate:(NSDate*)date;

@end


NS_ASSUME_NONNULL_END
