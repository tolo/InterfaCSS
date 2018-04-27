//
//  InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>


#define ISS_EQUAL_FLT(x, y) (fabs((x) - (y)) < FLT_EPSILON)

#ifndef ISS_UIKIT_SDK_VERSION
    #if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        #define ISS_UIKIT_SDK_VERSION __IPHONE_OS_VERSION_MIN_REQUIRED
    #elif defined(__TV_OS_VERSION_MIN_REQUIRED)
        #define ISS_UIKIT_SDK_VERSION __TV_OS_VERSION_MIN_REQUIRED
    #else
        #define ISS_UIKIT_SDK_VERSION 80000
    #endif
#endif



@protocol ISSStyleSheetParser;
@class ISSViewPrototype;
@class ISSPropertyRegistry;



#pragma mark - Common block type definitions

typedef NSArray* _Nonnull (^ISSWillApplyStylingNotificationBlock)(NSArray* _Nonnull propertyDeclarations);
typedef void (^ISSDidApplyStylingNotificationBlock)(NSArray* _Nonnull propertyDeclarations);


#pragma mark - Common notification definitions

extern NSString* _Nonnull const ISSWillRefreshStyleSheetsNotification;
extern NSString* _Nonnull const ISSDidRefreshStyleSheetNotification;


#import "ISSPropertyDefinition.h"
#import "ISSStyleSheet.h"
#import "ISSViewBuilder.h"
#import "UIView+InterfaCSS.h"
#import "UITableView+InterfaCSS.h"
#import "NSObject+ISSLogSupport.h"


NS_ASSUME_NONNULL_BEGIN

/** 
 * The heart, core and essence of InterfaCSS. Handles loading of stylesheets and keeps track of all style information.
 */
@interface InterfaCSS : NSObject

#pragma mark - Static methods

/** 
 * Gets the shared InterfaCSS instance.
 */
+ (InterfaCSS*) interfaCSS __deprecated_msg("use `[InterfaCSS sharedInstance]`");

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
 * The interval at which refreshable stylesheets are refreshed. Default is 5 seconds. If value is set to <= 0, automatic refresh is disabled. Note: this is only use for stylesheets loaded from a remote URL.
 */
@property (nonatomic) NSTimeInterval stylesheetAutoRefreshInterval;

/**
 * Flag indicating if refreshable stylesheets always should be processed after "normal" stylesheets, and thereby always being able to override those. Default is `YES`.
 */
@property (nonatomic) NSTimeInterval processRefreshableStylesheetsLast;

/**
 * Flag indicating if unknown type selectors should automatically be registered as canonical type classes (i.e. valid type selector classes) when encountered
 * in a stylesheet. As an alternative to this, consider using `[ISSPropertyRegistry registerCanonicalTypeClass:]`
 *
 * Default value of this property is `YES`.
 * 
 * @see [ISSPropertyRegistry registerCanonicalTypeClass:]
 */
@property (nonatomic) BOOL allowAutomaticRegistrationOfCustomTypeSelectorClasses;

/**
 * Enables or disables the use of selector specificity (see http://www.w3.org/TR/css3-selectors/#specificity ) when calculating the effective styles (and order) for an element. Default value of this property is `NO`.
 */
@property (nonatomic) BOOL useSelectorSpecificity;

/**
 * Enables or disables manual styling. If this property is set to `YES`, no calls to `applyStyling` etc will be scheduled automatically by InterfaCSS. Default value of this property is `NO`.
 */
@property (nonatomic) BOOL useManualStyling;


#pragma mark - Properties

/**
 * The property registry keeps track on all properties that can be set through stylesheets.
 */
@property (nonatomic, readonly, strong) ISSPropertyRegistry* propertyRegistry;

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
 * Clears all cached information, including cached style data, related to the specified UI element, but does not initiate re-styling.
 */
- (void) clearCachedStylesForUIElement:(id)uiElement;

/**
 * Clears all cached information, including cached style data, for the specified element and (optionally) its subviews, but does not initiate re-styling.
 */
- (void) clearCachedStylesForUIElement:(id)uiElement includeSubViews:(BOOL)includeSubViews;

/**
 * Clears all cached information, including cached style data, if needed, for the specified element and (optionally) its subviews, but does not initiate re-styling.
 */
- (void) clearCachedStylesIfNeededForUIElement:(id)uiElement includeSubViews:(BOOL)includeSubViews;

/**
 * Schedules styling of the specified UI object.
 */
- (void) scheduleApplyStyling:(id)uiElement animated:(BOOL)animated;

/**
 * Schedules styling of the specified UI object, but only if it hasn't already been scheduled for an ancestor element.
 */
- (void) scheduleApplyStylingIfNeeded:(id)uiElement animated:(BOOL)animated force:(BOOL)force;

/**
 * Schedules styling of the specified UI object.
 */
- (void) scheduleApplyStyling:(id)uiElement animated:(BOOL)animated force:(BOOL)force;

/**
 * Cancel previously scheduled styling of the specified UI object.
 */
- (void) cancelScheduledApplyStyling:(id)uiElement;

/**
 * Applies styling of the specified UI object and also all its children.
 */
- (void) applyStyling:(id)uiElement;

/**
 * Applies styling of the specified UI object and optionally also all its children.
 */
- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews;

/**
 * Applies styling of the specified UI object and optionally also all its children.
 */
- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force;

/**
 * Applies styling of the specified UI object, and also all its children, in an animation block.
 */
- (void) applyStylingWithAnimation:(id)uiElement;

/**
 * Applies styling of the specified UI object, and optionally also all its children, in an animation block.
 */
- (void) applyStylingWithAnimation:(id)uiElement includeSubViews:(BOOL)includeSubViews;

/**
 * Applies styling of the specified UI object, and optionally also all its children, in an animation block.
 */
- (void) applyStylingWithAnimation:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force;

/**
 * Applies styling of the specified UI object and also all its children, but only if styling has already been scheduled (i.e. one of the scheduleApplyStyling methods has been 
 * called - this is for instance done automatically whenever new style classes are added etc), and only if a parent element hasn't scheduled styling, in which case styling will
 * be applied to this element shortly anyway.
 */
- (void) applyStylingIfScheduled:(id)uiElement;


#pragma mark - Style classes

/**
 * Gets the current style classes for the specified UI element.
 */
- (NSSet*) styleClassesForUIElement:(id)uiElement;

/**
 * Checks if the specified class is set on the specified UI element.
 */
- (BOOL) uiElement:(id)uiElement hasStyleClass:(NSString*)styleClass;

/**
 * Sets the style classes for the specified UI element, replacing any previous style classes.
 */
- (void) setStyleClasses:(NSSet*)styleClasses forUIElement:(id)uiElement;

/**
 * Adds a style class to the specified UI element.
 */
- (void) addStyleClass:(NSString*)styleClass forUIElement:(id)uiElement;

/**
 * Removes a style class from the specified UI element.
 */
- (void) removeStyleClass:(NSString*)styleClass forUIElement:(id)uiElement;


#pragma mark - Element id

/**
 * Sets the unique element identifier to be associated with the specified element.
 *
 * Note: Setting an element id also affects how style information is cached for the specified element, and its decendants. More precicely, when using an element id, 
 * styling identities (effectively the cache key for the styling information) can be calculated more effectively, since the element id can be used as starting point 
 * for the view hierarchy "path" that styling identities consist of. This also means that it's imporant to keep element ids unique.
 */
- (void) setElementId:(nullable NSString*)elementId forUIElement:(id)uiElement;

/**
 * Gets the unique element identifier associated with the specified element.
 */
- (nullable NSString*) elementIdForUIElement:(id)uiElement;


#pragma mark - Additional styling control

/**
 * Sets a callback block for getting notified when styles will be applied to the specified UI element. Makes it possible to prevent some properties from being applied, by returning a different
 * list of properties than the list passed as a parameter to the block.
 */
- (void) setWillApplyStylingBlock:(nullable ISSWillApplyStylingNotificationBlock)willApplyStylingBlock forUIElement:(id)uiElement;

/** Gets the current callback block for getting notified when styles will be applied to the specified UI element.*/
- (nullable ISSWillApplyStylingNotificationBlock) willApplyStylingBlockForUIElement:(id)uiElement;

/**
 * Sets a callback block for getting notified when styles have been applied to the specified UI element. Makes it possible to for instance adjust property values or update dependent properties.
 */
- (void) setDidApplyStylingBlock:(nullable ISSDidApplyStylingNotificationBlock)didApplyStylingBlock forUIElement:(id)uiElement;

/** Gets the current callback block for getting notified when styles have been applied to the specified UI element.*/
- (nullable ISSDidApplyStylingNotificationBlock) didApplyStylingBlockForUIElement:(id)uiElement;

/**
 * Sets a custom styling identity that overrides the default mechanism for assigning styling identities to elements (which essentially involves building a full view
 * hierarchy "path" of an element, such as "UIWindow UIView UIView[class]"). The styling identity is effectively the cache key for the styling information
 * associated with a UI element, and setting this to a custom value makes it possible to (further) increase performance by sharing cached styles with
 * UI elements located in different places in the view hierarchy for instance. Examples of places where setting this property can be useful is for instance
 * the root view of a view controller, a custom UI component or other views that can be styles regardless of the ancestor view hierarchy.
 *
 * NOTE: When using a custom styling identity for a view, avoid using style declarations that depends on the view hierarchy above that view (i.e. use of chained
 * or nested selectors that ).
 */
- (void) setCustomStylingIdentity:(nullable NSString*)customStylingIdentity forUIElement:(id)uiElement;

/** Gets the custom styling identity. */
- (nullable NSString*) customStylingIdentityForUIElement:(id)uiElement;

/**
 * Disables or re-enables styling of the specified UI element. If `enabled` is set to `NO`, InterfaCSS will stop applying styling information to the element and it's children,
 * but any styles that have already been applied will remain. This method can for instance be useful for setting initial styles for a view via InterfaCSS,
 * and then take control of the styling manually, without the risk of InterfaCSS overwriting any modified properties.
 */
- (void) setStylingEnabled:(BOOL)enabled forUIElement:(id)uiElement;

/** Returns `YES` if styling is enabled for the specified UI element. */
- (BOOL) isStylingEnabledForUIElement:(id)uiElement;

/** Returns `YES` if styling has been successfully applied to the specified UI element. */
- (BOOL) isStylingAppliedForUIElement:(id)uiElement;


/**
 * Disables or re-enables styling of a specific property in the specified UI element. If `enabled` is set to `NO`, InterfaCSS will stop applying styling information to the
 * property, but any value that has already been applied will remain. This method can for instance be useful for setting initial styles for a view via InterfaCSS,
 * and then take control of the styling manually, without the risk of InterfaCSS overwriting property values.
 */
- (void) setStylingEnabled:(BOOL)enabled forProperty:(NSString*)propertyName inUIElement:(id)uiElement;

/** Returns `YES` if styling is enabled for a specific property in the specified UI element. */
- (BOOL) isStylingEnabledForProperty:(NSString*)propertyName inUIElement:(id)uiElement;

/** Finds a sub view with the specified element identifier. */
- (nullable id) subviewWithElementId:(NSString*)elementId inView:(id)view;
/** Finds a super view with the specified element identifier. */
- (nullable id) superviewWithElementId:(NSString*)elementId inView:(id)view;

- (void) autoPopulatePropertiesInViewHierarchyFromView:(UIView*)view inOwner:(id)owner;


#pragma mark - Stylesheets

/**
 * Loads a stylesheet from the main bundle.
 */
- (nullable ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName;
- (nullable ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName withScope:(nullable ISSStyleSheetScope*)scope;

/**
 * Loads a stylesheet from an absolute file path.
 */
- (nullable ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath;
- (nullable ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath withScope:(nullable ISSStyleSheetScope*)scope;

/**
 * Loads an auto-refreshable stylesheet from a URL (both file and http URLs are supported).
 * Note: Refreshable stylesheets are only intended for use during development, and not in production.
 */
- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetFileURL;
- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetFileURL withScope:(nullable ISSStyleSheetScope*)scope;

/**
 * Loads an auto-refreshable stylesheet from a local file path, and starts monitoring the file for changes.
 * Note: Refreshable stylesheets are only intended for use during development, and not in production.
 */
- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromLocalFile:(NSString*)styleSheetFilePath;
- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromLocalFile:(NSString*)styleSheetFilePath withScope:(nullable ISSStyleSheetScope*)scope;

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

/**
 * Clears all cached style information and re-applies styles for all views.
 */
- (void) refreshStyling;

/**
 * Clears all cached style information, but does not initiate re-styling.
 */
- (void) clearAllCachedStyles;


#pragma mark - Prototypes

/**
 * Registers a prototype defined in a view definition file.
 */
- (void) registerPrototype:(ISSViewPrototype*)prototype;

/**
 * Registers a prototype defined in a view definition file.
 */
- (void) registerPrototype:(ISSViewPrototype*)prototype inElement:(id)registeredInElement;

/**
 * Creates a view from a prototype defined in a view definition file.
 */
- (nullable UIView*) viewFromPrototypeWithName:(NSString*)prototypeName;

/**
 * Creates a view from a prototype defined in a view definition file.
 */
- (nullable UIView*) viewFromPrototypeWithName:(NSString*)prototypeName prototypeParent:(nullable id)prototypeParent;

/**
 * Creates a view from a prototype defined in a view definition file.
 */
- (nullable UIView*) viewFromPrototypeWithName:(NSString*)prototypeName registeredInElement:(nullable id)registeredInElement prototypeParent:(nullable id)prototypeParent;


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
 * Returns the value of the stylesheet variable with the specified name, transformed using the specified property definition.
 */
- (nullable id) transformedValueOfStyleSheetVariableWithName:(NSString*)variableName forPropertyDefinition:(ISSPropertyDefinition*)propertyDefinition;

/**
 * Sets the raw value of the stylesheet variable with the specified name.
 */
- (void) setValue:(nullable NSString*)value forStyleSheetVariableWithName:(NSString*)variableName;


#pragma mark - Debugging support

/**
 * Logs the active style declarations for the specified UI element.
 */
- (void) logMatchingStyleDeclarationsForUIElement:(id)uiElement;

@end

NS_ASSUME_NONNULL_END
