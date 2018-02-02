//
//  NSArray+ISSAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "NSArray+ISSAdditions.h"


static NSArray* flattenArray(NSArray* array) {
    NSMutableArray* flattened = [NSMutableArray array];
    for(id e in array) {
        if( [e isKindOfClass:NSArray.class] ) {
            [flattened addObjectsFromArray:flattenArray(e)];
        } else if( e != [NSNull null] ) {
            [flattened addObject:e];
        }
    }
    return flattened;
}


@implementation NSArray (GSSAdditions)

- (NSArray*) uss_flattened {
    return flattenArray(self);
}

@end


@implementation NSMutableArray (ISSAdditions)

- (void) iss_addAndReplaceUniqueObjectsInArray:(NSArray*)array {
    for(id element in array) {
        [self removeObject:element];
        [self addObject:element];
    }
}

@end
