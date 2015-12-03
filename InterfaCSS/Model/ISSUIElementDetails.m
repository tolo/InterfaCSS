//
//  ISSUIElementDetails.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-03-19.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSUIElementDetails.h"

#import <objc/runtime.h>
#import "ISSPropertyRegistry.h"
#import "ISSDownloadableResource.h"
#import "ISSUpdatableValue.h"
#import "ISSPropertyDeclaration.h"

NSString* const ISSIndexPathKey = @"ISSIndexPathKey";
NSString* const ISSPrototypeViewInitializedKey = @"ISSPrototypeViewInitializedKey";
NSString* const ISSUIElementDetailsResetCachedDataNotificationName = @"ISSUIElementDetailsResetCachedDataNotification";


@implementation NSObject (ISSUIElementDetails)

@dynamic elementDetailsISS;

- (void) setElementDetailsISS:(ISSUIElementDetails*)elementDetailsISS {
     objc_setAssociatedObject(self, @selector(elementDetailsISS), elementDetailsISS, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ISSUIElementDetails*) elementDetailsISS {
    return objc_getAssociatedObject(self, @selector(elementDetailsISS));
}

@end


@interface ISSUIElementDetails ()

@property (nonatomic, weak, readwrite) UIView* parentView;

@property (nonatomic, strong, readwrite) NSString* elementStyleIdentityPath;
@property (nonatomic, strong) NSString* elementStyleIdentity;

@property (nonatomic, strong, readwrite) NSDictionary* validNestedElements;

@property (nonatomic, weak, readwrite) UIViewController* closestViewController;

@property (nonatomic, readwrite) BOOL ancestorHasElementId;
@property (nonatomic, readwrite) BOOL ancestorUsesCustomElementStyleIdentity;

@property (nonatomic, strong, readwrite) NSSet* disabledProperties;

@property (nonatomic, strong) NSMutableDictionary* additionalDetails;

@property (nonatomic, strong) NSMutableDictionary* prototypes;

@property (nonatomic, strong) NSMapTable* observedUpdatableValues;

@end

@implementation ISSUIElementDetails

#pragma mark - Lifecycle

- (id) initWithUIElement:(id)uiElement {
    self = [super init];
    if (self) {
        _uiElement = uiElement;
        [self parentElement]; // Make sure weak reference to super view is set directly

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetCachedData) name:ISSUIElementDetailsResetCachedDataNotificationName object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ISSUIElementDetailsResetCachedDataNotificationName object:nil];
}


#pragma mark - NSCopying

- (id) copyWithZone:(NSZone*)zone {
    ISSUIElementDetails* copy = [[(id)self.class allocWithZone:zone] initWithUIElement:self->_uiElement];
    copy->_parentElement = self->_parentElement;
    
    copy->_closestViewController = self->_closestViewController; // Calculated and cached property - avoid calculation on copy
    
    copy->_validNestedElements = _validNestedElements; // Calculated and cached property - avoid calculation on copy
    
    copy.elementId = self.elementId;
    
    copy.layout = self.layout;

    copy.elementStyleIdentity = self.elementStyleIdentity;
    copy.elementStyleIdentityPath = self.elementStyleIdentityPath;
    copy.ancestorHasElementId = self.ancestorHasElementId;
    copy.customElementStyleIdentity = self.customElementStyleIdentity;
    copy.ancestorUsesCustomElementStyleIdentity = self.ancestorUsesCustomElementStyleIdentity;

    copy.cachedDeclarations = self.cachedDeclarations;
    
    copy.canonicalType = self.canonicalType;
    copy.styleClasses = self.styleClasses;

    copy.stylingApplied = self.stylingApplied;
    copy.stylingDisabled = self.stylingDisabled;
    copy.stylesContainPseudoClassesOrDynamicProperties = self.stylesContainPseudoClassesOrDynamicProperties;

    copy.willApplyStylingBlock = self.willApplyStylingBlock;
    copy.didApplyStylingBlock = self.didApplyStylingBlock;

    copy.disabledProperties = self.disabledProperties;
    
    copy.additionalDetails = self.additionalDetails;
    
    copy.prototypes = self.prototypes;

    return copy;
}


#pragma mark - Utils

- (id) findParent:(UIView*)parentView ofClass:(Class)class {
    if( !parentView ) return nil;
    else if( [parentView isKindOfClass:class] ) return parentView;
    else return [self findParent:parentView.superview ofClass:class];
}

- (void) updateElementStyleIdentity {
    if( self.customElementStyleIdentity ) {
        self.elementStyleIdentity = self.elementStyleIdentityPath = [NSString stringWithFormat:@"@%@", self.customElementStyleIdentity]; // Prefix custom style id with @
    }
    else if( self.elementId ) {
        self.elementStyleIdentity = self.elementStyleIdentityPath = [NSString stringWithFormat:@"#%@", self.elementId]; // Prefix element id with #
    }
    else if( self.nestedElementKeyPath ) {
        self.elementStyleIdentity = self.elementStyleIdentityPath = [NSString stringWithFormat:@"$%@", self.nestedElementKeyPath]; // Prefix nested elements with $
    }
    else if( self.styleClasses ) {
        NSArray* styleClasses = [[self.styleClasses allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            return [obj1 compare:obj2];
        }];
        NSMutableString* str = [NSMutableString stringWithString:NSStringFromClass(self.canonicalType)];
        [str appendString:@"["];
        [str appendString:[styleClasses componentsJoinedByString:@","]];
        [str appendString:@"]"];
        self.elementStyleIdentity = [str copy];
    }
    else {
        self.elementStyleIdentity = NSStringFromClass(self.canonicalType);
    }
}

- (void) updateElementStyleIdentityPath {
    // Update style identity of element, if needed
    [self elementStyleIdentity];
    
    if( self.elementId || self.customElementStyleIdentity ) return; // If element uses element Id, or custom style id, elementStyleIdentityPath will have been set by call above, and will only contain the element Id itself

    ISSUIElementDetails* parentDetails = [[InterfaCSS interfaCSS] detailsForUIElement:self.parentElement];
    NSString* parentStyleIdentityPath = parentDetails.elementStyleIdentityPath;
    // Check if an ancestor has an element id (i.e. style identity path will contain #someParentElementId) - this information will be used to determine if styles can be cacheable or not
    self.ancestorHasElementId = [parentStyleIdentityPath hasPrefix:@"#"] || [parentStyleIdentityPath rangeOfString:@" #"].location != NSNotFound;
    self.ancestorUsesCustomElementStyleIdentity = [parentStyleIdentityPath hasPrefix:@"@"] || [parentStyleIdentityPath rangeOfString:@" @"].location != NSNotFound;
    
    // Concatenate parent elementStyleIdentityPath of parent with the elementStyleIdentity of this element, separated by a space:
    if( parentStyleIdentityPath ) self.elementStyleIdentityPath = [NSString stringWithFormat:@"%@ %@", parentDetails.elementStyleIdentityPath, self.elementStyleIdentity];
    else self.elementStyleIdentityPath = self.elementStyleIdentity;
}


#pragma mark - Public interface

- (void) setLayout:(ISSLayout*)layout {
    _layout = layout;
    
    // Whenever layout is changed, make sure layout is executed for closest parent ISSLayoutContextView
    UIView* layoutContextView = [self findParent:self.parentView ofClass:ISSLayoutContextView.class];
    [layoutContextView setNeedsLayout];
}

- (BOOL) addedToViewHierarchy {
    return self.parentView.window || (self.parentView.class == UIWindow.class) || (self.view.class == UIWindow.class);
}

- (BOOL) stylesCacheable {
    return (self.elementId != nil) || self.ancestorHasElementId
        || (self.customElementStyleIdentity != nil)  || self.ancestorUsesCustomElementStyleIdentity
        || self.addedToViewHierarchy;
}

- (BOOL) stylingAppliedAndDisabled {
    return self.stylingDisabled && self.stylingApplied;
}

- (BOOL) stylingAppliedAndStatic {
    return self.stylingApplied && !self.stylesContainPseudoClassesOrDynamicProperties;
}

+ (void) resetAllCachedData {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSUIElementDetailsResetCachedDataNotificationName object:nil];
}

- (void) resetCachedViewHierarchyRelatedData {
    if( !self.elementId && !self.customElementStyleIdentity ) self.elementStyleIdentityPath = nil; // Reset style identity path, but only if this element doesn't use an element id
    self.ancestorHasElementId = NO;
    self.ancestorUsesCustomElementStyleIdentity = NO;
    _closestViewController = nil;
    self.ownerElement = nil;
}

- (void) resetCachedData {
    // Identity and structure:
    _canonicalType = nil;
    
    [self resetCachedViewHierarchyRelatedData];

    _validNestedElements = nil;

    // Cached styles:
    self.stylingApplied = NO;
    self.cachedDeclarations = nil; // Note: this just clears a weak ref - cache will still remain in class InterfaCSS (unless cleared at the same time)
}

- (UIView*) view {
    return [self.uiElement isKindOfClass:UIView.class] ? self.uiElement : nil;
}

- (id) parentElement {
    if( !_parentElement ) {
        if( [_uiElement isKindOfClass:[UIView class]] ) {
            UIView* view = (UIView*)_uiElement;
            _parentView = view.superview; // Update cached parentView reference
            UIViewController* closestViewController = [self.class closestViewController:view];
            if( closestViewController.view == view ) {
                _parentElement = closestViewController;
            } else {
                _parentElement = _parentView; // In case parent element is view - _parentElement is the same as _parentView
                _closestViewController = closestViewController;
            }
        }
        else if( [_uiElement isKindOfClass:[UIViewController class]] ) {
            _parentElement = ((UIViewController*)self.uiElement).view.superview; // User the super view of the view controller root view
        }
    }
    return _parentElement;
}

- (id) ownerElement {
    if( _ownerElement ) return _ownerElement;
    else return self.parentElement;
}

- (UIViewController*) parentViewController {
    return [self.parentElement isKindOfClass:UIViewController.class] ? self.parentElement : nil;
}

- (UIViewController*) closestViewController {
    if( !_closestViewController ) {
        _closestViewController = [self.class closestViewController:self.view];
    }
    return _closestViewController;
}

+ (UIViewController*) closestViewController:(UIView*)view {
    for (UIView* currentView = view; currentView; currentView = currentView.superview) {
        UIResponder* nextResponder = currentView.nextResponder;
        if ( [nextResponder isKindOfClass:UIViewController.class] ) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

- (Class) canonicalType {
    if( !_canonicalType ) {
        ISSPropertyRegistry* registry = [InterfaCSS sharedInstance].propertyRegistry;
        _canonicalType = [registry canonicalTypeClassForClass:[self.uiElement class]];
        if ( !_canonicalType ) _canonicalType = [self.uiElement class];
    }
    return _canonicalType;
}

- (void) setElementId:(NSString*)elementId {
    _elementId = elementId;
    _elementStyleIdentityPath = _elementStyleIdentity = nil; // Reset style identity to force refresh
}

- (void) setStyleClasses:(NSSet*)styleClasses {
    _styleClasses = styleClasses;
    _elementStyleIdentityPath = _elementStyleIdentity = nil; // Reset style identity to force refresh
}

- (void) setCustomElementStyleIdentity:(NSString*)customElementStyleIdentity {
    _customElementStyleIdentity = customElementStyleIdentity;
    _elementStyleIdentityPath = _elementStyleIdentity = nil; // Reset style identity to force refresh
}

- (NSString*) elementStyleIdentity {
    if( !_elementStyleIdentity ) {
        [self updateElementStyleIdentity];
    }
    return _elementStyleIdentity;
}

- (NSString*) elementStyleIdentityPath {
    if( !_elementStyleIdentityPath ) {
        [self updateElementStyleIdentityPath];
    }
    return _elementStyleIdentityPath;
}

- (NSMutableDictionary*) additionalDetails {
    if( !_additionalDetails ) _additionalDetails = [[NSMutableDictionary alloc] init];
    return _additionalDetails;
}

- (void) setPosition:(NSInteger*)position count:(NSInteger*)count fromIndexPath:(NSIndexPath*)indexPath countBlock:(NSInteger(^)(NSIndexPath*))countBlock {
    if( !indexPath ) indexPath = self.additionalDetails[ISSIndexPathKey];
    if( indexPath ) {
        *position = indexPath.row;
        *count = countBlock(indexPath);
    }
}

- (void) typeQualifiedPositionInParent:(NSInteger*)position count:(NSInteger*)count {
    *position = NSNotFound;
    *count = 0;

    if( [self.uiElement isKindOfClass:UITableViewCell.class] ) {
        UITableView* tv = [self findParent:self.parentView ofClass:UITableView.class];
        NSIndexPath* _indexPath = [tv indexPathForCell:(UITableViewCell*)self.uiElement];
        [self setPosition:position count:count fromIndexPath:_indexPath countBlock:^NSInteger(NSIndexPath* indexPath) {
            return [tv numberOfRowsInSection:indexPath.section];;
        }];
    }
    else if( [self.uiElement isKindOfClass:UICollectionViewCell.class] ) {
        UICollectionView* cv = [self findParent:self.parentView ofClass:UICollectionView.class];
        NSIndexPath* _indexPath = [cv indexPathForCell:(UICollectionViewCell*)self.uiElement];
        [self setPosition:position count:count fromIndexPath:_indexPath countBlock:^NSInteger(NSIndexPath* indexPath) {
            return [cv numberOfItemsInSection:indexPath.section];
        }];
    }
    else if( [self.uiElement isKindOfClass:UICollectionReusableView.class] ) {
        UICollectionView* cv = [self findParent:self.parentView ofClass:UICollectionView.class];
        [self setPosition:position count:count fromIndexPath:nil countBlock:^NSInteger(NSIndexPath* indexPath) {
            return [cv numberOfItemsInSection:indexPath.section];
        }];
    }
    else if( [self.uiElement isKindOfClass:UIBarButtonItem.class] && [self.parentView isKindOfClass:UINavigationBar.class] ) {
        UINavigationBar* navBar = (UINavigationBar*)self.parentView;
        if( navBar ) {
            *position = [navBar.items indexOfObject:self.uiElement];
            *count = navBar.items.count;
        }
    }
#if TARGET_OS_TV == 0
    else if( [self.uiElement isKindOfClass:UIBarButtonItem.class] && [self.parentView isKindOfClass:UIToolbar.class] ) {
        UIToolbar* toolbar = (UIToolbar*)self.parentView;
        if( toolbar ) {
            *position = [toolbar.items indexOfObject:self.uiElement];
            *count = toolbar.items.count;
        }
    }
#endif
    else if( [self.uiElement isKindOfClass:UITabBarItem.class] && [self.parentView isKindOfClass:UITabBar.class] ) {
        UITabBar* tabbar = (UITabBar*)self.parentView;
        if( tabbar ) {
            *position = [tabbar.items indexOfObject:self.uiElement];
            *count = tabbar.items.count;
        }
    }
    else if( self.parentView ) {
        ISSPropertyRegistry* registry = [InterfaCSS sharedInstance].propertyRegistry;
        Class uiKitClass = [registry canonicalTypeClassForClass:[self.uiElement class]];
        for(UIView* v in self.parentView.subviews) {
            if( [v.class isSubclassOfClass:uiKitClass] ) {
                if( v == self.uiElement ) *position = *count;
                (*count)++;
            }
        }
    }
}

- (void) addDisabledProperty:(ISSPropertyDefinition*)disabledProperty {
    if( !disabledProperty ) return;
    if( !_disabledProperties ) _disabledProperties = [NSSet setWithObject:disabledProperty];
    else _disabledProperties = [_disabledProperties setByAddingObject:disabledProperty];
}

- (void) removeDisabledProperty:(ISSPropertyDefinition*)disabledProperty {
    if( !disabledProperty || !_disabledProperties ) return;
    NSMutableSet* disabledProperties = [NSMutableSet setWithSet:_disabledProperties];
    [disabledProperties removeObject:disabledProperty];
    _disabledProperties = [disabledProperties copy];
}

- (BOOL) hasDisabledProperty:(ISSPropertyDefinition*)disabledProperty {
    return [_disabledProperties containsObject:disabledProperty];
}

- (void) clearDisabledProperties {
    _disabledProperties = nil;
}

- (NSMutableDictionary*) prototypes {
    if( !_prototypes ) _prototypes = [[NSMutableDictionary alloc] init];
    return _prototypes;
}

- (id) childElementForKeyPath:(NSString*)keyPath {
    NSString* validKeyPath = self.validNestedElements[[keyPath lowercaseString]];
    if( validKeyPath ) {
        return [self.uiElement valueForKeyPath:validKeyPath];
    }
    return nil;
}

- (NSDictionary*) validNestedElements {
    if( !_validNestedElements ) {
        ISSPropertyRegistry* registry = [InterfaCSS sharedInstance].propertyRegistry;
        NSSet* validPrefixPathsForClass = [registry validPrefixKeyPathsForClass:[self.uiElement class]];
        NSMutableDictionary* validNestedElements = [NSMutableDictionary dictionary];
        if( validPrefixPathsForClass.count ) {
            for(NSString* path in validPrefixPathsForClass) {
                validNestedElements[[path lowercaseString]] = path;
            }
        }
        _validNestedElements = validNestedElements;
    }
    return _validNestedElements;
}

- (NSArray*) childElementsForElement {
    //NSArray* subviews = self.view.subviews ?: [[NSArray alloc] init];
    NSMutableOrderedSet* subviews = self.view.subviews ? [[NSMutableOrderedSet alloc] initWithArray:self.view.subviews] : [[NSMutableOrderedSet alloc] init];
    
#if TARGET_OS_TV == 0
    // Special case: UIToolbar - add toolbar items to "subview" list
    if( [self.view isKindOfClass:UIToolbar.class] ) {
        UIToolbar* toolbar = (UIToolbar*)self.view;
        if( toolbar.items ) [subviews addObjectsFromArray:toolbar.items];
    }
    // Special case: UINavigationBar - add nav bar items to "subview" list
    else
#endif
    if( [self.view isKindOfClass:UINavigationBar.class] ) {
        UINavigationBar* navigationBar = (UINavigationBar*)self.view;

        NSMutableArray* additionalSubViews = [NSMutableArray array];
        for(id item in navigationBar.items) {
            if( [item isKindOfClass:UINavigationItem.class] ) {
                UINavigationItem* navigationItem = (UINavigationItem*)item;
#if TARGET_OS_TV == 0
                if( navigationItem.backBarButtonItem ) [additionalSubViews addObject:navigationItem.backBarButtonItem];
#endif
                if( navigationItem.leftBarButtonItems.count ) [additionalSubViews addObjectsFromArray:navigationItem.leftBarButtonItems];
                if( navigationItem.titleView ) [additionalSubViews addObject:navigationItem.titleView];
                if( navigationItem.rightBarButtonItems.count ) [additionalSubViews addObjectsFromArray:navigationItem.rightBarButtonItems];
            } else {
                [additionalSubViews addObject:item];
            }
        }
        [subviews addObjectsFromArray:additionalSubViews];
    }
    // Special case: UITabBar - add tab bar items to "subview" list
    else if( [self.view isKindOfClass:UITabBar.class] ) {
        UITabBar* tabBar = (UITabBar*)self.view;
        if( tabBar.items ) [subviews addObjectsFromArray:tabBar.items];
    }
    
    // Add any valid nested elements (valid property prefix key paths) to the subviews list
    for(NSString* nestedElementKeyPath in self.validNestedElements.allValues) {
        id nestedElement = [self.uiElement valueForKeyPath:nestedElementKeyPath];
        if( nestedElement && nestedElement != self.uiElement ) {
            ISSUIElementDetails* childDetails = [[InterfaCSS interfaCSS] detailsForUIElement:nestedElement];
            // Set the ownerElement and nestedElementPropertyName to make sure that the nested property can be properly matched by ISSNestedElementSelector
            // (even if it's not a direct subview) and that it has a unique styling identity (in its sub tree)
            childDetails.ownerElement = self.uiElement;
            childDetails.nestedElementKeyPath = nestedElementKeyPath;

            [subviews addObject:nestedElement];
        }
    }
    
    return [subviews array];
}

- (void) observeUpdatableValue:(ISSUpdatableValue*)value forProperty:(ISSPropertyDeclaration*)propertyDeclaration {
    if( [[self.observedUpdatableValues objectForKey:propertyDeclaration] isEqual:value] ) return;

    if( !self.observedUpdatableValues ) {
        self.observedUpdatableValues = [NSMapTable weakToWeakObjectsMapTable];
    }
    [value addValueUpdateObserver:self selector:@selector(updatableValueUpdated:)];
    [self.observedUpdatableValues setObject:value forKey:propertyDeclaration];
}

- (void) stopObservingUpdatableValueForProperty:(ISSPropertyDeclaration*)propertyDeclaration {
    ISSUpdatableValue* value = [self.observedUpdatableValues objectForKey:propertyDeclaration];
    if( value ) {
        [value removeValueUpdateObserver:self];
        [self.observedUpdatableValues removeObjectForKey:propertyDeclaration];
        if( self.observedUpdatableValues.count == 0 ) self.observedUpdatableValues = nil;
    }
}

- (void) updatableValueUpdated:(NSNotification*)notification {
    [[InterfaCSS sharedInstance] applyStyling:self.uiElement includeSubViews:NO force:YES];
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"ElementDetails(%@)", self.elementStyleIdentity];
}

@end
