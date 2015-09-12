//
// Created by Tobias Löfstrand on 15-09-11.
// Copyright (c) 2015 Leafnode AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UIDevice (ISSAdditions)

+ (NSString*) iss_deviceModelId;

+ (BOOL) iss_versionGreaterOrEqualTo:(NSString*)version;

+ (BOOL) iss_versionLessOrEqualTo:(NSString*)version;

@end
