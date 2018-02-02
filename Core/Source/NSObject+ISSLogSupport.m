//
//  NSObject+ISSLogSupport.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "NSObject+ISSLogSupport.h"

static NSInteger ISSLogLevel;

@implementation NSObject (ISSLogSupport)

+ (void) load {
#if DEBUG == 1
    [self iss_setLogLevel:ISS_LOG_LEVEL_DEBUG];
#else
    [self iss_setLogLevel:ISS_LOG_LEVEL_WARNING];
#endif
}

+ (void) iss_setLogLevel:(NSInteger)logLevel {
    ISSLogLevel = logLevel;
}

- (void) iss_log:(NSString*)level format:(NSString*)format withParameters:(va_list)vl {
    NSString* logMessage = [[NSString alloc] initWithFormat:format arguments:vl];
    NSLog(@"%@InterfaCSS: %@ - %@", level, self, logMessage);
}

- (void) iss_logTrace:(NSString*)format, ... {
    if( ISSLogLevel >= ISS_LOG_LEVEL_TRACE ) {
        va_list vl;
        va_start(vl, format);
        [self iss_log:@"[TRACE] " format:format withParameters:vl];
        va_end(vl);
    }
}

- (void) iss_logDebug:(NSString*)format, ... {
    if( ISSLogLevel >= ISS_LOG_LEVEL_DEBUG ) {
        va_list vl;
        va_start(vl, format);
        [self iss_log:@"[DEBUG] " format:format withParameters:vl];
        va_end(vl);
    }
}

- (void) iss_logWarning:(NSString*)format, ... {
    if( ISSLogLevel >= ISS_LOG_LEVEL_WARNING ) {
        va_list vl;
        va_start(vl, format);
        [self iss_log:@"[WARNING] " format:format withParameters:vl];
        va_end(vl);
    }
}

@end
