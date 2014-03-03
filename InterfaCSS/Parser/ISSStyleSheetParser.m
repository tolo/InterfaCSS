//
//  ISSStyleSheetParser.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-10.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSStyleSheetParser.h"

@implementation ISSStyleSheetParser

#pragma mark - ISStyleSheetParser interface (subclass) methods

- (NSMutableArray*) parse:(NSString*)styleSheetData {
    [NSException raise:NSInvalidArgumentException format:@"Method %s must be implemented by subclass.", __PRETTY_FUNCTION__];
    return nil;
}

@end
