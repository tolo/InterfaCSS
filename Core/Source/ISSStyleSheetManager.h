//
//  ISSStyleSheetManager.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

@class ISSStylingManager, ISSStyleSheetParser, ISSElementStylingProxy, ISSStyleSheet, ISSRuleset, ISSStyleSheetScope, ISSSelector;

#import "ISSPropertyDefinition.h"
#import "ISSPseudoClass.h"


#pragma mark - Common notification definitions

extern NSString* _Nonnull const ISSWillRefreshStyleSheetsNotification;
extern NSString* _Nonnull const ISSDidRefreshStyleSheetNotification;


NS_ASSUME_NONNULL_BEGIN

@interface ISSStyleSheetManager : NSObject

@property (nonatomic, weak) ISSStylingManager* stylingManager;

@property (nonatomic, strong) ISSStyleSheetParser* styleSheetParser;

/**
 * All currently active stylesheets (`ISSStyleSheet`).
 */
@property (nonatomic, readonly, strong) NSMutableArray<ISSStyleSheet*>* styleSheets;

/**
 * The interval at which refreshable stylesheets are refreshed. Default is 5 seconds. If value is set to <= 0, automatic refresh is disabled. Note: this is only use for stylesheets loaded from a remote URL.
 */
@property (nonatomic) NSTimeInterval stylesheetAutoRefreshInterval;

/**
 * Flag indicating if refreshable stylesheets always should be processed after "normal" stylesheets, and thereby always being able to override those. Default is `YES`.
 */
@property (nonatomic) BOOL processRefreshableStylesheetsLast;


- (instancetype) init;
- (instancetype) initWithStyleSheetParser:(nullable ISSStyleSheetParser*)parser NS_DESIGNATED_INITIALIZER;



#pragma mark - Stylesheets

/**
 * Loads a stylesheet from the main bundle.
 */
- (nullable ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName;
- (nullable ISSStyleSheet*) loadNamedStyleSheet:(nullable NSString*)name group:(nullable NSString*)groupName fromMainBundleFile:(NSString*)styleSheetFileName;
//- (nullable ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName withScope:(nullable ISSStyleSheetScope*)scope;

/**
 * Loads a stylesheet from an absolute file path.
 */
- (nullable ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath;
//- (nullable ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath withScope:(nullable ISSStyleSheetScope*)scope;
- (nullable ISSStyleSheet*) loadNamedStyleSheet:(nullable NSString*)name group:(nullable NSString*)groupName fromFile:(NSString*)styleSheetFilePath;

/**
 * Loads an auto-refreshable stylesheet from a URL (both file and http URLs are supported).
 * Note: Refreshable stylesheets are only intended for use during development, and not in production.
 */
- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetFileURL;
//- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetFileURL withScope:(nullable ISSStyleSheetScope*)scope;
- (nullable ISSStyleSheet*) loadRefreshableNamedStyleSheet:(nullable NSString*)name group:(nullable NSString*)groupName fromURL:(NSURL*)styleSheetFileURL;

/**
 * Loads an auto-refreshable stylesheet from a local file path, and starts monitoring the file for changes.
 * Note: Refreshable stylesheets are only intended for use during development, and not in production.
 */
//- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromLocalFile:(NSString*)styleSheetFilePath;
//- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromLocalFile:(NSString*)styleSheetFilePath withScope:(nullable ISSStyleSheetScope*)scope;

/** Reloads all (remote) refreshable stylesheets. If force is `YES`, stylesheets will be reloaded even if they haven't been modified. */
- (void) reloadRefreshableStyleSheets:(BOOL)force;

/** Reloads a refreshable stylesheet. If force is `YES`, the stylesheet will be reloaded even if is hasn't been modified. */
- (void) reloadRefreshableStyleSheet:(ISSStyleSheet*)styleSheet force:(BOOL)force;

/**
 * Unloads the specified styleSheet.
 * @param styleSheet the stylesheet to unload.
 * @param refreshStyling YES if styling on all tracked views should be reset and reapplied as a result of this call, otherwise NO.
 */
- (void) unloadStyleSheet:(ISSStyleSheet*)styleSheet refreshStyling:(BOOL)refreshStyling;

/**
 * Unloads all loaded stylesheets, effectively resetting the styling of all views.
 * @param refreshStyling YES if styling on all tracked views should be reset and reapplied as a result of this call, otherwise NO.
 */
- (void) unloadAllStyleSheets:(BOOL)refreshStyling;



- (NSArray<ISSRuleset*>*) rulesetsMatchingElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext;



#pragma mark - Variable access

/**
 * Returns the raw value of the stylesheet variable with the specified name.
 */
- (nullable NSString*) valueOfStyleSheetVariableWithName:(NSString*)variableName;

/**
 * Returns the value of the stylesheet variable with the specified name, transformed to the specified type.
 */
- (nullable id) transformedValueOfStyleSheetVariableWithName:(NSString*)variableName asPropertyType:(ISSPropertyType)propertyType;

/**
 * Sets the raw value of the stylesheet variable with the specified name.
 */
- (void) setValue:(nullable NSString*)value forStyleSheetVariableWithName:(NSString*)variableName;


#pragma mark - Selector creation support

- (nullable ISSSelector*) createSelectorWithType:(nullable NSString*)type elementId:(nullable NSString*)elementId styleClasses:(nullable NSArray*)styleClasses pseudoClasses:(nullable NSArray*)pseudoClasses;
    

#pragma mark - Pseudo class customization support

- (ISSPseudoClassType) pseudoClassTypeFromString:(NSString*)typeAsString;

- (nullable ISSPseudoClass*) createPseudoClassWithParameter:(nullable NSString*)parameter type:(ISSPseudoClassType)type;


#pragma mark - Debugging support

- (void) logMatchingStyleDeclarationsForUIElement:(ISSElementStylingProxy*)elementDetails styleSheetScope:(nullable ISSStyleSheetScope*)styleSheetScope;

@end


NS_ASSUME_NONNULL_END
