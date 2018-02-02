//
//  UIDevice+ISSAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "UIDevice+ISSAdditions.h"
#import "NSObject+ISSLogSupport.h"

#include <sys/sysctl.h>
#include <mach/mach.h>
#include <sys/types.h>


static NSString* cachedDeviceModelId;


@implementation UIDevice (ISSAdditions)

+ (NSString*) iss_loadDeviceModelId {
    @try {
        int mib[2];

        mib[0] = CTL_HW;
        mib[1] = HW_MACHINE;
        size_t len;
        sysctl(mib, 2, NULL, &len, NULL, 0);
        char* machine = malloc(len);
        if( machine ) {
            sysctl(mib, 2, machine, &len, NULL, 0);
            NSString* platform = @(machine);
            free(machine);
            return platform;
        } else {
            ISSLogWarning(@"Unable to load device model ID (unable to allocate memory)!");
        }
    } @catch (NSException* exception) {
        ISSLogWarning(@"Unable to load device model ID (%@)!", exception);
    }
    return @"<unknown>";
}

+ (void) load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cachedDeviceModelId = [[self iss_loadDeviceModelId] lowercaseString];
    });
}

+ (NSString*) iss_deviceModelId {
    return cachedDeviceModelId;
}

+ (BOOL) iss_versionGreaterOrEqualTo:(NSString*)version {
	NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
    return [systemVersion compare:version options:NSNumericSearch] != NSOrderedAscending;
}

+ (BOOL) iss_versionLessOrEqualTo:(NSString*)version {
	NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
    return [systemVersion compare:version options:NSNumericSearch] != NSOrderedDescending;
}

@end