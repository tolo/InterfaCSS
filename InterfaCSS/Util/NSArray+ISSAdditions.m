//
//  NSArray+ISSAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "NSArray+ISSAdditions.h"

#import "NSString+ISSStringAdditions.h"

static NSArray* flattenArray(NSArray* array) {
    NSMutableArray* flattened = [NSMutableArray array];
    for(id e in array) {
        if( [e isKindOfClass:NSArray.class] ) {
            [flattened addObjectsFromArray:flattenArray(e)];
        } else if( e != [NSNull null] ) {
            [flattened addObject:e];
        }
    }
    return [flattened copy];
}


@implementation NSArray (ISSAdditions)

- (NSArray*) iss_flattened {
    return flattenArray(self);
}

@end
