//
//  ISSElementStylingProxy.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


// TODO: Rename to ISSElementStylingProxy? And move methods fron old UIView+InterfaCSS category here?


@class ISSUpdatableValue, ISSPropertyDeclaration, ISSStylingManager, ISSUpdatableValueObserver, ISSElementStylingProxy;


#pragma mark - Block type definitions

typedef NSArray* _Nonnull (^ISSWillApplyStylingNotificationBlock)(NSArray* _Nonnull propertyDeclarations);
typedef void (^ISSDidApplyStylingNotificationBlock)(NSArray* _Nonnull propertyDeclarations);

typedef id _Nullable (^ISSElementStylingProxyVisitorBlock)(ISSElementStylingProxy* elementDetails);


extern NSNotificationName const ISSMarkCachedStylingInformationAsDirtyNotificationName;


/**
 * Styling proxy class
 */
@interface ISSElementStylingProxy : NSObject<NSCopying>

@property (nonatomic, weak, readonly, nullable) id uiElement;
@property (nonatomic, weak, readonly, nullable) UIView* view; // uiElement, if instance of UIView, otherwise nil
@property (nonatomic, weak, readonly, nullable) id parentElement;
@property (nonatomic, weak, nullable) id ownerElement; // Element holding a property reference (which is defined validNestedElements) to this element, otherwise parentElement
@property (nonatomic, weak, readonly, nullable) UIView* parentView; // parentElement, if instance of UIView, otherwise nil

@property (nonatomic, weak, readonly, nullable) UIViewController* parentViewController; // Direct parent view controller of element, i.e. parentElement, if instance of UIViewController, otherwise nil
@property (nonatomic, weak, readonly, nullable) UIViewController* closestViewController; // Closest ancestor view controller

@property (nonatomic, readonly, nullable) NSDictionary* validNestedElements;

@property (nonatomic, strong, nullable) NSString* elementId;
@property (nonatomic, strong, nullable) Class canonicalType;
@property (nonatomic, strong, nullable) NSSet<NSString*>* styleClasses;
@property (nonatomic, strong, nullable) NSString* styleClass; // Convenience property for cases when only a single style class is required (if more than one style class is set, this property may return any of them)

@property (nonatomic, strong, nullable) NSString* nestedElementKeyPath; // The key path / property name by which this element is know as in the ownerElement

@property (nonatomic, strong, readonly, nullable) NSString* elementStyleIdentityPath;
@property (nonatomic, readonly) BOOL ancestorHasElementId;
@property (nonatomic, strong, nullable) NSString* customElementStyleIdentity;
@property (nonatomic, readonly) BOOL ancestorUsesCustomElementStyleIdentity;

@property (nonatomic, weak, nullable) NSArray* cachedDeclarations; // Optimization for quick access to cached declarations
@property (nonatomic) BOOL stylesFullyResolved;

@property (nonatomic) BOOL stylingApplied; // Indicates if styles have been applied to element  // TODO: Maybe we don't need this in core...
@property (nonatomic) BOOL stylingStatic; // Indicates that applied styling contains no pseudo classes for instance
@property (nonatomic, readonly) BOOL addedToViewHierarchy;
@property (nonatomic, readonly) BOOL stylesCacheable;

@property (nonatomic, copy, nullable) ISSWillApplyStylingNotificationBlock willApplyStylingBlock;
@property (nonatomic, copy, nullable) ISSDidApplyStylingNotificationBlock didApplyStylingBlock;

@property (nonatomic) BOOL cachedStylingInformationDirty;

@property (nonatomic, readonly) BOOL isVisiting;


- (instancetype) initWithUIElement:(id)uiElement;
- (void) resetWith:(ISSStylingManager*)stylingManager;


- (BOOL) checkForUpdatedParentElement;
+ (void) markAllCachedStylingInformationAsDirty;


- (void) addStyleClass:(NSString*)styleClass;
- (void) removeStyleClass:(NSString*)styleClass;
- (BOOL) hasStyleClass:(NSString*)styleClass;


- (nullable id) childElementForKeyPath:(NSString*)keyPath;
- (BOOL) addValidNestedElementKeyPath:(NSString*)keyPath;

- (ISSUpdatableValueObserver*) addObserverForValue:(ISSUpdatableValue*)value inProperty:(ISSPropertyDeclaration*)propertyDeclaration withBlock:(void (^)(NSNotification* note))block;

- (nullable id) visitExclusivelyWithScope:(const void*)scope visitorBlock:(ISSElementStylingProxyVisitorBlock)visitorBlock;


@end


NS_ASSUME_NONNULL_END
