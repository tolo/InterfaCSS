//
//  NSArray+ISSAdditions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@interface NSMutableArray (ISSAdditions)

- (void) iss_addAndReplaceUniqueObjectsInArray:(NSArray*)array;

@end