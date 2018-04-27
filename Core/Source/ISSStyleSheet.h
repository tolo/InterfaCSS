//
//  ISSStyleSheet.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

#import "ISSRefreshableResource.h"

NS_ASSUME_NONNULL_BEGIN


@class ISSStyleSheetManager, ISSElementStylingProxy, ISSStylingContext, ISSRuleset, ISSSelectorChain, ISSPropertyDeclarations, ISSStyleSheet;


typedef BOOL (^ISSStyleSheetMatcher)(ISSStyleSheet* styleSheet);


extern NSString* const ISSStyleSheetRefreshedNotification;
extern NSString* const ISSStyleSheetRefreshFailedNotification;



/**
 * Class representing a scope used for limiting which stylesheets should be used for styling.
 */
@interface ISSStyleSheetScope : NSObject

+ (ISSStyleSheetScope*) scopeWithStyleSheetNames:(NSArray*)names;

+ (ISSStyleSheetScope*) scopeWithStyleSheetGroups:(NSArray*)groups;

- (instancetype) initWithMatcher:(ISSStyleSheetMatcher)matcher;

- (BOOL) containsStyleSheet:(ISSStyleSheet*)styleSheet;

@end


/**
 * Represents a loaded stylesheet.
 */
@interface ISSStyleSheet : ISSRefreshableResource

@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, strong, readonly, nullable) NSString* group;
@property (nonatomic, strong, readonly) NSURL* styleSheetURL;

@property (nonatomic, strong, readonly, nullable) NSArray<ISSRuleset*>* rulesets;

@property (nonatomic) BOOL active;
@property (nonatomic, readonly) BOOL refreshable;

@property (nonatomic, strong, readonly) NSString* displayDescription;

- (instancetype) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(nullable NSArray*)declarations refreshable:(BOOL)refreshable;
- (instancetype) initWithStyleSheetURL:(NSURL*)styleSheetURL name:(nullable NSString*)name group:(nullable NSString*)groupName declarations:(nullable NSArray*)declarations refreshable:(BOOL)refreshable;

- (nullable NSArray<ISSRuleset*>*) rulesetsMatchingElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

- (nullable ISSRuleset*) findPropertyDeclarationsWithSelectorChain:(ISSSelectorChain*)selectorChain;

- (void) refreshStylesheetWith:(ISSStyleSheetManager*)styleSheetManager andCompletionHandler:(void (^)(void))completionHandler force:(BOOL)force;

@end


NS_ASSUME_NONNULL_END
