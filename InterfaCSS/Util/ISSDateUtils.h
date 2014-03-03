//
//  ISSDateUtils.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-01-14.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>


@interface ISSDateUtils : NSObject

+ (NSDate*) parseHttpDate:(NSString*)string;

+ (NSString*) formatHttpDate:(NSDate*)date;

@end
