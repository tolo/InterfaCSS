//
//  InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//


typedef NSArray* (^ISSWillApplyStylingNotificationBlock)(NSArray* propertyDeclarations);
typedef void (^ISSDidApplyStylingNotificationBlock)(NSArray* propertyDeclarations);


#import "ISSPropertyDefinition.h"
#import "ISSStyleSheet.h"
#import "ISSViewBuilder.h"
#import "UIView+InterfaCSS.h"
#import "UITableView+InterfaCSS.h"
#import "NSObject+ISSLogSupport.h"


@protocol ISSStyleSheetParser;
@class ISSViewPrototype;
@class ISSUIElementDetails;


/** 
 * The heart, core and essence of InterfaCSS. Handles loading of stylesheets and keeps track of all style information.
 */
@interface InterfaCSS : NSObject


#pragma mark - Static methods

/** 
 * Gets the shared InterfaCSS instance.
 *
 * @deprecated use `[InterfaCSS sharedInstance]`.
 */
+ (InterfaCSS*) interfaCSS;

/**
 * Gets the shared InterfaCSS instance.
 */
+ (InterfaCSS*) sharedInstance;

/**
 * Clears and resets all loaded stylesheets, registered style class names and caches.
 */
+ (void) clearResetAndUnload;



#pragma mark - Behavioural properties

/**
 * Setting this flag to `YES` prevents "overwriting" of font and text color in attributed text of labels (and buttons) when styles are applied.
 * Default value is `NO`
 */
@property (nonatomic) BOOL preventOverwriteOfAttributedTextAttributes;

/**
 * If this flag is set to `YES`, any type selector that don't match a valid UIKit type will instead be used as a style class selector. Default is `NO`.
 */
@property (nonatomic) BOOL useLenientSelectorParsing;

/**
 * The interval at which refreshable stylesheets are refreshed. Default is 5 seconds.
 */
@property (nonatomic) NSTimeInterval stylesheetAutoRefreshInterval;

/**
 * Flag indicating if refreshable stylesheets always should be processed after "normal" stylesheets, and thereby always being able to override those. Default is `YES`.
 */
@property (nonatomic) NSTimeInterval processRefreshableStylesheetsLast;


#pragma mark - Properties

/**
 * All currently active stylesheets (`ISSStyleSheet`).
 */
@property (nonatomic, readonly, strong) NSMutableArray* styleSheets;

/**
 * The current stylesheet parser.
 */
@property (nonatomic, strong) id<ISSStyleSheetParser> parser;


#pragma mark - Styling

/**
 * Clears cached styles.
 */
- (void) clearCachedStylesForUIElement:(id)uiElement;

/**
 * Schedules styling of the specified UI object.
 */
- (void) scheduleApplyStyling:(id)uiElement animated:(BOOL)animated;

/**
 * Schedules styling of the specified UI object.
 */
- (void) scheduleApplyStyling:(id)uiElement animated:(BOOL)animated force:(BOOL)force;

/**
 * Applies styling of the specified UI object.
 */
- (void) applyStyling:(id)uiElement;

/**
 * Applies styling of the specified UI object.
 */
- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews;

/**
 * Applies styling of the specified UI object.
 */
- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force;

/**
 * Applies styling of the specified UI object in an animation block.
 */
- (void) applyStylingWithAnimation:(id)uiElement;

/**
 * Applies styling of the specified UI object in an animation block.
 */
- (void) applyStylingWithAnimation:(id)uiElement includeSubViews:(BOOL)includeSubViews;

/**
 * Applies styling of the specified UI object in an animation block.
 */
- (void) applyStylingWithAnimation:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force;

/**
 * Disables or re-enables styling of this view. If `enabled` is set to `NO`, InterfaCSS will stop applying styling information to this view and it's children,
 * but any styles that have already been applied will remain. This method can for instance be useful for setting initial styles for a view via InterfaCSS,
 * and then take control of the styling manually, without the risk of InterfaCSS overwriting any modified properties.
 */
- (void) setStylingEnabled:(BOOL)enabled forUIElement:(id)uiElement;


#pragma mark - Style classes

/**
 * Gets the current style classes for the specific UI object.
 */
- (NSSet*) styleClassesForUIElement:(id)uiElement;

/**
 *
 */
- (BOOL) uiElement:(id)uiElement hasStyleClass:(NSString*)styleClass;

/**
 * Sets the style classes for the specific UI object, replacing any previous style classes.
 */
- (void) setStyleClasses:(NSSet*)styleClasses forUIElement:(id)uiElement;

/**
 * Adds a style class to the specific UI object.
 */
- (void) addStyleClass:(NSString*)styleClass forUIElement:(id)uiElement;

/**
 * Removes a style class from the specific UI object.
 */
- (void) removeStyleClass:(NSString*)styleClass forUIElement:(id)uiElement;


#pragma mark - Stylesheets

/**
 * Loads a stylesheet from the main bundle.
 */
- (ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName;

/**
 * Loads a stylesheet from file.
 */
- (ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath;

/**
 * Loads an auto-refreshable stylesheet from a URL.
 * Note: Refreshable stylesheets are only intended for use during development, and not in production.
 */
- (ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetFileURL;

/**
 * Unloads the specified styleSheet.
 * @param styleSheet the stylesheet to unload.
 * @param refreshStyling @p YES if styling on all tracked views should be reset as a result of this call, otherwise @p NO.
 */
- (void) unloadStyleSheet:(ISSStyleSheet*)styleSheet refreshStyling:(BOOL)refreshStyling;

/**
 * Unloads all loaded stylesheets, effectively resetting the styling of all views.
 * @param refreshStyling @p YES if styling on all tracked views should be reset as a result of this call, otherwise @p NO.
 */
- (void) unloadAllStyleSheets:(BOOL)refreshStyling;


#pragma mark - Prototypes

/**
 * Registers a prototype defined in a view definition file.
 */
- (void) registerPrototype:(ISSViewPrototype*)prototype;

/**
 * Creates a view from a prototype defined in a view definition file.
 */
- (UIView*) viewFromPrototypeWithName:(NSString*)prototypeName;


#pragma mark - Variable access

/**
 * Returns the raw value of the stylesheet variable with the specified name.
 */
- (NSString*) valueOfStyleSheetVariableWithName:(NSString*)variableName;

/**
 * Returns the value of the stylesheet variable with the specified name, transformed to the specified type.
 */
- (id) transformedValueOfStyleSheetVariableWithName:(NSString*)variableName asPropertyType:(ISSPropertyType)propertyType;

/**
 * Returns the value of the stylesheet variable with the specified name, transformed using the specified property definition.
 */
- (id) transformedValueOfStyleSheetVariableWithName:(NSString*)variableName forPropertyDefinition:(ISSPropertyDefinition*)propertyDefinition;

/**
 * Sets the raw value of the stylesheet variable with the specified name.
 */
- (void) setValue:(NSString*)value forStyleSheetVariableWithName:(NSString*)variableName;


#pragma mark - Debugging support

/**
 * Logs the active style declarations for the specified UI element.
 */
- (void) logMatchingStyleDeclarationsForUIElement:(id)uiElement;

@end
