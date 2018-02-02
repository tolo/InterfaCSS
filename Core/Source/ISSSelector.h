//
//  ISSSelector.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@class ISSPseudoClass;
@class ISSElementStylingProxy;
@class ISSStylingContext;


typedef NS_ENUM(NSInteger, ISSSelectorCombinator) {
    ISSSelectorCombinatorDescendant,
    ISSSelectorCombinatorChild,
    ISSSelectorCombinatorAdjacentSibling,
    ISSSelectorCombinatorGeneralSibling,
};

@interface ISSSelector : NSObject<NSCopying>

@property (nonatomic, readonly, nullable) Class type;
@property (nonatomic, readonly, nullable) NSString* elementId;
@property (nonatomic, readonly, nullable) NSString* styleClass; // Convenience property for dealing with selectors with only a single style class (returns the first style class if more than one are set)
@property (nonatomic, readonly, nullable) NSArray<NSString*>* styleClasses;
@property (nonatomic, readonly, nullable) NSArray<ISSPseudoClass*>* pseudoClasses;

@property (nonatomic, readonly) NSUInteger specificity;

@property (nonatomic, readonly) NSString* displayDescription;


- (instancetype) initWithType:(nullable Class)type elementId:(nullable NSString*)elementId styleClasses:(nullable NSArray*)styleClasses pseudoClasses:(nullable NSArray*)pseudoClasses;
- (instancetype) initWithWildcardTypeAndElementId:(nullable NSString*)elementId styleClasses:(nullable NSArray*)styleClasses pseudoClasses:(nullable NSArray*)pseudoClasses;


- (BOOL) matchesElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

@end


NS_ASSUME_NONNULL_END
