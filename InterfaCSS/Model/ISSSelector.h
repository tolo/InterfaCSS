//
//  ISSSelector.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

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

@property (nonatomic, readonly) Class type;
@property (nonatomic, readonly) NSString* elementId;
@property (nonatomic, readonly) NSString* styleClass;
@property (nonatomic, readonly) NSArray* pseudoClasses;

@property (nonatomic, readonly) NSUInteger specificity;

@property (nonatomic, readonly) NSString* displayDescription;

+ (instancetype) selectorWithType:(NSString*)type elementId:(NSString*)elementId pseudoClasses:(NSArray*)pseudoClasses;
+ (instancetype) selectorWithType:(NSString*)type styleClass:(NSString*)styleClass pseudoClasses:(NSArray*)pseudoClasses;
+ (instancetype) selectorWithType:(NSString*)type elementId:(NSString*)elementId styleClass:(NSString*)styleClass pseudoClasses:(NSArray*)pseudoClasses;

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

@end
