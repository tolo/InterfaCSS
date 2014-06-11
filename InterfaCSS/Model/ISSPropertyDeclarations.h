//
//  ISSPropertyDeclarations.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@class ISSUIElementDetails;

/**
 * Represents a declaration block (or rule set) in a stylesheet.
 */
@interface ISSPropertyDeclarations : NSObject

@property (nonatomic, readonly) NSArray* selectorChains;
@property (nonatomic, readonly) NSArray* properties;
@property (nonatomic, readonly) NSString* displayDescription;

- (id) initWithSelectorChains:(NSArray*)selectorChains andProperties:(NSArray*)properties;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails;

- (NSString*) displayDescription:(BOOL)withProperties;

@end
