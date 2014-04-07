//
//  NSObject+ISSLogSupport.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2010-10-20
//  Copyright (c) 2010 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "NSObject+ISSLogSupport.h"

@implementation NSObject (ISSLogSupport)

- (void) iss_log:(NSString*)level format:(NSString*)format withParameters:(va_list)vl {
    NSString* logMessage = [[NSString alloc] initWithFormat:format arguments:vl];
    NSLog(@"%@InterfaCSS.%@ - %@", level, self, logMessage);
}

- (void) iss_logTrace:(NSString*)format, ... {
#if ISS_LOG_LEVEL >= ISS_LOG_LEVEL_TRACE
    va_list vl;
    va_start(vl, format);
    [self iss_log:@"[TRACE] " format:format withParameters:vl];
    va_end(vl);
#endif
}

- (void) iss_logDebug:(NSString*)format, ... {
#if ISS_LOG_LEVEL >= ISS_LOG_LEVEL_DEBUG
    va_list vl;
    va_start(vl, format);
    [self iss_log:@"[DEBUG] " format:format withParameters:vl];
    va_end(vl);
#endif
}

- (void) iss_logWarning:(NSString*)format, ... {
#if ISS_LOG_LEVEL >= ISS_LOG_LEVEL_WARNING
    va_list vl;
    va_start(vl, format);
    [self iss_log:@"[WARNING] " format:format withParameters:vl];
    va_end(vl);
#endif
}

@end
