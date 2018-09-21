//
//  NSDictionary+ISSDictionaryAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "NSDictionary+ISSAdditions.h"

@implementation NSDictionary (ISSDictionaryAdditions)

- (NSDictionary*) iss_dictionaryWithLowerCaseKeys {
    NSMutableDictionary* result = [[NSMutableDictionary alloc] initWithCapacity:self.count];
    [self enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL* stop) {
        result[[key lowercaseString]] = obj;
    }];
    return result;
}

- (NSDictionary*) iss_dictionaryByAddingValue:(id)value forKey:(NSString*)key {
    NSMutableDictionary* dict = [self mutableCopy];
    dict[key] = value;
    return [dict copy];
}

@end
