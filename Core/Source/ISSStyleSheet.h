//
//  ISSStyleSheet.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

#import "ISSStyleSheetContent.h"


NS_ASSUME_NONNULL_BEGIN


@class ISSStyleSheetManager, ISSElementStylingProxy, ISSStylingContext, ISSRuleset, ISSSelectorChain, ISSRuleset, ISSStyleSheet, ISSRefreshableStyleSheet, ISSRefreshableResource;


NS_SWIFT_NAME(StyleSheetMatcher)
typedef BOOL (^ISSStyleSheetMatcher)(ISSStyleSheet* styleSheet);


NS_SWIFT_NAME(StyleSheetRefreshed)
extern NSNotificationName const ISSStyleSheetRefreshedNotification;
NS_SWIFT_NAME(StyleSheetRefreshFailed)
extern NSNotificationName const ISSStyleSheetRefreshFailedNotification;

NS_SWIFT_NAME(StyleSheetGroupDefault)
extern NSString* const ISSStyleSheetGroupDefault;
NS_SWIFT_NAME(StyleSheetNoGroup)
extern NSString* const ISSStyleSheetNoGroup;



/**
 * Class representing a scope used for limiting which stylesheets should be used for styling.
 */
NS_SWIFT_NAME(StyleSheetScope)
@interface ISSStyleSheetScope : NSObject

+ (ISSStyleSheetScope*) defaultGroupScope;

+ (ISSStyleSheetScope*) scopeWithStyleSheetNames:(NSArray<NSString*>*)names;
+ (ISSStyleSheetScope*) scopeWithDefaultStyleSheetGroupAndStyleSheetNames:(NSArray<NSString*>*)names;

+ (ISSStyleSheetScope*) scopeWithStyleSheetGroups:(NSArray<NSString*>*)groups;
+ (ISSStyleSheetScope*) scopeWithDefaultStyleSheetGroupAndGroups:(NSArray<NSString*>*)groups;

- (instancetype) initWithMatcher:(ISSStyleSheetMatcher)matcher;
- (ISSStyleSheetScope*) scopeByIncludingScope:(ISSStyleSheetScope*)otherScope;

- (BOOL) containsStyleSheet:(ISSStyleSheet*)styleSheet;

@end


/**
 * Represents a loaded stylesheet.
 */
NS_SWIFT_NAME(StyleSheet)
@interface ISSStyleSheet : NSObject

@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, strong, readonly, nullable) NSString* group;
@property (nonatomic, strong, readonly) NSURL* styleSheetURL;

@property (nonatomic, strong, readonly, nullable) ISSStyleSheetContent* content;

@property (nonatomic) BOOL active;
@property (nonatomic, readonly) BOOL refreshable;

@property (nonatomic, strong, readonly) NSString* displayDescription;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) initWithStyleSheetURL:(NSURL*)styleSheetURL content:(nullable ISSStyleSheetContent*)content;
- (instancetype) initWithStyleSheetURL:(NSURL*)styleSheetURL name:(nullable NSString*)name group:(nullable NSString*)groupName content:(nullable ISSStyleSheetContent*)content NS_DESIGNATED_INITIALIZER;

- (nullable ISSRulesets*) rulesetsMatchingElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

- (nullable ISSRuleset*) findPropertyDeclarationsWithSelectorChain:(ISSSelectorChain*)selectorChain;

- (void) unload;

@end


typedef void (^ISSRefreshableStyleSheetObserverBlock)(ISSRefreshableStyleSheet* refreshedStylesheet);


NS_SWIFT_NAME(RefreshableStyleSheet)
@interface ISSRefreshableStyleSheet : ISSStyleSheet

@property (nonatomic, strong, readonly) ISSRefreshableResource* refreshableResource;

@property (nonatomic, readonly) BOOL styleSheetModificationMonitoringSupported;
@property (nonatomic, readonly) BOOL styleSheetModificationMonitoringEnabled;

- (void) startMonitoringStyleSheetModification:(ISSRefreshableStyleSheetObserverBlock)modificationObserver;

- (void) refreshStylesheetWith:(ISSStyleSheetManager*)styleSheetManager andCompletionHandler:(void (^)(void))completionHandler force:(BOOL)force;

@end


NS_ASSUME_NONNULL_END
