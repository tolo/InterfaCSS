//
//  InterfaCSS
//  NSAttributedString+ISSAdditions.m
//  
//  Created by Tobias Löfstrand on 12/06/14.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//


#import "NSAttributedString+ISSAdditions.h"


@implementation NSAttributedString (ISSAdditions)

- (BOOL) iss_hasAttributes {
    __block BOOL hasAttributes = NO;
    [self enumerateAttributesInRange:NSMakeRange(0, self.length) options:0 usingBlock:^(NSDictionary* attrs, NSRange range, BOOL* stop) {
        if( attrs.count > 0 ) {
            hasAttributes = YES;
            *stop = YES;
        }
    }];
    return hasAttributes;
}

@end
