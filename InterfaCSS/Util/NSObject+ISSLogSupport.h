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

#ifndef ISS_LOG_LEVEL
    #if DEBUG == 1
        #define ISS_LOG_LEVEL ISS_LOG_LEVEL_DEBUG
    #else
        #define ISS_LOG_LEVEL ISS_LOG_LEVEL_WARNING
    #endif
#endif

#define ISSLogTrace(__FORMAT__, ...) [self ISSLogTrace:__FORMAT__, ##__VA_ARGS__]
#define ISSLogDebug(__FORMAT__, ...) [self ISSLogDebug:__FORMAT__, ##__VA_ARGS__]
#define ISSLogWarning(__FORMAT__, ...) [self ISSLogWarning:__FORMAT__, ##__VA_ARGS__]

@interface NSObject (ISSLogSupport)

- (void) ISSLogTrace:(NSString*)format, ...;
- (void) ISSLogDebug:(NSString*)format, ...;
- (void) ISSLogWarning:(NSString*)format, ...;

@end
