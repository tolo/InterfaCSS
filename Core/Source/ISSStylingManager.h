//
//  ISSStylingManager.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class ISSPropertyManager, ISSStyleSheetManager, ISSElementStylingProxy;



#pragma mark - Common block type definitions

//typedef NSArray* _Nonnull (^ISSWillApplyStylingNotificationBlock)(NSArray* _Nonnull propertyDeclarations);
//typedef void (^ISSDidApplyStylingNotificationBlock)(NSArray* _Nonnull propertyDeclarations);


#pragma mark - Common notification definitions

//extern NSString* _Nonnull const ISSWillRefreshStyleSheetsNotification;
//extern NSString* _Nonnull const ISSDidRefreshStyleSheetNotification;

#import "ISSStyler.h"
#import "ISSProperty.h"
#import "ISSStyleSheet.h"
#import "NSObject+ISSLogSupport.h"


NS_ASSUME_NONNULL_BEGIN

/** 
 * The heart, core and essence of InterfaCSS. Handles loading of stylesheets and keeps track of all style information.
 */
@interface ISSStylingManager : NSObject <ISSStyler>

@property (nonatomic, strong, readonly) ISSPropertyManager* propertyManager;
@property (nonatomic, strong, readonly) ISSStyleSheetManager* styleSheetManager;


#pragma mark - Initialization

/** 
 * Gets the shared ISSStylingManager instance.
 */
//+ (ISSStylingManager*) shared;

- (instancetype) init;
- (instancetype) initWithPropertyRegistry:(nullable ISSPropertyManager*)propertyManager styleSheetManager:(nullable ISSStyleSheetManager*)styleSheetManager NS_DESIGNATED_INITIALIZER;


#pragma mark - Behavioural properties


/**
 * Enables or disables the use of selector specificity (see http://www.w3.org/TR/css3-selectors/#specificity ) when calculating the effective styles (and order) for an element. Default value of this property is `NO`.
 */
//@property (nonatomic) BOOL useSelectorSpecificity;


#pragma mark - Styling

/**
 * Applies styling of the specified UI object and optionally also all its children.
 */
- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force styleSheetScope:(nullable ISSStyleSheetScope*)styleSheetScope;

/**
 *
 */
- (id<ISSStyler>) stylerWithScope:(ISSStyleSheetScope*)styleSheetScope;

/**
 *
 */
- (ISSElementStylingProxy*) stylingProxyFor:(id)uiElement;

/**
 * Clears all cached style information, but does not initiate re-styling.
 */
- (void) clearAllCachedStyles;


#pragma mark - Subscripting support (alias for stylingProxyFor:)

- (ISSElementStylingProxy*) objectForKeyedSubscript:(id)uiElement;



#pragma mark - Pseudo class support

- (void) typeQualifiedPositionInParentForElement:(ISSElementStylingProxy*)elementDetails position:(NSInteger*)position count:(NSInteger*)count;


#pragma mark - Debugging support

/**
 * Logs the active rulesets for the specified UI element.
 */
- (void) logMatchingRulesetsForElement:(id)uiElement styleSheetScope:(nullable ISSStyleSheetScope*)styleSheetScope;

@end

NS_ASSUME_NONNULL_END
