//
//  NSDictionary+ISSDictionaryAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2013-04-01.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//


#import "NSDictionary+ISSDictionaryAdditions.h"

@implementation NSDictionary (ISSDictionaryAdditions)

- (NSDictionary*) iss_dictionaryWithLowerCaseKeys {
    NSMutableDictionary* result = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        result[[key lowercaseString]] = obj;
    }];
    return result;
}

@end