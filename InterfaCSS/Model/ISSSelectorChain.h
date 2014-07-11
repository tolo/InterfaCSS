//
//  ISSSelectorChain.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-03-02.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@class ISSSelector;
@class ISSUIElementDetails;

@interface ISSSelectorChain : NSObject<NSCopying>

@property (nonatomic, readonly) NSArray* selectorComponents;
@property (nonatomic, readonly) NSString* displayDescription;
@property (nonatomic, readonly) BOOL hasPseudoClassSelector;

+ (instancetype) selectorChainWithComponents:(NSArray*)selectorComponents;

- (ISSSelectorChain*) selectorChainByAddingDescendantSelector:(ISSSelector*)selector;
- (ISSSelectorChain*) selectorChainByAddingDescendantSelectorChain:(ISSSelectorChain*)selectorChain;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails ignoringPseudoClasses:(BOOL)ignorePseudoClasses;

@end
