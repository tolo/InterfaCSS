//
//  ISSUIElementDetails.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-03-19.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "InterfaCSS.h"

@class ISSRelativeRectValue;

extern NSString* const ISSIndexPathKey;
extern NSString* const ISSPrototypeViewInitializedKey;


@interface NSObject (ISSUIElementDetails)
@property (nonatomic, strong) ISSUIElementDetails* elementDetailsISS;
@end


// InterfaCSS class extension
@interface InterfaCSS ()
- (ISSUIElementDetails*) detailsForUIElement:(id)uiElement;
@end


@interface ISSUIElementDetails : NSObject<NSCopying>

@property (nonatomic, weak, readonly) id uiElement;
@property (nonatomic, weak, readonly) UIView* view;
@property (nonatomic, weak) UIView* parentView;

@property (nonatomic, weak, readonly) UIViewController* parentViewController;

@property (nonatomic, strong) NSString* elementId;

@property (nonatomic, readonly) BOOL addedToViewHierarchy;
@property (nonatomic, readonly) BOOL stylesCacheable;

@property (nonatomic, strong, readonly) NSString* elementStyleIdentity;
@property (nonatomic, readonly) BOOL elementStyleIdentityResolved;
@property (nonatomic, weak) NSMutableArray* cachedDeclarations; // Optimization for quick access to cached declarations
@property (nonatomic) BOOL usingCustomElementStyleIdentity;
@property (nonatomic) BOOL ancestorUsesCustomElementStyleIdentity;

@property (nonatomic, weak) Class canonicalType;
@property (nonatomic, strong) NSSet* styleClasses;

@property (nonatomic) BOOL stylingApplied;
@property (nonatomic) BOOL stylingDisabled;

@property (nonatomic, copy) ISSWillApplyStylingNotificationBlock willApplyStylingBlock;
@property (nonatomic, copy) ISSDidApplyStylingNotificationBlock didApplyStylingBlock;

@property (nonatomic, strong, readonly) NSSet* disabledProperties;

@property (nonatomic, strong, readonly) NSMutableDictionary* additionalDetails;

@property (nonatomic, strong, readonly) NSMutableDictionary* prototypes;


- (id) initWithUIElement:(id)uiElement;

+ (void) resetAllCachedData;
- (void) resetCachedData;

- (void) setCustomElementStyleIdentity:(NSString*)identityPath;

- (void) typeQualifiedPositionInParent:(NSInteger*)position count:(NSInteger*)count;

- (void) addDisabledProperty:(ISSPropertyDefinition*)disabledProperty;
- (void) removeDisabledProperty:(ISSPropertyDefinition*)disabledProperty;
- (BOOL) hasDisabledProperty:(ISSPropertyDefinition*)disabledProperty;
- (void) clearDisabledProperties;

@end
