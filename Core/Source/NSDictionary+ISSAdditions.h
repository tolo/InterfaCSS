//
//  NSDictionary+ISSDictionaryAdditions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (ISSDictionaryAdditions)

- (NSDictionary*) iss_dictionaryWithLowerCaseKeys;

- (NSDictionary*) iss_dictionaryByAddingValue:(id)value forKey:(id)key;

@end

NS_ASSUME_NONNULL_END
