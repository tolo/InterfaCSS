//
//  ISSStylingManager.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSStylingManager.h"

#import "ISSStyleSheetManager.h"
#import "ISSPropertyManager.h"

#import "ISSStyleSheet.h"
#import "ISSPropertyValue.h"
#import "ISSElementStylingProxy.h"
#import "ISSPropertyValue.h"
#import "ISSRuleset.h"
#import "ISSSelectorChain.h"
#import "ISSRuntimeIntrospectionUtils.h"
#import "ISSStylingContext.h"

#import "NSArray+ISSAdditions.h"


// TODO: RELOAD STYLES WHEN STYLESHEETS ARE RELOADED

typedef id (^ISSViewHierarchyVisitorBlock)(id viewObject, ISSElementStylingProxy* elementDetails, BOOL* stop);


static ISSStylingManager* sharedISSStylingManager = nil;


@interface ISSDelegatingStyler : NSObject <ISSStyler>

@property (nonatomic, weak, readonly) ISSStylingManager* stylingManager;
@property (nonatomic, strong, readonly) ISSStyleSheetScope* styleSheetScope;

- (instancetype) initWithStylingManager:(ISSStylingManager*)stylingManager styleSheetScope:(ISSStyleSheetScope*)styleSheetScope;

@end

@implementation ISSDelegatingStyler

- (instancetype) initWithStylingManager:(ISSStylingManager*)stylingManager styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    if (self = [super init]) {
        _stylingManager = stylingManager;
        _styleSheetScope = styleSheetScope;
    }
    return self;
}

- (ISSPropertyManager*) propertyManager {
    return self.stylingManager.propertyManager;
}

- (ISSStyleSheetManager*) styleSheetManager {
    return self.stylingManager.styleSheetManager;
}

- (id<ISSStyler>) stylerWithScope:(ISSStyleSheetScope*)styleSheetScope includeCurrent:(BOOL)includeCurrent {
    if (includeCurrent) {
        styleSheetScope = [self.styleSheetScope scopeByIncludingScope:styleSheetScope];
    }
    return [[ISSDelegatingStyler alloc] initWithStylingManager:self.stylingManager styleSheetScope:styleSheetScope];
}

- (nullable ISSElementStylingProxy*) stylingProxyFor:(id)uiElement {
    return [self.stylingManager stylingProxyFor:uiElement];
}

- (void) applyStyling:(id)uiElement {
    [self.stylingManager applyStyling:uiElement includeSubViews:YES force:NO styleSheetScope:self.styleSheetScope];
}

- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews {
    [self.stylingManager applyStyling:uiElement includeSubViews:includeSubViews force:NO styleSheetScope:self.styleSheetScope];
}

- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force {
    [self.stylingManager applyStyling:uiElement includeSubViews:includeSubViews force:force styleSheetScope:self.styleSheetScope];
}

- (void) clearCachedStylingInformationFor:(id)uiElement includeSubViews:(BOOL)includeSubViews {
    [self.stylingManager clearCachedStylingInformationFor:uiElement includeSubViews:includeSubViews];
}

#pragma mark - StyleSheetManager methods

- (nullable ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(nonnull NSString*)styleSheetFileName {
    return [self.styleSheetManager loadStyleSheetFromMainBundleFile:styleSheetFileName];
}

- (nullable ISSStyleSheet*) loadStyleSheetFromFileURL:(nonnull NSURL*)styleSheetFileURL {
    return [self.styleSheetManager loadStyleSheetFromFileURL:styleSheetFileURL];
}

- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(nonnull NSURL*)styleSheetFileURL {
    return [self.styleSheetManager loadRefreshableStyleSheetFromURL:styleSheetFileURL];
}

@end


// Private interface
@interface ISSStylingManager ()

@property (nonatomic, strong) NSMapTable* cachedStyleDeclarationsForElements; // Weak canonical element styling identity (NSString) -> NSMutableArray

@end


@implementation ISSStylingManager


#pragma mark - Creation & destruction

+ (ISSStylingManager*) shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedISSStylingManager = [[ISSStylingManager alloc] init];
    });

    return sharedISSStylingManager;
}

- (instancetype) init {
    return [self initWithPropertyRegistry:nil styleSheetManager:nil];
}

- (instancetype) initWithPropertyRegistry:(ISSPropertyManager*)propertyManager styleSheetManager:(ISSStyleSheetManager*)styleSheetManager {
    if ( self = [super init] ) {
        _propertyManager = propertyManager ?: [[ISSPropertyManager alloc] init];
        _propertyManager.stylingManager = self;
        _styleSheetManager = styleSheetManager ?: [[ISSStyleSheetManager alloc] init];
        _styleSheetManager.stylingManager = self;
        
        _cachedStyleDeclarationsForElements = [NSMapTable weakToStrongObjectsMapTable];
        
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver:self selector:@selector(memoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
        // TODO: More notifications?
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) memoryWarning:(NSNotification*)notification {
    [self clearAllCachedStyles];
}


#pragma mark - ISSStyler

- (ISSStyleSheetScope*) styleSheetScope {
    return [ISSStyleSheetScope defaultGroupScope];
}

- (ISSStylingManager*) stylingManager {
    return self;
}

- (nullable ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(nonnull NSString*)styleSheetFileName {
    return [self.styleSheetManager loadStyleSheetFromMainBundleFile:styleSheetFileName];
}

- (nullable ISSStyleSheet*) loadStyleSheetFromFileURL:(nonnull NSURL*)styleSheetFileURL {
    return [self.styleSheetManager loadStyleSheetFromFileURL:styleSheetFileURL];
}

- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(nonnull NSURL*)styleSheetFileURL {
    return [self.styleSheetManager loadRefreshableStyleSheetFromURL:styleSheetFileURL];
}


#pragma mark - Styling - Style matching and application

- (NSArray*) effectiveStylesForUIElement:(ISSElementStylingProxy*)elementDetails force:(BOOL)force styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    // First - get cached declarations stored using weak reference on ISSElementStylingProxy object
//    NSArray* cachedRulesets = elementDetails.cachedRulesets;
// TODO: Is caching even possible,

    // If not found - get cached declarations that matches element style identity (i.e. unique hierarchy/path of classes and style classes)
    // This makes it possible to reuse identical style information in sibling elements for instance.
//    if( !cachedRulesets ) {
        NSArray* cachedRulesets = [self.cachedStyleDeclarationsForElements objectForKey:elementDetails.elementStyleIdentityPath];
//        elementDetails.cachedRulesets = cachedRulesets;
//    }

     if ( !cachedRulesets ) { // Otherwise - build styles
        ISSLogTrace(@"FULL stylesheet scan for '%@'", elementDetails.elementStyleIdentityPath);

        elementDetails.stylingApplied = NO; // Reset 'stylingApplied' flag if declaration cache has been cleared, to make sure element is re-styled

        // Perform full stylesheet scan to get matching style classes, but ignore pseudo classes at this stage
        ISSStylingContext* stylingContext = [[ISSStylingContext alloc] initWithStylingManager:self styleSheetScope:styleSheetScope ignorePseudoClasses:YES];
        cachedRulesets = [self.styleSheetManager rulesetsMatchingElement:elementDetails stylingContext:stylingContext];
        
        if( stylingContext.containsPartiallyMatchedDeclarations ) {
            ISSLogTrace(@"Found %d matching declarations, and at least one partially matching declaration, for '%@'.", cachedRulesets.count, elementDetails.elementStyleIdentityPath);
        } else {
            ISSLogTrace(@"Found %d matching declarations for '%@'", cachedRulesets.count, elementDetails.elementStyleIdentityPath);
        }
        
        // If selector specificity is enabled...
//        if( self.useSelectorSpecificity ) {
            // ...sort declarations on specificity
            cachedRulesets = [cachedRulesets sortedArrayWithOptions:NSSortStable usingComparator:^NSComparisonResult(ISSRuleset* ruleset1, ISSRuleset* ruleset2) {
                if ( ruleset1.specificity > ruleset2.specificity ) return NSOrderedDescending;
                if ( ruleset1.specificity < ruleset2.specificity ) return NSOrderedAscending;
                return NSOrderedSame;
            }];
//        }
        
        // If there are no style declarations that only partially matches the element - consider the styles fully resolved for the element
        elementDetails.stylesFullyResolved = !stylingContext.containsPartiallyMatchedDeclarations;
        
        // Only add declarations to cache if styles are cacheable for element (i.e. either added to window, or part of a view hierachy that has an root element with an element Id), or,
        // if there were no styles that would match if the element was placed under a different parent (i.e. partial matches)
        if( stylingContext.stylesCacheable && (elementDetails.stylesCacheable || elementDetails.stylesFullyResolved) ) {
            [self.cachedStyleDeclarationsForElements setObject:cachedRulesets forKey:elementDetails.elementStyleIdentityPath];
//            elementDetails.cachedRulesets = cachedRulesets;
        } else {
            ISSLogTrace(@"Can NOT cache styles for '%@'", elementDetails.elementStyleIdentityPath);
        }
    } else {
        ISSLogTrace(@"Cached declarations exists for '%@'", elementDetails.elementStyleIdentityPath);
    }

    if( !force && elementDetails.stylingApplied && elementDetails.stylingStatic ) { // Current styling information has already been applied, and declarations contain no pseudo classes
        ISSLogTrace(@"Styles aleady applied for '%@'", elementDetails.elementStyleIdentityPath);
        return nil;
    } else { // Styling information has not been applied, or declarations contains pseudo classes (in which case we need to re-evaluate the styles every time styling is initiated), or is forced
        ISSLogTrace(@"Processing style declarations for '%@'", elementDetails.elementStyleIdentityPath);
        
        // Process declarations to see which styles currently match
        BOOL containsPseudoClassSelector = NO;
        ISSStylingContext* stylingContext = [[ISSStylingContext alloc] initWithStylingManager:self styleSheetScope:styleSheetScope];
        NSMutableArray* viewStyles = [[NSMutableArray alloc] init];
        for (ISSRuleset* ruleset in cachedRulesets) {
            // Add styles if declarations doesn't contain pseudo selector, or if matching against pseudo class selector is successful
            if ( !ruleset.containsPseudoClassSelector || [ruleset matchesElement:elementDetails stylingContext:stylingContext] ) {
                [viewStyles iss_addAndReplaceUniqueObjectsInArray:ruleset.properties];
            }

            containsPseudoClassSelector = containsPseudoClassSelector || ruleset.containsPseudoClassSelector;
        }
        if( elementDetails.inlineStyle.count > 0 ) {
            [viewStyles iss_addAndReplaceUniqueObjectsInArray:elementDetails.inlineStyle];
        }
        elementDetails.stylingStatic = !containsPseudoClassSelector; // Record in elementDetails if declarations contain pseudo classes, and thus needs constant re-evaluation (i.e. not static)

        // Set 'stylingApplied' flag to indicate that styles have been fully applied, but only if element is part of a defined view
        // hierarchy (i.e. either added to window, or part of a view hierachy that has an root element with an element Id)
        if( elementDetails.stylesCacheable || elementDetails.stylesFullyResolved ) {
            elementDetails.stylingApplied = YES;
        } else {
            ISSLogTrace(@"Cannot mark element '%@' as styled", elementDetails.elementStyleIdentityPath);
        }

        return viewStyles;
    }
}

- (void) styleUIElement:(ISSElementStylingProxy*)elementDetails force:(BOOL)force styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    NSArray* styles = [self effectiveStylesForUIElement:elementDetails force:force styleSheetScope:styleSheetScope];

    if( styles ) { // If 'styles' is nil, current styling information has already been applied
        if ( elementDetails.willApplyStylingBlock ) {
            styles = elementDetails.willApplyStylingBlock(styles);
        }

        for (ISSPropertyValue* propertyDeclaration in styles) {
//            if( [elementDetails.disabledProperties containsObject:propertyDeclaration.property] ) {
//                ISSLogTrace(@"Skipping setting of %@ - property disabled on %@", propertyDeclaration, elementDetails.uiElement);
//            } else {
            [self.propertyManager applyPropertyValue:propertyDeclaration onTarget:elementDetails styleSheetScope:styleSheetScope];
//            }
        }

        if ( elementDetails.didApplyStylingBlock ) {
            elementDetails.didApplyStylingBlock(styles);
        }
    }
}


#pragma mark - Styling - Elememt styling proxy

//- (ISSElementStylingProxy*) stylingProxyFor:(id)uiElement create:(BOOL)create {
- (ISSElementStylingProxy*) stylingProxyFor:(id)uiElement {
    if( !uiElement ) return nil;

//    ISSElementStylingProxy* stylingProxy = [uiElement interfaCSS];
//    if( !stylingProxy && create ) {
//        stylingProxy = [[ISSElementStylingProxy alloc] initWithUIElement:uiElement];
//        [stylingProxy resetWith:self];
//        [uiElement iss_setStylingProxy:stylingProxy];
//    }
//
//    return stylingProxy;
    return [uiElement interfaCSS];
}
//
//- (ISSElementStylingProxy*) stylingProxyFor:(id)uiElement {
//    return [self stylingProxyFor:uiElement create:YES];
//}


//#pragma mark - Styling - Elememt styling proxy conveience methods
//
//- (ISSElementStylingProxy*) objectForKeyedSubscript:(id)uiElement {
//    return [self stylingProxyFor:uiElement create:YES];
//}


#pragma mark - Styling - Caching

- (void) clearCachedStylingInformationFor:(id)uiElement includeSubViews:(BOOL)includeSubViews {
    [self clearCachedStylingInformationFor:[uiElement interfaCSS] includeRoot:YES includeSubViews:includeSubViews];
}

- (void) clearCachedStylingInformationFor:(ISSElementStylingProxy*)rootElement includeRoot:(BOOL)includeRoot includeSubViews:(BOOL)includeSubViews {
    if (!rootElement) return;
    
    if (includeSubViews) {
        [self visitViewHierarchyFromRootElement:rootElement scope:_cmd includeRoot:includeRoot visitorBlock:^id(id viewObject, ISSElementStylingProxy* element, BOOL* stop) {
            [self.cachedStyleDeclarationsForElements removeObjectForKey:element.elementStyleIdentityPath];
            [element resetWith:self];
            return nil;
        } stop:nil createDetails:NO];
    } else {
        [self.cachedStyleDeclarationsForElements removeObjectForKey:rootElement.elementStyleIdentityPath];
        [rootElement resetWith:self];
    }
}

- (void) clearAllCachedStyles {
    if( self.cachedStyleDeclarationsForElements.count ) {
        ISSLogTrace(@"Clearing all cached styles");
        [self.cachedStyleDeclarationsForElements removeAllObjects];

        [ISSElementStylingProxy markAllCachedStylingInformationAsDirty];
    }
}


#pragma mark - Styling - High level style application methods

- (void) applyStyling:(id)uiElement {
    [self applyStyling:uiElement includeSubViews:YES force:NO styleSheetScope:nil];
}

- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews {
    [self applyStyling:uiElement includeSubViews:includeSubViews force:NO styleSheetScope:nil];
}

- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force {
    [self applyStyling:uiElement includeSubViews:includeSubViews force:force styleSheetScope:nil];
}

// Main styling method
- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    if( !uiElement ) return;

    ISSElementStylingProxy* stylingProxy = [uiElement interfaCSS];
    [self applyStylingWithDetails:stylingProxy includeSubViews:includeSubViews force:force styleSheetScope:styleSheetScope];
}

// Main styling method (element details version)
- (void) applyStylingWithDetails:(ISSElementStylingProxy*)element includeSubViews:(BOOL)includeSubViews force:(BOOL)force styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    if( !element ) return;

    // If styling is disabled for element (but has been displayed once) - abort styling of whole sub tre
//    if( element.stylingAppliedAndDisabled ) {
//        ISSLogTrace(@"Styling disabled for %@", element.view);
//        return;
//    }
    
    [element visitExclusivelyWithScope:_cmd visitorBlock:^id (ISSElementStylingProxy* _) { // Prevent recursive styling calls for uiElement during styling
        [self applyStylingInternal:element includeSubViews:includeSubViews force:force styleSheetScope:styleSheetScope];
        return nil;
    }];
    
//    // Cancel scheduled calls after styling has been applied, to avoid "loop"
//    if( element.stylingScheduled ) {
//        [self cancelScheduledApplyStyling:element.uiElement];
//        element.stylingScheduled = NO;
//    }
}

// Internal styling method ("inner") - should only be called by -[doApplyStylingInternal:includeSubViews:force:].
- (void) applyStylingInternal:(ISSElementStylingProxy*)element includeSubViews:(BOOL)includeSubViews force:(BOOL)force styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    ISSLogTrace(@"Applying style to %@", element.uiElement);
    styleSheetScope = styleSheetScope ?: [ISSStyleSheetScope defaultGroupScope];
    
    [element checkForUpdatedParentElement]; // Reset cached styles if parent/superview has changed...
    
    BOOL dirty = element.cachedStylingInformationDirty;
    if ( dirty ) {
        ISSLogTrace(@"Cached styling information for element of %@ dirty - resetting cached styling information", element);
        [self clearCachedStylingInformationFor:element includeRoot:YES includeSubViews:NO];
//        element.cachedStylingInformationDirty = NO;

        // If not including subviews, make sure child elements are marked dirty
        if( !includeSubViews ) {
            for(id subView in [self childElementsForElement:element]) {
                [subView interfaCSS].cachedStylingInformationDirty = YES;
            }
        }
    }

    [self styleUIElement:element force:force styleSheetScope:styleSheetScope];

    if( includeSubViews ) { // Process subviews
        for(id subView in [self childElementsForElement:element]) {
            ISSElementStylingProxy* subViewDetails = [subView interfaCSS];
            if (dirty) subViewDetails.cachedStylingInformationDirty = YES;
            
            [self applyStylingWithDetails:subViewDetails includeSubViews:YES force:force styleSheetScope:styleSheetScope];
        }
    }
}

- (id<ISSStyler>) stylerWithScope:(ISSStyleSheetScope*)styleSheetScope {
    return [self stylerWithScope:styleSheetScope includeCurrent:NO];
}

- (id<ISSStyler>) stylerWithScope:(ISSStyleSheetScope*)styleSheetScope includeCurrent:(BOOL)includeCurrent {
    if (includeCurrent) {
        styleSheetScope = [self.styleSheetScope scopeByIncludingScope:styleSheetScope];
    }
    return [[ISSDelegatingStyler alloc] initWithStylingManager:self styleSheetScope:styleSheetScope];
}


#pragma mark - View hierarchy traversing

- (id) visitViewHierarchyFromRootView:(id)view visitorBlock:(ISSViewHierarchyVisitorBlock)visitorBlock {
    return [self visitViewHierarchyFromRootElement:[view interfaCSS] scope:_cmd includeRoot:YES visitorBlock:visitorBlock stop:NULL createDetails:NO];
}

- (id) visitViewHierarchyFromRootElement:(ISSElementStylingProxy*)rootElementDetails scope:(void*)scope includeRoot:(BOOL)includeRoot visitorBlock:(ISSViewHierarchyVisitorBlock)visitorBlock stop:(BOOL*)stop createDetails:(BOOL)createDetails {
    if( !rootElementDetails || (includeRoot && rootElementDetails.isVisiting) ) return nil; // Prevent recursive loops...
    
    return [rootElementDetails visitExclusivelyWithScope:scope visitorBlock:^id (ISSElementStylingProxy* details) {
        id result = nil;
        if( includeRoot ) {
            result = visitorBlock(details.uiElement, details, stop);
            if( stop && *stop ) return result;
        }

        // Drill down
        for(UIView* subview in [self childElementsForElement:details]) {
            ISSElementStylingProxy* subviewDetails = [subview interfaCSS];
            result = [self visitViewHierarchyFromRootElement:subviewDetails scope:scope includeRoot:YES visitorBlock:visitorBlock stop:stop createDetails:createDetails];
            if( stop && *stop ) return result;
        }
        return nil;
    }];
}

- (id) visitReversedViewHierarchyFromView:(id)view visitorBlock:(ISSViewHierarchyVisitorBlock)visitorBlock {
    BOOL stop = NO;
    return [self visitReversedViewHierarchyFromView:view visitorBlock:visitorBlock stop:&stop];
}

- (id) visitReversedViewHierarchyFromView:(id)view visitorBlock:(ISSViewHierarchyVisitorBlock)visitorBlock stop:(BOOL*)stop {
    if( view == nil ) return nil;
    
    ISSElementStylingProxy* details = [view interfaCSS];

    id result = visitorBlock(view, details, stop);
    if( *stop ) return result;

    // Move up
    return [self visitReversedViewHierarchyFromView:details.parentElement visitorBlock:visitorBlock stop:stop];
}

- (id) subviewWithElementId:(NSString*)elementId inView:(id)view {
    return [self visitViewHierarchyFromRootView:view visitorBlock:^id(id viewObject, ISSElementStylingProxy* elementDetails, BOOL* stop) {
        if( viewObject != view && [elementDetails.elementId isEqualToString:elementId] ) {
            *stop = YES;
            return viewObject;
        }
        return nil;
    }];
}

- (id) superviewWithElementId:(NSString*)elementId inView:(id)view {
    return [self visitReversedViewHierarchyFromView:view visitorBlock:^id(id viewObject, ISSElementStylingProxy* elementDetails, BOOL* stop) {
        if( viewObject != view && [elementDetails.elementId isEqualToString:elementId] ) {
            *stop = YES;
            return viewObject;
        }
        return nil;
    }];
}

- (NSArray*) childElementsForElement:(ISSElementStylingProxy*)element {
    NSMutableOrderedSet* subviews = element.view.subviews ? [[NSMutableOrderedSet alloc] initWithArray:element.view.subviews] : [[NSMutableOrderedSet alloc] init];
    
#if TARGET_OS_TV == 0
    // Special case: UIToolbar - add toolbar items to "subview" list
    if( [element.view isKindOfClass:UIToolbar.class] ) {
        UIToolbar* toolbar = (UIToolbar*)element.view;
        if( toolbar.items ) [subviews addObjectsFromArray:toolbar.items];
    }
    // Special case: UINavigationBar - add nav bar items to "subview" list
    else
#endif
        if( [element.view isKindOfClass:UINavigationBar.class] ) {
            UINavigationBar* navigationBar = (UINavigationBar*)element.view;
            
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
        else if( [element.view isKindOfClass:UITabBar.class] ) {
            UITabBar* tabBar = (UITabBar*)element.view;
            if( tabBar.items ) [subviews addObjectsFromArray:tabBar.items];
        }
    
    // Add any valid nested elements (valid property prefix key paths) to the subviews list
    for(NSString* nestedElementKeyPath in element.validNestedElements.allValues) {
        //        id nestedElement = [self.uiElement valueForKeyPath:nestedElementKeyPath];
        id nestedElement = [ISSRuntimeIntrospectionUtils invokeGetterForKeyPath:nestedElementKeyPath ignoringCase:NO inObject:element.uiElement];
        
        if( nestedElement && nestedElement != element.uiElement && nestedElement != element.parentElement ) { // Do quick initial sanity checks for circular relationship
            ISSElementStylingProxy* childDetails = [nestedElement interfaCSS];
            
            BOOL circularReference = NO;
            if( childDetails.ownerElement ) {
                // If nested element already has an owner - check that there isn't a circular relationship (can happen with inputView and inputAccessoryView for instance)
                if( [ISSRuntimeIntrospectionUtils invokeGetterForKeyPath:nestedElementKeyPath ignoringCase:NO inObject:element.parentElement] == nestedElement ) {
                    circularReference = YES;
                } else {
                    UIView* superview = element.view.superview;
                    while(superview != nil) {
                        if( superview == nestedElement ) {
                            circularReference = TRUE;
                            break;
                        }
                        superview = superview.superview;
                    }
                }
            }
            
            if (!circularReference) {
                // Set the ownerElement and nestedElementPropertyName to make sure that the nested property can be properly matched by ISSNestedElementSelector
                // (even if it's not a direct subview) and that it has a unique styling identity (in its sub tree)
                childDetails.ownerElement = element.uiElement;
                childDetails.nestedElementKeyPath = nestedElementKeyPath;
                
                [subviews addObject:nestedElement];
            }
        }
    }
    
    return [subviews array];
}


#pragma mark - Pseudo class support

- (id) findParent:(UIView*)parentView ofClass:(Class)class {
    if( !parentView ) return nil;
    else if( [parentView isKindOfClass:class] ) return parentView;
    else return [self findParent:parentView.superview ofClass:class];
}

- (void) typeQualifiedPositionInParentForElement:(ISSElementStylingProxy*)elementDetails position:(NSInteger*)position count:(NSInteger*)count {
    *position = NSNotFound;
    *count = 0;
    
    if( [elementDetails.uiElement isKindOfClass:UITableViewCell.class] ) {
        UITableView* tv = [self findParent:elementDetails.parentView ofClass:UITableView.class];
        UITableViewCell* cell = (UITableViewCell*)elementDetails.uiElement;
        NSIndexPath* indexPath = [tv indexPathForCell:cell];
        if (!indexPath) indexPath = [tv indexPathForRowAtPoint:cell.center];
        if (indexPath) {
            *position = indexPath.row;
            *count = [tv numberOfRowsInSection:indexPath.section];
        }
    }
    else if( [elementDetails.uiElement isKindOfClass:UICollectionViewCell.class] ) {
        UICollectionView* cv = [self findParent:elementDetails.parentView ofClass:UICollectionView.class];
        UICollectionViewCell* cell = (UICollectionViewCell*)elementDetails.uiElement;
        NSIndexPath* indexPath = [cv indexPathForCell:cell];
        if (!indexPath) indexPath = [cv indexPathForItemAtPoint:cell.center];
        if (indexPath) {
            *position = indexPath.row;
            *count = [cv numberOfItemsInSection:indexPath.section];
        }
    }
    else if( [elementDetails.uiElement isKindOfClass:UICollectionReusableView.class] ) {
        UICollectionView* cv = [self findParent:elementDetails.parentView ofClass:UICollectionView.class];
        NSIndexPath* indexPath = [cv indexPathForItemAtPoint:((UICollectionReusableView*)elementDetails.uiElement).center];
        if (indexPath) {
            *position = indexPath.row;
            *count = [cv numberOfItemsInSection:indexPath.section];
        }
    }
    else if( [elementDetails.uiElement isKindOfClass:UIBarButtonItem.class] && [elementDetails.parentView isKindOfClass:UINavigationBar.class] ) {
        UINavigationBar* navBar = (UINavigationBar*)elementDetails.parentView;
        if( navBar ) {
            *position = [navBar.items indexOfObject:elementDetails.uiElement];
            *count = navBar.items.count;
        }
    }
#if TARGET_OS_TV == 0
    else if( [elementDetails.uiElement isKindOfClass:UIBarButtonItem.class] && [elementDetails.parentView isKindOfClass:UIToolbar.class] ) {
        UIToolbar* toolbar = (UIToolbar*)elementDetails.parentView;
        if( toolbar ) {
            *position = [toolbar.items indexOfObject:elementDetails.uiElement];
            *count = toolbar.items.count;
        }
    }
#endif
    else if( [elementDetails.uiElement isKindOfClass:UITabBarItem.class] && [elementDetails.parentView isKindOfClass:UITabBar.class] ) {
        UITabBar* tabbar = (UITabBar*)elementDetails.parentView;
        if( tabbar ) {
            *position = [tabbar.items indexOfObject:elementDetails.uiElement];
            *count = tabbar.items.count;
        }
    }
    else if( elementDetails.parentView ) {
        Class uiKitClass = [self.propertyManager canonicalTypeClassForClass:[elementDetails.uiElement class]];
        for(UIView* v in elementDetails.parentView.subviews) {
            if( [v.class isSubclassOfClass:uiKitClass] ) {
                if( v == elementDetails.uiElement ) *position = *count;
                (*count)++;
            }
        }
    }
}


#pragma mark - Debugging support

- (void) logMatchingRulesetsForElement:(id)uiElement styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    ISSElementStylingProxy* elementDetails = [uiElement interfaCSS];
    [self.styleSheetManager logMatchingRulesetsForElement:elementDetails styleSheetScope:styleSheetScope];
}

@end
