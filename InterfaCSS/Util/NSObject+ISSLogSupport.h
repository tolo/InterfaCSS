//
//  NSObject+ISSLogSupport.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2010-10-20
//  Copyright (c) 2010 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

#define ISS_LOG_LEVEL_NONE      0
#define ISS_LOG_LEVEL_WARNING   1
#define ISS_LOG_LEVEL_DEBUG     2
#define ISS_LOG_LEVEL_TRACE     3

#define ISSLogTrace(__FORMAT__, ...) [self iss_logTrace:__FORMAT__, ##__VA_ARGS__]
#define ISSLogDebug(__FORMAT__, ...) [self iss_logDebug:__FORMAT__, ##__VA_ARGS__]
#define ISSLogWarning(__FORMAT__, ...) [self iss_logWarning:__FORMAT__, ##__VA_ARGS__]

@interface NSObject (ISSLogSupport)

/**
 * Sets the logging level for InterfaCSS - valid values are ISS_LOG_LEVEL_NONE, ISS_LOG_LEVEL_WARNING, ISS_LOG_LEVEL_DEBUG and ISS_LOG_LEVEL_TRACE.
 */
+ (void) iss_setLogLevel:(NSInteger)logLevel;

- (void) iss_logTrace:(NSString*)format, ...;
- (void) iss_logDebug:(NSString*)format, ...;
- (void) iss_logWarning:(NSString*)format, ...;

@end
