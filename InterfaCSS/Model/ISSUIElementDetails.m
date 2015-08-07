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

@property (nonatomic, strong, readwrite) NSString* elementStyleIdentityPath;
@property (nonatomic, strong) NSString* elementStyleIdentity;

@property (nonatomic, strong) NSDictionary* validNestedElements;

@property (nonatomic, strong) NSMutableDictionary* additionalDetails;

@property (nonatomic, strong) NSMutableDictionary* prototypes;

@end

@implementation ISSUIElementDetails {
    __weak UIViewController* _parentViewController;
}

#pragma mark - Lifecycle

- (id) initWithUIElement:(id)uiElement {
    self = [super init];
    if (self) {
        _uiElement = uiElement;
        if( [uiElement isKindOfClass:[UIView class]] ) {
            UIView* view = (UIView*)uiElement;
            _parentElement = view.superview;
        }

        ISSPropertyRegistry* registry = [InterfaCSS sharedInstance].propertyRegistry;
        _canonicalType = [registry canonicalTypeClassForViewClass:[self.uiElement class]];
        if( !_canonicalType ) _canonicalType = [uiElement class];
        
        NSSet* validPrefixPathsForClass = [registry validPrefixKeyPathsForClass:[self.uiElement class]];
        if( validPrefixPathsForClass.count ) {
            NSMutableDictionary* validNestedElements = [NSMutableDictionary dictionary];
            for(NSString* path in validPrefixPathsForClass) {
                validNestedElements[[path lowercaseString]] = path;
            }
            _validNestedElements = validNestedElements;
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetCachedData) name:ISSUIElementDetailsResetCachedDataNotificationName object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ISSUIElementDetailsResetCachedDataNotificationName object:nil];
}


#pragma mark - NSCopying

- (id) copyWithZone:(NSZone*)zone {
    ISSUIElementDetails* copy = [[(id)self.class allocWithZone:zone] init];
    copy->_uiElement = self->_uiElement;
    copy->_parentElement = self->_parentElement;

    copy.elementId = self.elementId;

    copy.canonicalType = self.canonicalType;
    copy.styleClasses = self.styleClasses;

    copy.elementStyleIdentity = self.elementStyleIdentity;
    copy.elementStyleIdentityPath = self.elementStyleIdentityPath;
    copy.usingCustomElementStyleIdentity = self.usingCustomElementStyleIdentity;
    copy.ancestorUsesCustomElementStyleIdentity = self.ancestorUsesCustomElementStyleIdentity;

    copy.cachedDeclarations = self.cachedDeclarations;

    copy.stylingApplied = self.stylingApplied;
    copy.stylingDisabled = self.stylingDisabled;

    copy.willApplyStylingBlock = self.willApplyStylingBlock;
    copy.didApplyStylingBlock = self.didApplyStylingBlock;

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
    if( self.usingCustomElementStyleIdentity ) return;

    if( self.elementId ) {
        self.elementStyleIdentity = self.elementId;
    } else if( self.styleClasses ) {
        NSArray* styleClasses = [[self.styleClasses allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            return [obj1 compare:obj2];
        }];
        NSMutableString* str = [NSMutableString stringWithString:NSStringFromClass(self.canonicalType)];
        [str appendString:@"["];
        [str appendString:[styleClasses componentsJoinedByString:@","]];
        [str appendString:@"]"];
        self.elementStyleIdentity = [str copy];
    } else {
        self.elementStyleIdentity = NSStringFromClass(self.canonicalType);
    }
}

+ (void) buildElementStyleIdentityPath:(NSMutableString*)identityPath element:(ISSUIElementDetails*)element ancestorUsesCustomElementStyleIdentity:(BOOL*)ancestorUsesCustomElementStyleIdentity {
    // Update style identity of element, if needed
    if( !element.elementStyleIdentity ) {
        [element updateElementStyleIdentity];
    }

    if( element.parentElement && !element.usingCustomElementStyleIdentity ) {
        [self buildElementStyleIdentityPath:identityPath element:[[InterfaCSS interfaCSS] detailsForUIElement:element.parentElement] ancestorUsesCustomElementStyleIdentity:ancestorUsesCustomElementStyleIdentity];
    }
    if( identityPath.length ) [identityPath appendString:@" "];

    if( element.usingCustomElementStyleIdentity ) {
        [identityPath appendString:element.elementStyleIdentityPath];
        *ancestorUsesCustomElementStyleIdentity = YES;
    } else {
        [identityPath appendString:element.elementStyleIdentity];
    }
}


#pragma mark - Public interface

- (BOOL) addedToViewHierarchy {
    return self.parentView.window || (self.parentView.class == UIWindow.class) || (self.view.class == UIWindow.class);
}

- (BOOL) stylesCacheable {
    return self.usingCustomElementStyleIdentity || self.ancestorUsesCustomElementStyleIdentity || self.addedToViewHierarchy;
}

- (BOOL) stylingAppliedAndDisabled {
    return self.stylingDisabled && self.stylingApplied;
}

+ (void) resetAllCachedData {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSUIElementDetailsResetCachedDataNotificationName object:nil];
}

- (void) resetCachedData {
    // Identity and structure:
    if( !self.usingCustomElementStyleIdentity ) self.elementStyleIdentityPath = nil;
    self.ancestorUsesCustomElementStyleIdentity = NO;
    _parentViewController = nil;
    // Cached styles:
    self.stylingApplied = NO;
    self.cachedDeclarations = nil;
}

- (UIView*) view {
    return [self.uiElement isKindOfClass:UIView.class] ? self.uiElement : nil;
}

- (UIView*) parentView {
    return [self.parentElement isKindOfClass:UIView.class] ? self.parentElement : nil;
}

- (UIViewController*) parentViewController {
    if( !_parentViewController ) {
//        for (UIView* next = self.view.superview; next; next = next.superview) {
        for (UIView* currentView = self.view; currentView; currentView = currentView.superview) {
            UIResponder* nextResponder = currentView.nextResponder;
            if ( [nextResponder isKindOfClass:UIViewController.class] ) {
                _parentViewController = (UIViewController*)nextResponder;
                break;
            }
        }
    }
    return _parentViewController;
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
    self.usingCustomElementStyleIdentity = customElementStyleIdentity != nil;
    _elementStyleIdentity = _elementStyleIdentityPath = customElementStyleIdentity;
}

- (NSString*) elementStyleIdentityPath {
    NSString* path = _elementStyleIdentityPath;
    if( !path ) {
        // Build style identity path:
        NSMutableString* identityPath = [NSMutableString string];
        BOOL ancestorUsesCustomElementStyleIdentity = NO;
        [self.class buildElementStyleIdentityPath:identityPath element:self ancestorUsesCustomElementStyleIdentity:&ancestorUsesCustomElementStyleIdentity];
        self.ancestorUsesCustomElementStyleIdentity = ancestorUsesCustomElementStyleIdentity;
        path = [identityPath copy];
        if( self.parentElement && (ancestorUsesCustomElementStyleIdentity || self.parentView.window) ) {
            _elementStyleIdentityPath = path;
        }
    }
    return path;
}

- (BOOL) elementStyleIdentityPathResolved {
    return _elementStyleIdentityPath != nil;
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
    else if( [self.uiElement isKindOfClass:UIBarButtonItem.class] && [self.parentView isKindOfClass:UIToolbar.class] ) {
        UIToolbar* toolbar = (UIToolbar*)self.parentView;
        if( toolbar ) {
            *position = [toolbar.items indexOfObject:self.uiElement];
            *count = toolbar.items.count;
        }
    }
    else if( [self.uiElement isKindOfClass:UITabBarItem.class] && [self.parentView isKindOfClass:UITabBar.class] ) {
        UITabBar* tabbar = (UITabBar*)self.parentView;
        if( tabbar ) {
            *position = [tabbar.items indexOfObject:self.uiElement];
            *count = tabbar.items.count;
        }
    }
    else if( self.parentView ) {
        ISSPropertyRegistry* registry = [InterfaCSS sharedInstance].propertyRegistry;
        Class uiKitClass = [registry canonicalTypeClassForViewClass:[self.uiElement class]];
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

- (NSArray*) childElementsForElement {
    //NSArray* subviews = self.view.subviews ?: [[NSArray alloc] init];
    NSMutableOrderedSet* subviews = self.view.subviews ? [[NSMutableOrderedSet alloc] initWithArray:self.view.subviews] : [[NSMutableOrderedSet alloc] init];
    
    UIView* parentView = nil;
    // Special case: UIToolbar - add toolbar items to "subview" list
    if( [self.view isKindOfClass:UIToolbar.class] ) {
        UIToolbar* toolbar = (UIToolbar*)self.view;
        parentView = toolbar;
        if( toolbar.items ) [subviews addObjectsFromArray:toolbar.items];
    }
    // Special case: UINavigationBar - add nav bar items to "subview" list
    else if( [self.view isKindOfClass:UINavigationBar.class] ) {
        UINavigationBar* navigationBar = (UINavigationBar*)self.view;
        parentView = navigationBar;
        
        NSMutableArray* additionalSubViews = [NSMutableArray array];
        for(id item in navigationBar.items) {
            if( [item isKindOfClass:UINavigationItem.class] ) {
                UINavigationItem* navigationItem = (UINavigationItem*)item;
                if( navigationItem.backBarButtonItem ) [additionalSubViews addObject:navigationItem.backBarButtonItem];
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
        parentView = tabBar;
        if( tabBar.items ) [subviews addObjectsFromArray:tabBar.items];
    }
    
    // Add any valid nested elements (valid property prefix key paths) to the subviews list
    for(NSString* nestedElementKeyPath in self.validNestedElements.allValues) {
        id nestedElement = [self.uiElement valueForKeyPath:nestedElementKeyPath];
        if( nestedElement ) [subviews addObject:nestedElement];
    }
    
    return [subviews array];
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"ElementDetails(%@)", self.elementStyleIdentity];
}

@end
