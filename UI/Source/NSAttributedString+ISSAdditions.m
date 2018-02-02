//
//  NSAttributedString+ISSAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
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
