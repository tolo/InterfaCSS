//
//  InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@class ISSStyleSheet;
@class ISSStyleSheetParser;
@class ISSViewPrototype;

/** 
 * The is the main class of InterfaCSS
 */
@interface InterfaCSS : NSObject

#pragma mark - static methods

/** 
 * Gets the shared InterfaCSS instance.
 */
+ (InterfaCSS*) interfaCSS;

/**
 * Clears and resets all loaded stylesheets, registered style class names and caches.
 */
+ (void) clearResetAndUnload;


#pragma mark - properties

@property (nonatomic, readonly, strong) NSMutableArray* styleSheets;
@property (nonatomic, strong) ISSStyleSheetParser* parser;


#pragma mark - instance methods


/**
 * Clears cached styles.
 */
- (void) clearCachedStylesForUIObject:(id)uiObject;

/**
 * Gets the parent (super) view of a UI object.
 */
- (UIView*) parentViewForUIObject:(id)uiObject;

/**
 * Schedules styling of the specified UI object, i.e.
 */
- (void) scheduleApplyStyling:(id)uiObject animated:(BOOL)animated;

/**
 * Applies styling of the specified UI object.
 */
- (void) applyStyling:(id)uiObject;

/**
 * Applies styling of the specified UI object.
 */
- (void) applyStyling:(id)uiObject includeSubViews:(BOOL)includeSubViews;

/**
 * Applies styling of the specified UI object in an animation block.
 */
- (void) applyStylingWithAnimation:(id)uiObject;

/**
 * Applies styling of the specified UI object in an animation block.
 */
- (void) applyStylingWithAnimation:(id)uiObject includeSubViews:(BOOL)includeSubViews;



/**
 * Gets the current style classes for the specific UI object.
 */
- (NSSet*) styleClassesForUIObject:(id)uiObject;

/**
 * Sets the style classes for the specific UI object.
 */
- (void) setStyleClasses:(NSSet*)styleClasses forUIObject:(id)uiObject;

/**
 * Adds a style class to the specific UI object.
 */
- (void) addStyleClass:(NSString*)styleClass forUIObject:(id)uiObject;

/**
 * Removes a style class from the specific UI object.
 */
- (void) removeStyleClass:(NSString*)styleClass forUIObject:(id)uiObject;



/**
 * Registers a prototype.
 */
- (void) registerPrototype:(ISSViewPrototype*)prototype;

/**
 * Creates a view from a prototype.
 */
- (UIView*) viewFromPrototypeWithName:(NSString*)prototypeName;



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

@end

