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
@class ISSUIElementDetails;
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
@property (nonatomic, readonly, nullable) NSString* styleClass; // Returns the first style class
@property (nonatomic, readonly, nullable) NSArray* styleClasses;
@property (nonatomic, readonly, nullable) NSArray* pseudoClasses;

@property (nonatomic, readonly) NSUInteger specificity;

@property (nonatomic, readonly) NSString* displayDescription;

+ (nullable instancetype) selectorWithType:(nullable NSString*)type elementId:(nullable NSString*)elementId pseudoClasses:(nullable NSArray*)pseudoClasses;
+ (nullable instancetype) selectorWithType:(nullable NSString*)type styleClass:(nullable NSString*)styleClass pseudoClasses:(nullable NSArray*)pseudoClasses;
+ (nullable instancetype) selectorWithType:(nullable NSString*)type styleClasses:(nullable NSArray*)styleClasses pseudoClasses:(nullable NSArray*)pseudoClasses;
+ (nullable instancetype) selectorWithType:(nullable NSString*)type elementId:(nullable NSString*)elementId styleClass:(nullable NSString*)styleClass pseudoClasses:(nullable NSArray*)pseudoClasses;
+ (nullable instancetype) selectorWithType:(nullable NSString*)type elementId:(nullable NSString*)elementId styleClasses:(nullable NSArray*)styleClasses pseudoClasses:(nullable NSArray*)pseudoClasses;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

@end


NS_ASSUME_NONNULL_END
