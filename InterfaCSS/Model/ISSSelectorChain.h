//
//  ISSSelectorChain.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-03-02.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@class ISSSelector;

@interface ISSSelectorChain : NSObject<NSCopying>

@property (nonatomic, readonly) NSArray* selectorComponents;
@property (nonatomic, readonly) NSString* displayDescription;

- (id) initWithComponents:(NSArray*)components;
- (ISSSelectorChain*) selectorChainByAddingSelector:(ISSSelector*)selector;
- (ISSSelectorChain*) selectorChainByAddingSelectorChain:(ISSSelectorChain*)selectorChain;

- (BOOL) matchesView:(id)view;

@end
