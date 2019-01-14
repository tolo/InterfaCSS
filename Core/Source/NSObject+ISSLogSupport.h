//
//  NSObject+ISSLogSupport.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ISSLogLevel) {
    ISSLogLevelNone = 0,
    ISSLogLevelWarning = 1,
    ISSLogLevelDebug = 2,
    ISSLogLevelTrace = 3
} NS_SWIFT_NAME(LogLevel);

#define ISSLogTrace(__FORMAT__, ...) [self iss_logTrace:__FORMAT__, ##__VA_ARGS__]
#define ISSLogDebug(__FORMAT__, ...) [self iss_logDebug:__FORMAT__, ##__VA_ARGS__]
#define ISSLogWarning(__FORMAT__, ...) [self iss_logWarning:__FORMAT__, ##__VA_ARGS__]

@interface NSObject (ISSLogSupport)

/**
 * Sets the logging level for InterfaCSS - valid values are ISS_LOG_LEVEL_NONE, ISS_LOG_LEVEL_WARNING, ISS_LOG_LEVEL_DEBUG and ISS_LOG_LEVEL_TRACE.
 */
+ (void) iss_setLogLevel:(ISSLogLevel)logLevel NS_SWIFT_NAME(setLogLevel(_:));

- (void) iss_logTrace:(NSString*)format, ...;
- (void) iss_logTraceMessage:(NSString*)message NS_SWIFT_NAME(logTrace(message:));
- (void) iss_logDebug:(NSString*)format, ...;
- (void) iss_logDebugMessage:(NSString*)message NS_SWIFT_NAME(logDebug(message:));
- (void) iss_logWarning:(NSString*)format, ...;
- (void) iss_logWarningMessage:(NSString*)message NS_SWIFT_NAME(logWarning(message:));

@end

NS_ASSUME_NONNULL_END
