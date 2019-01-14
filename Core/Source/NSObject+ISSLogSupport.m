//
//  NSObject+ISSLogSupport.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "NSObject+ISSLogSupport.h"

static ISSLogLevel issLogLevel;

@implementation NSObject (ISSLogSupport)

+ (void) load {
#if DEBUG == 1
    [self iss_setLogLevel:ISSLogLevelDebug];
#else
    [self iss_setLogLevel:ISSLogLevelWarning];
#endif
}

+ (void) iss_setLogLevel:(ISSLogLevel)logLevel {
    issLogLevel = logLevel;
}

- (void) iss_log:(NSString*)level format:(NSString*)format withParameters:(va_list)vl {
    NSString* logMessage = [[NSString alloc] initWithFormat:format arguments:vl];
    NSLog(@"%@InterfaCSS: %@ - %@", level, self, logMessage);
}

- (void) iss_logTrace:(NSString*)format, ... {
    if( issLogLevel >= ISSLogLevelTrace ) {
        va_list vl;
        va_start(vl, format);
        [self iss_log:@"[TRACE] " format:format withParameters:vl];
        va_end(vl);
    }
}

- (void) iss_logTraceMessage:(NSString*)logMessage {
    if( issLogLevel >= ISSLogLevelTrace ) {
        NSLog(@"[TRACE] InterfaCSS: %@ - %@", self, logMessage);
    }
}

- (void) iss_logDebug:(NSString*)format, ... {
    if( issLogLevel >= ISSLogLevelDebug ) {
        va_list vl;
        va_start(vl, format);
        [self iss_log:@"[DEBUG] " format:format withParameters:vl];
        va_end(vl);
    }
}

- (void) iss_logDebugMessage:(NSString*)logMessage {
    if( issLogLevel >= ISSLogLevelDebug ) {
        NSLog(@"[DEBUG] InterfaCSS: %@ - %@", self, logMessage);
    }
}

- (void) iss_logWarning:(NSString*)format, ... {
    if( issLogLevel >= ISSLogLevelWarning ) {
        va_list vl;
        va_start(vl, format);
        [self iss_log:@"[WARNING] " format:format withParameters:vl];
        va_end(vl);
    }
}

- (void) iss_logWarningMessage:(NSString*)logMessage {
    if( issLogLevel >= ISSLogLevelWarning ) {
        NSLog(@"[WARNING] InterfaCSS: %@ - %@", self, logMessage);
    }
}

@end
