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
@class ISSSelectorChain;

NS_ASSUME_NONNULL_BEGIN


/**
 * Represents a declaration block (or rule set) in a stylesheet.
 */
@interface ISSPropertyDeclarations : NSObject

@property (nonatomic, readonly, nullable) ISSSelectorChain* extendedDeclarationSelectorChain;
@property (nonatomic, weak, nullable) ISSPropertyDeclarations* extendedDeclaration;

@property (nonatomic, readonly) NSArray* selectorChains;
@property (nonatomic, readonly, nullable) NSArray* properties;
@property (nonatomic, readonly) NSString* displayDescription;
@property (nonatomic, readonly) BOOL containsPseudoClassSelector;
@property (nonatomic, readonly) BOOL containsPseudoClassSelectorOrDynamicProperties;
@property (nonatomic, readonly) NSUInteger specificity;

@property (nonatomic, weak) ISSStyleSheetScope* scope; // The scope used by the parent stylesheet...

- (id) initWithSelectorChains:(NSArray*)selectorChains andProperties:(nullable NSArray*)properties;
- (id) initWithSelectorChains:(NSArray*)selectorChains andProperties:(nullable NSArray*)properties extendedDeclarationSelectorChain:(nullable ISSSelectorChain*)extendedDeclarationSelectorChain;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;
- (ISSPropertyDeclarations*) propertyDeclarationsMatchingElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

- (BOOL) containsSelectorChain:(ISSSelectorChain*)selectorChain;

- (NSString*) displayDescription:(BOOL)withProperties;

@end


NS_ASSUME_NONNULL_END
