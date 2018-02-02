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


//typedef BOOL (^ISSStyleSheetScopeMatcher)(ISSElementStylingProxy* elementDetails);

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


///**
// * Class representing a scope for limiting to which views styles in a stylesheet should be applied.
// */
//@interface ISSStyleSheetScope : NSObject
//
///** Scope limited to views under a view with the specified element ID. */
//+ (ISSStyleSheetScope*) scopeWithElementId:(NSString*)elementId;
//
///** Scope limited to views in the direct view hierarchy (i.e. excluding child view controllers) of view controllers with the specified class. */
//+ (ISSStyleSheetScope*) scopeWithViewControllerClass:(Class)viewControllerClass;
//
///** Scope limited to views in the view hierarchy of view controllers with the specified class. If `includeChildViewControllers` is `NO`, the scope is limited
//* to the direct view hierarchy of the view controller - if `YES`, views in child view controllers are also included. */
//+ (ISSStyleSheetScope*) scopeWithViewControllerClass:(Class)viewControllerClass includeChildViewControllers:(BOOL)includeChildViewControllers;
//
///** Scope limited to views in the direct view hierarchy (i.e. excluding child view controllers) of view controllers with the specified classes. */
//+ (ISSStyleSheetScope*) scopeWithViewControllerClasses:(NSArray*)viewControllerClasses;
//
///** Scope limited to views in the view hierarchy of view controllers with the specified classes. If `includeChildViewControllers` is `NO`, the scope is limited
//* to the direct view hierarchy of the view controller - if `YES`, views in child view controllers are also included. */
//+ (ISSStyleSheetScope*) scopeWithViewControllerClasses:(NSArray*)viewControllerClasses includeChildViewControllers:(BOOL)includeChildViewControllers;
//
///** Creates a scope with a custom matcher. */
//+ (ISSStyleSheetScope*) scopeWithMatcher:(ISSStyleSheetScopeMatcher)matcher;
//
//- (BOOL) elementInScope:(ISSElementStylingProxy*)elementDetails;
//
//@end


/**
 * Represents a loaded stylesheet.
 */
@interface ISSStyleSheet : ISSRefreshableResource

@property (nonatomic, strong, readonly) NSString* name;
@property (nonatomic, strong, readonly) NSString* group;
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
