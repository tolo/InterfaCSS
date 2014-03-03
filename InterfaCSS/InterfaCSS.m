//
//  InterfaCSS.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "InterfaCSS.h"

#import <QuartzCore/QuartzCore.h>
#import "ISSStyleSheetParser.h"
#import "UIView+InterfaCSS.h"
#import "ISSStyleSheetParser.h"
#import "ISSParcoaStyleSheetParser.h"
#import "ISSStyleSheet.h"
#import "ISSViewBuilder.h"
#import "ISSPropertyDeclaration.h"
#import "NSObject+ISSLogSupport.h"
#import "ISSViewPrototype.h"


@interface ViewProperties : NSObject

@property (nonatomic, weak) id uiObject;
@property (nonatomic, weak) UIView* viewSuperview;
@property (nonatomic, strong) NSSet* styleClasses;

@end

@implementation ViewProperties

- (id) initForView:(id)uiObject {
    self = [super init];
    if (self) {
        self.uiObject = uiObject;
        if( [uiObject isKindOfClass:[UIView class]] ) {
            UIView* view = (UIView*)uiObject;
            self.viewSuperview = view.superview;
        }
    }
    return self;
}

- (UIView*) view {
    return [self.uiObject isKindOfClass:UIView.class] ? self.uiObject : nil;
}

@end


static InterfaCSS* singleton = nil;


// Private interface
@interface InterfaCSS ()

@property (nonatomic, strong) NSMutableArray* styleSheets;

@property (nonatomic, strong) NSMapTable* cachedStylesForViews; // UIView (weak reference) -> NSDictionary
@property (nonatomic, strong) NSMapTable* trackedViews; // UIView (weak reference) -> ViewProperties

@property (nonatomic, strong) NSMutableDictionary* prototypes;

@property (nonatomic, weak) UIWindow* keyWindow;

@property (nonatomic, strong) NSTimer* timer;

@end


@implementation InterfaCSS


#pragma mark - Creation & destruction

+ (void) initialize {
    if( !singleton ) {
        singleton = [[InterfaCSS alloc] initInternal];
    }
}

+ (InterfaCSS*) interfaCSS {
    return singleton;
}

+ (void) clearResetAndUnload {
    singleton.parser = nil;
    [singleton.styleSheets removeAllObjects];
    [singleton.trackedViews removeAllObjects];
    [singleton.cachedStylesForViews removeAllObjects];
    [singleton.prototypes removeAllObjects];

    [singleton disableAutoRefreshTimer];
}

- (id) init {
    [NSException raise:NSInternalInconsistencyException format:@"Hold on there professor, use +[InterfaCSS interfaCSS] instead!"];
    return self;
}

- (id) initInternal {
    if( (self = [super init]) ) {
        self.styleSheets = [[NSMutableArray alloc] init];
        self.trackedViews = [NSMapTable weakToStrongObjectsMapTable];
        self.cachedStylesForViews = [NSMapTable weakToStrongObjectsMapTable];
        self.prototypes = [[NSMutableDictionary alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(memoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];

        [self performSelector:@selector(initViewHierarchy) withObject:nil afterDelay:0];
    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) memoryWarning:(NSNotification*)notification {
    [self.cachedStylesForViews removeAllObjects];
}


#pragma mark - Timer

- (void) enableAutoRefreshTimer {
    if( !_timer ) {
        _timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(autoRefreshTimerTick) userInfo:nil repeats:YES];
    }
}

- (void) disableAutoRefreshTimer {
    [_timer invalidate];
    _timer = nil;
}

- (void) autoRefreshTimerTick {
    for(ISSStyleSheet* styleSheet in self.styleSheets) {
        if( styleSheet.refreshable && styleSheet.active ) { // Attempt to get updated stylesheet
            [self updateRefreshableStyleSheet:styleSheet];
        }
    }
}


#pragma mark - Parsing Internals

- (ISSStyleSheetParser*) parser {
    if ( !_parser ) {
        _parser = [[ISSParcoaStyleSheetParser alloc] init];
    }
    return _parser;
}

- (ISSStyleSheet*) loadStyleSheetFromFileURL:(NSURL*)styleSheetFile {
    ISSStyleSheet* styleSheet = nil;

    NSError* error = nil;
    NSString* styleSheetData = [NSString stringWithContentsOfURL:styleSheetFile usedEncoding:nil error:&error];

    if( styleSheetData ) {
        NSMutableArray* declarations = [self.parser parse:styleSheetData];

        if( declarations ) {
            styleSheet = [[ISSStyleSheet alloc] initWithStyleSheetURL:styleSheetFile declarations:declarations];
            [self.styleSheets addObject:styleSheet];

            [self refreshStyling];
        }
    } else {
        ISSLogDebug(@"Error loading stylesheet data from '%@' - %@", styleSheetFile, error);
    }

    return styleSheet;
}

- (void) updateRefreshableStyleSheet:(ISSStyleSheet*)styleSheet {
    [styleSheet refresh:^{
        [self refreshStyling];
    } parse:self.parser];
}

- (ViewProperties*) viewPropertiesForView:(id)view {
    ViewProperties* properties = [self.trackedViews objectForKey:view];
    if( !properties ) {
        properties = [[ViewProperties alloc] initForView:view];
        [self.trackedViews setObject:properties forKey:view];
    }
    return properties;
}


#pragma mark - Styling

- (BOOL) initViewHierarchy {
    self.keyWindow = [UIApplication sharedApplication].keyWindow;
    if( self.keyWindow ) {
        [self applyStyling:self.keyWindow];
        return YES;
    }
    return NO;
}

- (void) refreshStyling {
    [self.cachedStylesForViews removeAllObjects];
    if( self.keyWindow ) [self applyStyling:self.keyWindow];
}

- (NSMutableDictionary*) effectiveStylesForUIObject:(id)uiObject {
    NSMutableDictionary* effectiveStyles = [NSMutableDictionary dictionary];

    // Get inherited styles - NOTE: disabled for now, possibly undesired
    //if ( view.superview ) [effectiveStyles addEntriesFromDictionary:[self effectiveStylesForView:view.superview]];

    // Get view styles from cache
    NSMutableDictionary* viewStyles = [self.cachedStylesForViews objectForKey:uiObject];
    
    if ( !viewStyles ) {
        // Otherwise - build styles
        viewStyles = [NSMutableDictionary dictionary];

        for (ISSStyleSheet* styleSheet in self.styleSheets) {
            NSDictionary* styleSheetStyles = [styleSheet stylesForView:uiObject];
            if ( styleSheetStyles ) {
                [viewStyles addEntriesFromDictionary:styleSheetStyles];
            }
        }

        [self.cachedStylesForViews setObject:viewStyles forKey:uiObject];
    }

    [effectiveStyles addEntriesFromDictionary:viewStyles];
    return effectiveStyles;
}

- (void) styleUIObject:(id)uiObject {
    NSMutableDictionary* styles = [self effectiveStylesForUIObject:uiObject];
    
    for (ISSPropertyDeclaration* propertyDeclaration in styles.allKeys) {
        id value = styles[propertyDeclaration];
        if ( value ) {
            [propertyDeclaration setValue:value onTarget:uiObject];
        }
    }
}


#pragma mark - Public interface

#pragma mark - Styling

- (void) clearCachedStylesForUIObject:(id)uiObject {
    [self.cachedStylesForViews removeObjectForKey:uiObject];

    UIView* view = [uiObject isKindOfClass:[UIView class]] ? (UIView*)uiObject : nil;
    for(UIView* subView in view.subviews) {
        [self clearCachedStylesForUIObject:subView];
    }
}

- (UIView*) parentViewForUIObject:(id)uiObject {
    return [self viewPropertiesForView:uiObject].viewSuperview;
}

- (void) scheduleApplyStyling:(id)uiObject animated:(BOOL)animated {
    if( animated ) {
        //[NSObject cancelPreviousPerformRequestsWithTarget:uiObject selector:@selector(applyStyling:) object:nil];
        [[InterfaCSS interfaCSS] performSelector:@selector(applyStylingWithAnimation:) withObject:uiObject afterDelay:0];
    } else {
        //[NSObject cancelPreviousPerformRequestsWithTarget:uiObject selector:@selector(applyStylingWithAnimation:) object:nil];
        [[InterfaCSS interfaCSS] performSelector:@selector(applyStyling:) withObject:uiObject afterDelay:0];
    }
}

- (void) applyStyling:(id)uiObject {
    [NSObject cancelPreviousPerformRequestsWithTarget:uiObject selector:_cmd object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:uiObject selector:@selector(applyStylingWithAnimation:) object:nil];
    [self applyStyling:uiObject includeSubViews:YES];
}

- (void) applyStyling:(id)uiObject includeSubViews:(BOOL)includeSubViews {
    BOOL applied = NO;
    if( !self.keyWindow && includeSubViews ) {
        applied = [self initViewHierarchy];
    }
    if( !applied ) {
        ISSLogTrace(@"Applying style to %@", uiObject);

        UIView* view = [uiObject isKindOfClass:[UIView class]] ? (UIView*)uiObject : nil;

        // Reset cached styles if superview has changed
        ViewProperties* viewProperties = [self viewPropertiesForView:uiObject];
        if( view && view.superview != viewProperties.viewSuperview ) {
            ISSLogTrace(@"Superview of %@ has changed - resetting cached styles", view);
            [self clearCachedStylesForUIObject:view];
            viewProperties.viewSuperview = view.superview;
        }
        
        [self styleUIObject:uiObject];

        if( includeSubViews ) {
            NSArray* subviews = view.subviews ?: [[NSArray alloc] init];
            UIView* parentView = nil;
            if( [view isKindOfClass:UIToolbar.class] ) {
                UIToolbar* toolbar = (UIToolbar*)view;
                parentView = toolbar;
                if( toolbar.items ) subviews = [subviews arrayByAddingObjectsFromArray:toolbar.items];
            } else if( [view isKindOfClass:UINavigationBar.class] ) {
                UINavigationBar* navigationBar = (UINavigationBar*)view;
                parentView = navigationBar;
                if( navigationBar.items ) subviews = [subviews arrayByAddingObjectsFromArray:navigationBar.items];
            } else if( [view isKindOfClass:UITabBar.class] ) {
                UITabBar* tabBar = (UITabBar*)view;
                parentView = tabBar;
                if( tabBar.items ) subviews = [subviews arrayByAddingObjectsFromArray:tabBar.items];
            }
            
            for(id subView in subviews) {
                // If subview isn't view (i.e. UIToolbarItem for instance) - set parent view as super view in ViewProperties
                if( ![subView isKindOfClass:UIView.class] && parentView ) {
                    ViewProperties* subViewProperties = [self viewPropertiesForView:subView];
                    if( !subViewProperties.viewSuperview ) subViewProperties.viewSuperview = parentView;
                }
                [self applyStyling:subView];
            }
        }
    }
}

- (void) applyStylingWithAnimation:(id)uiObject {
    [NSObject cancelPreviousPerformRequestsWithTarget:uiObject selector:_cmd object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:uiObject selector:@selector(applyStyling:) object:nil];
    [self applyStylingWithAnimation:uiObject includeSubViews:YES];
}

- (void) applyStylingWithAnimation:(id)uiObject includeSubViews:(BOOL)includeSubViews {
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^() {
        [self applyStyling:uiObject includeSubViews:includeSubViews];
    } completion:nil];
}


#pragma mark - Style classes

- (NSSet*) styleClassesForUIObject:(id)uiObject {
    return [self viewPropertiesForView:uiObject].styleClasses;
}

- (void) setStyleClasses:(NSSet*)styleClasses forUIObject:(id)uiObject {
    if( styleClasses.count ) {
        [self viewPropertiesForView:uiObject].styleClasses = styleClasses;
    } else {
        [self viewPropertiesForView:uiObject].styleClasses = nil;
    }

    [self clearCachedStylesForUIObject:uiObject];
}

- (void) addStyleClass:(NSString*)styleClass forUIObject:(id)uiObject {
    ViewProperties* viewProperties = [self viewPropertiesForView:uiObject];
    
    NSSet* newClasses = [NSSet setWithObject:styleClass];
    NSSet* existingClasses = viewProperties.styleClasses;
    if( existingClasses ) newClasses = [newClasses setByAddingObjectsFromSet:existingClasses];
    viewProperties.styleClasses = newClasses;

    [self clearCachedStylesForUIObject:uiObject];
}

- (void) removeStyleClass:(NSString*)styleClass forUIObject:(id)uiObject {
    ViewProperties* viewProperties = [self viewPropertiesForView:uiObject];

    NSSet* existingClasses = viewProperties.styleClasses;
    if( existingClasses ) {
        NSPredicate* predicate = [NSPredicate predicateWithBlock:^(id o, NSDictionary *b) {
            return (BOOL)![styleClass isEqual:o];
        }];
        viewProperties.styleClasses = [existingClasses filteredSetUsingPredicate:predicate];
    }
    [self clearCachedStylesForUIObject:uiObject];
}


#pragma mark - Prototypes

- (void) registerPrototype:(ISSViewPrototype*)prototype {
    if( prototype.name ) self.prototypes[prototype.name] = prototype;
    else ISSLogWarning(@"Attempted to register prototype without name!");
}

- (UIView*) viewFromPrototypeWithName:(NSString*)prototypeName {
    return [self.prototypes[prototypeName] createViewObjectFromPrototype:nil];
}


#pragma mark - Stylesheets

- (ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName {
    return [self loadStyleSheetFromFileURL:[[NSBundle mainBundle] URLForResource:styleSheetFileName withExtension:nil]];
}

- (ISSStyleSheet*) loadStyleSheetFromFile:(NSString*)styleSheetFilePath {
    return [self loadStyleSheetFromFileURL:[NSURL fileURLWithPath:styleSheetFilePath]];
}

- (ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetURL {
    ISSStyleSheet* styleSheet = [[ISSStyleSheet alloc] initWithStyleSheetURL:styleSheetURL declarations:nil refreshable:YES];
    [self.styleSheets addObject:styleSheet];
    [self updateRefreshableStyleSheet:styleSheet];
    [self enableAutoRefreshTimer];
    return styleSheet;
}

- (void) unloadStyleSheet:(ISSStyleSheet*)styleSheet refreshStyling:(BOOL)refreshStyling {
    [self.styleSheets removeObject:styleSheet];
    [self.cachedStylesForViews removeAllObjects];
    if( refreshStyling ) [self refreshStyling];
}

- (void) unloadAllStyleSheets:(BOOL)refreshStyling {
    [self.styleSheets removeAllObjects];
    [self.cachedStylesForViews removeAllObjects];
    if( refreshStyling ) [self refreshStyling];
}

@end
