//
//  ISSSelectorChain.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@class ISSSelector;
@class ISSUIElementDetails;
@class ISSStylingContext;


@interface ISSSelectorChain : NSObject<NSCopying>

@property (nonatomic, readonly) NSArray* selectorComponents;
@property (nonatomic, readonly) NSString* displayDescription;
@property (nonatomic, readonly) BOOL hasPseudoClassSelector;
@property (nonatomic, readonly) NSUInteger specificity;

+ (instancetype) selectorChainWithSelector:(ISSSelector*)selector;
+ (instancetype) selectorChainWithComponents:(NSArray*)selectorComponents;

- (ISSSelectorChain*) selectorChainByAddingDescendantSelector:(ISSSelector*)selector;
- (ISSSelectorChain*) selectorChainByAddingDescendantSelectorChain:(ISSSelectorChain*)selectorChain;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

@end
