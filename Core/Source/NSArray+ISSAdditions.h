//
//  NSArray+ISSAdditions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (ISSAdditions)

- (NSArray*) iss_flattened;

- (NSArray*) iss_trimStringElements;

- (NSArray*) iss_map:(id (^)(id element))mapFunc;

- (NSArray*) iss_filter:(BOOL (^)(id element))filterFunc;

@end

@interface NSMutableArray (ISSAdditions)

- (void) iss_addAndReplaceUniqueObjectsInArray:(NSArray*)array;

@end

NS_ASSUME_NONNULL_END
