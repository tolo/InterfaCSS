//
//  UIView+InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//


#import "InterfaCSS.h"

/**
 * UIView category that adds convenience methods for managing the style classes of a UI element.
 */
@interface UIView (InterfaCSS)

/**
 * Convenience property for setting/getting a single style class. If multiple classes are set, the value returned by this property can be any of those styles.
 */
@property (nonatomic, strong) NSString* styleClassISS;

/**
 * Represents the style class for the this view.
 */
@property (nonatomic, strong) NSSet* styleClassesISS;

/**
 * Callback block for getting notified when styles will be applied to this view. Makes it possible to prevent some properties from being applied
 */
@property (nonatomic, copy) ISSWillApplyStylingNotificationBlock willApplyStylingBlockISS;

/**
 * Callback block for getting notified when styles have been applied to this view. Makes it possible to for instance adjust property values or update dependent properties.
 */
@property (nonatomic, copy) ISSDidApplyStylingNotificationBlock didApplyStylingBlockISS;


/**
 * Sets the style class for the this view, replacing any previous style classes.
 */
- (void) setStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;

/**
 * Sets the style classes for the this view, replacing any previous style classes.
 */
- (void) setStyleClassesISS:(NSSet*)classes animated:(BOOL)animated;

/**
 * Checks if the specified class is set on this view.
 */
- (BOOL) hasStyleClassISS:(NSString*)styleClass;


/**
 * Adds a new styles class to this view, if not already present. Triggers an asynchronous re-styling of this view.
 */
- (void) addStyleClassISS:(NSString*)styleClass;

/**
 * Adds a new styles class to this view, if not already present. Triggers an asynchronous re-styling of this view, within an animation block.
 */
- (void) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;


/**
 * Removes the specified style class from this view. Triggers an asynchronous re-styling of this view.
 */
- (void) removeStyleClassISS:(NSString*)styleClass;

/**
 * Removes the specified style class from this view. Triggers an asynchronous re-styling of this view, within an animation block.
 */
- (void) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;


/**
 * Schedules an asynchronous re-styling of this view.
 */
- (void) scheduleApplyStylingISS;

/**
 * Schedules an asynchronous re-styling of this view. The re-styling will be performed within an animation block.
 */
- (void) scheduleApplyStylingISS:(BOOL)animated;


/**
 * Applies styling to this view.
 */
- (void) applyStylingISS;

/**
 * Applies styling to this view, with optional clearing of cached styling information first.
 */
- (void) applyStylingISS:(BOOL)invalidateStyles;

/**
 * Applies styling to this view within an animation block.
 */
- (void) applyStylingWithAnimationISS;

@end
