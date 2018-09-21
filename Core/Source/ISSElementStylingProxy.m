//
//  ISSElementStylingProxy.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSElementStylingProxy+Protected.h"

#import <objc/runtime.h>

#import "ISSStylingManager.h"
#import "ISSPropertyManager.h"

#import "ISSPropertyDeclaration.h"
#import "ISSRuntimeIntrospectionUtils.h"
#import "ISSUpdatableValue.h"

#import "NSString+ISSAdditions.h"


NSNotificationName const ISSMarkCachedStylingInformationAsDirtyNotificationName = @"ISSMarkCachedStylingInformationAsDirtyNotificationName";


@implementation NSObject (ISSElementStylingProxy)

@dynamic iss_stylingProxy;

- (void) iss_setStylingProxy:(ISSElementStylingProxy*)elementDetailsISS {
     objc_setAssociatedObject(self, @selector(iss_stylingProxy), elementDetailsISS, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (ISSElementStylingProxy*) iss_stylingProxy {
    return objc_getAssociatedObject(self, @selector(iss_stylingProxy));
}

@end


@interface ISSElementStylingProxy ()

@property (nonatomic, weak, readwrite) UIView* parentView;
@property (nonatomic, weak, readwrite) id parentElement;

@property (nonatomic, strong, readwrite) NSString* elementStyleIdentityPath;
@property (nonatomic, strong) NSString* elementStyleIdentity;
@property (nonatomic, readwrite) BOOL ancestorHasElementId;
@property (nonatomic, readwrite) BOOL ancestorUsesCustomElementStyleIdentity;

@property (nonatomic, strong, readwrite) NSDictionary* validNestedElements;

@property (nonatomic, weak, readwrite) UIViewController* closestViewController;

@property (nonatomic, strong) NSMutableDictionary<NSString*, ISSUpdatableValueObserver*>* observedUpdatableValues;

@property (nonatomic, readwrite) BOOL isVisiting;
@property (nonatomic) const void* visitorScope;

@end

@implementation ISSElementStylingProxy

#pragma mark - Lifecycle

- (instancetype) initWithUIElement:(id)uiElement {
    if (self = [super init]) {
        _uiElement = uiElement;
        _visitorScope = NULL;
        
        _cachedStylingInformationDirty = YES; // Make as dirty to start with to make sure object is properly configured later (resetWith:)
        
        [self parentElement]; // Make sure weak reference to super view is set directly

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(markCachedStylingInformationAsDirty) name:ISSMarkCachedStylingInformationAsDirtyNotificationName object:nil];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ISSMarkCachedStylingInformationAsDirtyNotificationName object:nil];
}

- (void) resetWith:(ISSStylingManager*)stylingManager {
    self.canonicalType = [stylingManager.propertyManager canonicalTypeClassForClass:[self.uiElement class]] ?: [self.uiElement class];
    self.validNestedElements = nil;
    
    // Identity and structure:
    self.elementStyleIdentity = [self createElementStyleIdentity];
    self.elementStyleIdentityPath = nil; // Will result in re-evaluation of elementStyleIdentityPath, ancestorHasElementId and ancestorUsesCustomElementStyleIdentity in method below:
    [self updateElementStyleIdentityPathIfNeededWith:stylingManager];
    self.closestViewController = nil;
    
    // Reset fields related to style caching
    self.stylingApplied = NO;
    self.stylesFullyResolved = NO;
    self.stylingStatic = NO;
    self.cachedDeclarations = nil; // Note: this just clears a weak ref - cache will still remain in class InterfaCSS (unless cleared at the same time)
    
    self.cachedStylingInformationDirty = NO;
}


#pragma mark - NSCopying

- (id) copyWithZone:(NSZone*)zone {
    ISSElementStylingProxy* copy = [[(id)self.class allocWithZone:zone] initWithUIElement:self->_uiElement];
    copy->_parentElement = self->_parentElement;
    
    copy->_closestViewController = self->_closestViewController; // Calculated and cached property - avoid calculation on copy
    
    copy->_validNestedElements = _validNestedElements; // Calculated and cached property - avoid calculation on copy
    
    copy.elementId = self.elementId;
    
    copy->_elementStyleIdentity = _elementStyleIdentity;
    copy->_elementStyleIdentityPath = _elementStyleIdentityPath;
    copy.ancestorHasElementId = self.ancestorHasElementId;
    copy.customElementStyleIdentity = self.customElementStyleIdentity;
    copy.ancestorUsesCustomElementStyleIdentity = self.ancestorUsesCustomElementStyleIdentity;

    copy.cachedDeclarations = self.cachedDeclarations;
    
    copy.canonicalType = self.canonicalType;
    copy.styleClasses = self.styleClasses;

    copy.stylingApplied = self.stylingApplied;
    copy.stylingStatic = self.stylingStatic;

    copy.willApplyStylingBlock = self.willApplyStylingBlock;
    copy.didApplyStylingBlock = self.didApplyStylingBlock;

    return copy;
}


#pragma mark - Utils

- (NSString*) classNamesStyleIdentityFragment {
    if( self.styleClasses.count == 0 ) {
        return @"";
    } else {
        NSArray* styleClasses = [[self.styleClasses allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            return [obj1 compare:obj2];
        }];
        NSMutableString* str = [NSMutableString stringWithString:@"["];
        [str appendString:[styleClasses componentsJoinedByString:@","]];
        [str appendString:@"]"];
        return [str copy];
    }
}

- (NSString*) createElementStyleIdentity {
    if( self.customElementStyleIdentity ) {
        self.elementStyleIdentityPath = [NSString stringWithFormat:@"@%@%@", self.customElementStyleIdentity, [self classNamesStyleIdentityFragment]]; // Prefix custom style id with @
        return self.elementStyleIdentityPath;
    }
    else if( self.elementId ) {
        self.elementStyleIdentityPath = [NSString stringWithFormat:@"#%@%@", self.elementId, [self classNamesStyleIdentityFragment]]; // Prefix element id with #
        return self.elementStyleIdentityPath;
    }
    else if( self.nestedElementKeyPath ) {
        self.elementStyleIdentityPath = [NSString stringWithFormat:@"$%@", self.nestedElementKeyPath]; // Prefix nested elements with $
        return self.elementStyleIdentityPath;
    }
    else if( self.styleClasses ) {
        NSMutableString* str = [NSMutableString stringWithString:NSStringFromClass(self.canonicalType)];
        [str appendString:[self classNamesStyleIdentityFragment]];
        return [str copy];
    }
    else {
        return NSStringFromClass(self.canonicalType);
    }
}

- (NSString*) updateElementStyleIdentityPathIfNeededWith:(ISSStylingManager*)stylingManager {
    // Update style identity of element, if needed
//    [self elementStyleIdentity];
    if ( self.elementStyleIdentityPath ) return self.elementStyleIdentityPath;
    
//    if ( self.elementId || self.customElementStyleIdentity ) return nil; // If element uses element Id, or custom style id, elementStyleIdentityPath will have been set by call to createElementStyleIdentity, and will only contain the element Id itself
    
    if( self.parentElement ) {
//        ISSElementStylingProxy* parentDetails = [[InterfaCSS interfaCSS] stylingProxyFor:self.parentElement];
        ISSElementStylingProxy* parentDetails = [stylingManager stylingProxyFor:self.parentElement];
//        NSString* parentStyleIdentityPath = parentDetails.elementStyleIdentityPath;
        NSString* parentStyleIdentityPath = [parentDetails updateElementStyleIdentityPathIfNeededWith:stylingManager];
        // Check if an ancestor has an element id (i.e. style identity path will contain #someParentElementId) - this information will be used to determine if styles can be cacheable or not
        self.ancestorHasElementId = [parentStyleIdentityPath hasPrefix:@"#"] || [parentStyleIdentityPath rangeOfString:@" #"].location != NSNotFound;
        self.ancestorUsesCustomElementStyleIdentity = [parentStyleIdentityPath hasPrefix:@"@"] || [parentStyleIdentityPath rangeOfString:@" @"].location != NSNotFound;
        
        // Concatenate parent elementStyleIdentityPath of parent with the elementStyleIdentity of this element, separated by a space:
        if( parentStyleIdentityPath ) self.elementStyleIdentityPath = [NSString stringWithFormat:@"%@ %@", parentDetails.elementStyleIdentityPath, self.elementStyleIdentity];
        else self.elementStyleIdentityPath = self.elementStyleIdentity;
    } else {
        self.ancestorHasElementId = NO;
        self.ancestorUsesCustomElementStyleIdentity = NO;
        
        self.elementStyleIdentityPath = self.elementStyleIdentity;
    }
    
    return self.elementStyleIdentityPath;
}


#pragma mark - Public interface


- (BOOL) addedToViewHierarchy {
    return self.parentView.window || (self.parentView.class == UIWindow.class) || (self.view.class == UIWindow.class);
}

- (BOOL) stylesCacheable {
    return (self.elementId != nil) || self.ancestorHasElementId
        || (self.customElementStyleIdentity != nil)  || self.ancestorUsesCustomElementStyleIdentity
        || self.addedToViewHierarchy;
}


+ (void) markAllCachedStylingInformationAsDirty {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISSMarkCachedStylingInformationAsDirtyNotificationName object:nil];
}

- (void) markCachedStylingInformationAsDirty {
    self.cachedStylingInformationDirty = YES;
}


- (UIView*) view {
    return [self.uiElement isKindOfClass:UIView.class] ? self.uiElement : nil;
}

- (id) parentElement {
    if( !_parentElement ) {
        if( [_uiElement isKindOfClass:[UIView class]] ) {
            UIView* view = (UIView*)_uiElement;
            _parentView = view.superview; // Update cached parentView reference
            _closestViewController = [self.class closestViewController:view];
            if( _closestViewController.view == view ) {
                _parentElement = _closestViewController;
            } else {
                _parentElement = _parentView; // In case parent element is view - _parentElement is the same as _parentView
            }
        }
        else if( [_uiElement isKindOfClass:[UIViewController class]] ) {
            _parentElement = ((UIViewController*)self.uiElement).view.superview; // Use the super view of the view controller root view
        }
        if( _parentElement ) {
            _cachedStylingInformationDirty = YES;
        }
    }
    return _parentElement;
}

- (BOOL) checkForUpdatedParentElement {
    BOOL didChangeParent = NO;
    if( self.view && self.view.superview != self.parentView ) { // Check for updated superview
        _parentElement = nil; // Reset parent element to make sure it's re-evaluated
        didChangeParent = _cachedStylingInformationDirty = YES;
    }
    
    [self parentElement]; // Update parent element, if needed...
    
    return didChangeParent;
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



#pragma mark - Element id

- (void) setElementId:(NSString*)elementId {
    _elementId = elementId;
    self.cachedStylingInformationDirty = YES;
}


#pragma mark - Style classes

- (void) setStyleClasses:(NSSet*)styleClasses {
    if (styleClasses) {
        NSMutableSet* lcStyleClasses = [[NSMutableSet alloc] init];
        for(NSString* styleClass in styleClasses) [lcStyleClasses addObject:[styleClass lowercaseString]];
        
        _styleClasses = [lcStyleClasses copy];
    } else {
        _styleClasses = nil;
    }
    self.cachedStylingInformationDirty = YES;
}

- (NSString*) styleClass {
    return [self.styleClasses anyObject];
}

- (void) setStyleClass:(NSString*)styleClass {
    self.styleClasses = styleClass ? [NSSet setWithObject:styleClass] : nil;
}

- (BOOL) hasStyleClass:(NSString*)styleClass {
    return [self.styleClasses containsObject:[styleClass lowercaseString]];
}

- (void) addStyleClass:(NSString*)styleClass {
    NSSet* newClasses = [NSSet setWithObject:[styleClass lowercaseString]];
    NSSet* existingClasses = self.styleClasses;
    [self setStyleClasses:existingClasses ? [newClasses setByAddingObjectsFromSet:existingClasses] : newClasses];
}

- (void) removeStyleClass:(NSString*)styleClass {
    NSSet* newClasses = [self.styleClasses objectsPassingTest:^BOOL(id obj, BOOL* stop) {
        return ![styleClass iss_isEqualIgnoreCase:obj];
    }];
    [self setStyleClasses:newClasses];
}


#pragma mark - Custom styling identity

- (void) setCustomElementStyleIdentity:(NSString*)customElementStyleIdentity {
    _customElementStyleIdentity = customElementStyleIdentity;
    self.cachedStylingInformationDirty = YES;
}



- (id) childElementForKeyPath:(NSString*)keyPath {
    NSString* validKeyPath = self.validNestedElements[[keyPath lowercaseString]];
    if( validKeyPath ) {
        return [self.uiElement valueForKeyPath:validKeyPath];
    }
    return nil;
}

- (BOOL) addValidNestedElementKeyPath:(NSString*)keyPath {
    NSString* lcPath = [keyPath lowercaseString];
    if( _validNestedElements[lcPath] ) return YES;
    
    NSString* validKeyPathForClass = [ISSRuntimeIntrospectionUtils validKeyPathForCaseInsensitivePath:keyPath inClass:[self.uiElement class]];
    if (!validKeyPathForClass) return NO;
    
    NSMutableDictionary* updatedValidNestedElements = [NSMutableDictionary dictionaryWithObject:validKeyPathForClass forKey:lcPath];
    if( _validNestedElements ) {
        [updatedValidNestedElements addEntriesFromDictionary:_validNestedElements];
    }
    _validNestedElements = [updatedValidNestedElements copy];
    
    return YES;
}

- (ISSUpdatableValueObserver*) addObserverForValue:(ISSUpdatableValue*)value inProperty:(ISSPropertyDeclaration*)propertyDeclaration withBlock:(void (^)(NSNotification* note))block {
    ISSUpdatableValueObserver* existingObserver = self.observedUpdatableValues[propertyDeclaration.fqn];
    if( [value isEqual:existingObserver.value] ) return existingObserver;
    
    if( !self.observedUpdatableValues ) {
        self.observedUpdatableValues = [NSMutableDictionary dictionary];
    }

    ISSUpdatableValueObserver* observer = [value addValueUpdateObserverWithBlock:block];
    self.observedUpdatableValues[propertyDeclaration] = observer;
    return observer;
}


- (id) visitExclusivelyWithScope:(const void*)scope visitorBlock:(ISSElementStylingProxyVisitorBlock)visitorBlock {
    if( !_isVisiting || scope != _visitorScope ) {
        const void* previousScope = _visitorScope;
        @try {
            _isVisiting = YES;
            _visitorScope = scope;
            return visitorBlock(self);
        }
        @finally {
            _visitorScope = previousScope;
            if (_visitorScope == NULL) {
                _isVisiting = NO;
            }
        }
    } else {
        return nil; // Already vising element - aborting
    }
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"ElementDetails(%@)", self.elementStyleIdentity];
}

@end
