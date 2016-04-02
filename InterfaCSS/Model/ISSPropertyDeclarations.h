//
//  ISSPropertyDeclarations.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@class ISSUIElementDetails;
@class ISSStylingContext;
@class ISSStyleSheetScope;


/**
 * Represents a declaration block (or rule set) in a stylesheet.
 */
@interface ISSPropertyDeclarations : NSObject

@property (nonatomic, readonly) NSArray* selectorChains;
@property (nonatomic, readonly) NSArray* properties;
@property (nonatomic, readonly) NSString* displayDescription;
@property (nonatomic, readonly) BOOL containsPseudoClassSelector;
@property (nonatomic, readonly) BOOL containsPseudoClassSelectorOrDynamicProperties;
@property (nonatomic, readonly) NSUInteger specificity;

@property (nonatomic, weak) ISSStyleSheetScope* scope; // The scope used by the parent stylesheet...

- (id) initWithSelectorChains:(NSArray*)selectorChains andProperties:(NSArray*)properties;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;
- (ISSPropertyDeclarations*) propertyDeclarationsMatchingElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

- (NSString*) displayDescription:(BOOL)withProperties;

@end
