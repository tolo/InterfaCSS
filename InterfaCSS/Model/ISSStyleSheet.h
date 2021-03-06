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


@protocol ISSStyleSheetParser;
@class ISSUIElementDetails;
@class ISSStylingContext;
@class ISSPropertyDeclarations;
@class ISSSelectorChain;


typedef BOOL (^ISSStyleSheetScopeMatcher)(ISSUIElementDetails* elementDetails);

extern NSString* const ISSStyleSheetRefreshedNotification;
extern NSString* const ISSStyleSheetRefreshFailedNotification;



/**
 * Class representing a scope for limiting to which views styles in a stylesheet should be applied.
 */
@interface ISSStyleSheetScope : NSObject

/** Scope limited to views under a view with the specified element ID. */
+ (ISSStyleSheetScope*) scopeWithElementId:(NSString*)elementId;

/** Scope limited to views in the direct view hierarchy (i.e. excluding child view controllers) of view controllers with the specified class. */
+ (ISSStyleSheetScope*) scopeWithViewControllerClass:(Class)viewControllerClass;

/** Scope limited to views in the view hierarchy of view controllers with the specified class. If `includeChildViewControllers` is `NO`, the scope is limited
* to the direct view hierarchy of the view controller - if `YES`, views in child view controllers are also included. */
+ (ISSStyleSheetScope*) scopeWithViewControllerClass:(Class)viewControllerClass includeChildViewControllers:(BOOL)includeChildViewControllers;

/** Scope limited to views in the direct view hierarchy (i.e. excluding child view controllers) of view controllers with the specified classes. */
+ (ISSStyleSheetScope*) scopeWithViewControllerClasses:(NSArray*)viewControllerClasses;

/** Scope limited to views in the view hierarchy of view controllers with the specified classes. If `includeChildViewControllers` is `NO`, the scope is limited
* to the direct view hierarchy of the view controller - if `YES`, views in child view controllers are also included. */
+ (ISSStyleSheetScope*) scopeWithViewControllerClasses:(NSArray*)viewControllerClasses includeChildViewControllers:(BOOL)includeChildViewControllers;

/** Creates a scope with a custom matcher. */
+ (ISSStyleSheetScope*) scopeWithMatcher:(ISSStyleSheetScopeMatcher)matcher;

- (BOOL) elementInScope:(ISSUIElementDetails*)elementDetails;

@end


/**
 * Represents a loaded stylesheet.
 */
@interface ISSStyleSheet : ISSRefreshableResource

@property (nonatomic, readonly) NSURL* styleSheetURL;
@property (nonatomic, readonly, nullable) NSArray* declarations; // ISSPropertyDeclarations
@property (nonatomic) BOOL active;
@property (nonatomic, readonly) BOOL refreshable;
@property (nonatomic, readonly) NSString* displayDescription;
@property (nonatomic, strong, nullable) ISSStyleSheetScope* scope;

- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(nullable NSArray*)declarations;
- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(nullable NSArray*)declarations refreshable:(BOOL)refreshable;
- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(nullable NSArray*)declarations refreshable:(BOOL)refreshable scope:(nullable ISSStyleSheetScope*)scope;

- (nullable NSArray*) declarationsMatchingElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;

- (nullable ISSPropertyDeclarations*) findPropertyDeclarationsWithSelectorChain:(ISSSelectorChain*)selectorChain;

- (void) refreshStylesheetWithCompletionHandler:(void (^)(void))completionHandler force:(BOOL)force;

@end


NS_ASSUME_NONNULL_END
