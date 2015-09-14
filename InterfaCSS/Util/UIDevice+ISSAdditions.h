//
//  UIDevice+ISSAdditions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2015-09-11.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface UIDevice (ISSAdditions)

+ (NSString*) iss_deviceModelId;

+ (BOOL) iss_versionGreaterOrEqualTo:(NSString*)version;

+ (BOOL) iss_versionLessOrEqualTo:(NSString*)version;

@end
