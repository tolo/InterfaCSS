//
//  NSArray+ISSAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "NSArray+ISSAdditions.h"

#import "NSString+ISSAdditions.h"

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

- (NSArray*) iss_trimStringElements {
    NSMutableArray* trimmed = [NSMutableArray array];
    for(id e in self) {
        if( [e isKindOfClass:NSString.class] ) {
            [trimmed addObject:[e iss_trim]];
        }
        [trimmed addObject:e];
    }
    return [trimmed copy];
}

- (NSArray*) iss_map:(id (^)(id element))mapFunc {
    NSMutableArray* mapped = [NSMutableArray array];
    for(id e in self) {
        [mapped addObject:mapFunc(e)];
    }
    return [mapped copy];
}

- (NSArray*) iss_filter:(BOOL (^)(id element))filterFunc {
    NSMutableArray* filtered = [NSMutableArray array];
    for(id e in self) {
        if( filterFunc(e) ) [filtered addObject:e];
    }
    return [filtered copy];
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
