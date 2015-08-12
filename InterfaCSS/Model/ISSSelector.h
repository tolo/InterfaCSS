//
//  ISSSelector.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@class ISSPseudoClass;
@class ISSUIElementDetails;

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

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails ignoringPseudoClasses:(BOOL)ignorePseudoClasses;

@end
