//
//  ISSUIElementDetails.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-03-19.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "InterfaCSS.h"

extern const NSString* ISSTableViewCellIndexPathKey;

// InterfaCSS class extension
@interface InterfaCSS ()
- (ISSUIElementDetails*) detailsForUIElement:(id)uiElement;
@end


@interface ISSUIElementDetails : NSObject<NSCopying>

@property (nonatomic, weak, readonly) id uiElement;
@property (nonatomic, weak, readonly) UIView* view;
@property (nonatomic, weak) UIView* parentView;
@property (nonatomic, readonly) BOOL addedToViewHierarchy;

@property (nonatomic, strong, readonly) NSString* elementStyleIdentity;

@property (nonatomic, weak) Class canonicalType;
@property (nonatomic, strong) NSSet* styleClasses;

@property (nonatomic) BOOL stylingApplied;
@property (nonatomic) BOOL stylingDisabled;

@property (nonatomic, copy) ISSWillApplyStylingNotificationBlock willApplyStylingBlock;
@property (nonatomic, copy) ISSDidApplyStylingNotificationBlock didApplyStylingBlock;

@property (nonatomic, strong, readonly) NSSet* disabledProperties;

@property (nonatomic, strong, readonly) NSMutableDictionary* additionalDetails;


- (id) initWithUIElement:(id)uiElement;

- (void) resetCachedData;

- (void) setCustomElementStyleIdentity:(NSString*)identityPath;

- (void) typeQualifiedPositionInParent:(NSInteger*)position count:(NSInteger*)count;

- (void) addDisabledProperty:(ISSPropertyDefinition*)disabledProperty;
- (void) removeDisabledProperty:(ISSPropertyDefinition*)disabledProperty;
- (void) clearDisabledProperties;

@end
