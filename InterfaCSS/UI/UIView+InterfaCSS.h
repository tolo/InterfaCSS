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
 * Callback block for getting notified when styles will be applied to this view. Makes it possible to prevent some properties from being applied, by returning a different 
 * list of properties than the list passed as a parameter to the block.
 */
@property (nonatomic, copy) ISSWillApplyStylingNotificationBlock willApplyStylingBlockISS;

/**
 * Callback block for getting notified when styles have been applied to this view. Makes it possible to for instance adjust property values or update dependent properties.
 */
@property (nonatomic, copy) ISSDidApplyStylingNotificationBlock didApplyStylingBlockISS;

/**
 * A custom styling identity that overrides the default mechanism for assigning styling identities to elements (which essentially involves building a full view
 * hierarchy "path" of an element, such as "UIWindow UIView UIView[class]"). The styling identity is effectively the cache key for the styling information
 * associated with a UI element, and setting this to a custom value makes it possible to (further) increase performance by sharing cached styles with
 * UI elements located in different places in the view hierarchy for instance. Examples of places where setting this property can be useful is for instance
 * the root view of a view controller, a custom UI component or other views that can be styles regardless of the ancestor view hierarchy.
 *
 * NOTE: When using a custom styling identity for a view, avoid using style declarations that depends on the view hierarchy above that view (i.e. use of chained
 * or nested selectors that ).
 */
@property (nonatomic, strong) NSString* customStylingIdentityISS;

/** An optional element identifier for this view. May be used to find a view using the method `subviewWithElementId:`. */
@property (nonatomic, strong) NSString* elementIdISS;

/** Flag indicating if styling is enabled for this view. */
@property (nonatomic, readonly) BOOL stylingEnabledISS;

/** Flag indicating if styling has been successfully applied to this view. */
@property (nonatomic, readonly) BOOL stylingAppliedISS;


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
- (BOOL) addStyleClassISS:(NSString*)styleClass;

/**
 * Adds a new styles class to this view, if not already present. If `scheduleStyling` is `YES`, asynchronous re-styling of this view is triggered.
 */
- (BOOL) addStyleClassISS:(NSString*)styleClass scheduleStyling:(BOOL)scheduleStyling;

/**
 * Adds a new styles class to this view, if not already present. Triggers an asynchronous re-styling of this view, optionally within an animation block.
 */
- (BOOL) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;

/**
 * Adds a new styles class to this view, if not already present. If `scheduleStyling` is `YES`, asynchronous re-styling of this view is triggered, optionally within an animation block.
 */
- (BOOL) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated scheduleStyling:(BOOL)scheduleStyling;


/**
 * Removes the specified style class from this view. Triggers an asynchronous re-styling of this view.
 */
- (BOOL) removeStyleClassISS:(NSString*)styleClass;

/**
 * Removes the specified style class from this view. If `scheduleStyling` is `YES`, asynchronous re-styling of this view is triggered.
 */
- (BOOL) removeStyleClassISS:(NSString*)styleClass scheduleStyling:(BOOL)scheduleStyling;

/**
 * Removes the specified style class from this view. Triggers an asynchronous re-styling of this view, within an animation block.
 */
- (BOOL) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;

/**
 * Removes the specified style class from this view. If `scheduleStyling` is `YES`, asynchronous re-styling of this view is triggered, optionally within an animation block.
 */
- (BOOL) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated scheduleStyling:(BOOL)scheduleStyling;


/**
 * Schedules an asynchronous re-styling of this view.
 */
- (void) scheduleApplyStylingISS;

/**
 * Cancel previously scheduled styling of this view.
 */
- (void) cancelScheduledApplyStylingISS;

/**
 * Schedules an asynchronous re-styling of this view. The re-styling will be performed within an animation block.
 */
- (void) scheduleApplyStylingISS:(BOOL)animated;


/**
 * Applies styling to this view, if not already applied.
 */
- (void) applyStylingISS;

/**
 * Applies styling once to this view and then disables further styling. Call `enabledStylingISS` to re-enable styling.
 */
- (void) applyStylingOnceISS;

/**
 * Applies styling to this view. If `force` is `YES`, styling will always be applied (i.e. properties will be set), otherwise styling will only
 * be applied if not already applied.
 */
- (void) applyStylingISS:(BOOL)force;

/**
 * Applies styling to this view within an animation block.
 */
- (void) applyStylingWithAnimationISS;

/**
 * Disables styling of this view, i.e. InterfaCSS will stop applying styling information to this view and it's children, but any styles that
 * have already been applied will remain. This method can for instance be useful for setting initial styles for a view via InterfaCSS, and then take control
 * of the styling manually, without the risk of InterfaCSS overwriting any modified properties.
 *
 * Call `enabledStylingISS` to re-enable styling.
 */
- (void) disableStylingISS;

/**
 * Re-enables styling of this view.
 */
- (void) enableStylingISS;

/**
 * Clears all cached styling information associated with this view and all its subviews.
 */
- (void) clearCachedStylesISS;


/**
 * Disables styling of a property in this view, i.e. InterfaCSS will stop applying styling information to the property, but any value that has
 * already been applied will remain. This method can for instance be useful for setting initial styles for a view via InterfaCSS, and then take control of the
 * styling manually, without the risk of InterfaCSS overwriting property values.
 *
 * Call `enableStylingForPropertyISS:` to re-enable styling.
 */
- (void) disableStylingForPropertyISS:(NSString*)propertyName;

/**
 * Re-enables styling of a property.
 */
- (void) enableStylingForPropertyISS:(NSString*)propertyName;


/** Finds a sub view with the specified element identifier. */
- (id) subviewWithElementId:(NSString*)elementId;

@end
