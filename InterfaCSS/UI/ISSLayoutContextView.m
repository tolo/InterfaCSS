//
//  ISSLayoutContextView.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSLayoutContextView.h"

#import "ISSUIElementDetails.h"
#import "ISSLayout.h"


@implementation ISSLayoutContextView {
    BOOL didLayoutOnce;
}

- (void) setupSubviewDetailsWithLayouts:(NSMutableArray*)subviewsDetails andResolvedElements:(NSMutableDictionary*)resolvedElements forView:(UIView*)view {
    ISSUIElementDetails* details = [[InterfaCSS sharedInstance] detailsForUIElement:view];

    // If element has layout - add to array
    if( details.layout ) {
        [subviewsDetails addObject:details];
    }

    // Add elementId to elementDetails mapping to resolvedElements dictionary - but only do it for elements without layout here (i.e. elements with known frames)
    if( details.elementId && !details.layout ) {
        resolvedElements[details.elementId] = details;
    }

    // Drill down
    for (UIView* subview in view.subviews) {
        [self setupSubviewDetailsWithLayouts:subviewsDetails andResolvedElements:resolvedElements forView:subview];
    }
}

- (NSMutableArray*) resolveLayouts:(NSArray*)subviewsDetails resolvedElements:(NSMutableDictionary*)resolvedElements layoutGuideInsets:(UIEdgeInsets)layoutGuideInsets shouldContinueResolve:(BOOL*)shouldContinueResolve {
    BOOL didResolveElements = NO;
    NSMutableArray* unresolved = [NSMutableArray array];

    for(ISSUIElementDetails* elementDetails in subviewsDetails) {
        // Get layout for element
        ISSLayout* layout = elementDetails.layout;

        // Execute layout pre processing block, to enable additional customization of layout before layout is resolved
        if( self.layoutPreProcessingBlock ) {
            self.layoutPreProcessingBlock(elementDetails.view, elementDetails.layout);
        }

        // Attempt resolve of layout to frame
        if( [layout resolveRectForView:elementDetails.view withResolvedElements:resolvedElements andLayoutGuideInsets:(UIEdgeInsets)layoutGuideInsets] ) {
            // Execute layout post processing block, to enable additional customization of frame
            if( self.layoutPostProcessingBlock ) {
                self.layoutPostProcessingBlock(elementDetails.view, elementDetails.layout);
            }
            if( elementDetails.elementId ) {
                resolvedElements[elementDetails.elementId] = elementDetails;
            }
            didResolveElements = YES;
        } else {
            [unresolved addObject:elementDetails];
        }
    }

    *shouldContinueResolve = didResolveElements && unresolved.count > 0;

    return unresolved;
}

- (void) didMoveToSuperview {
    [super didMoveToSuperview];
    if( !self.superview ) didLayoutOnce = NO;
}

- (void) layoutSubviews {
    [super layoutSubviews];

    ISSUIElementDetails* selfDetails = [[InterfaCSS sharedInstance] detailsForUIElement:self];
    
    if( !didLayoutOnce ) { // Make sure styling is applied before proceeding (this is not just important for ISSLayout, but for the use of relative ISSRectValue objects as well)
        if ( ![InterfaCSS sharedInstance].useManualStyling ) {
            [self applyStylingISS];
        }
        didLayoutOnce = YES;
    }

    // Get top and bottom layout guides (thank you Apple)
    UIViewController* parentViewController = selfDetails.closestViewController;
    id<UILayoutSupport> topLayoutGuide = [parentViewController respondsToSelector:@selector(topLayoutGuide)] ? parentViewController.topLayoutGuide : nil;
    id<UILayoutSupport> bottomLayoutGuide = [parentViewController respondsToSelector:@selector(bottomLayoutGuide)] ? parentViewController.bottomLayoutGuide : nil;
    UIEdgeInsets layoutGuideInsets = UIEdgeInsetsMake(topLayoutGuide.length, 0, bottomLayoutGuide.length, 0);
    
    // Gather up details for all views with layouts, and setup mappings of elementId to element details
    NSMutableArray* unresolvedElementDetails = [NSMutableArray array];
    NSMutableDictionary* resolvedElements = [NSMutableDictionary dictionary];
    [self setupSubviewDetailsWithLayouts:unresolvedElementDetails andResolvedElements:resolvedElements forView:self];

    // Make several passes over elementDetails array, to make sure all layouts are resolved
    BOOL shouldContinueResolve = NO;
    do {
        unresolvedElementDetails = [self resolveLayouts:unresolvedElementDetails resolvedElements:resolvedElements layoutGuideInsets:layoutGuideInsets shouldContinueResolve:&shouldContinueResolve];
    } while (shouldContinueResolve);

    if( unresolvedElementDetails.count ) {
        ISSLogWarning(@"Still %d elements with unresolved layouts after execution of layoutSubviews!", unresolvedElementDetails.count);
        NSMutableArray* unresolvedLayoutsDescriptions = [NSMutableArray array];
        for(ISSUIElementDetails* details in unresolvedElementDetails) {
            [unresolvedLayoutsDescriptions addObject:[NSString stringWithFormat:@"%@: %@", details, details.layout]];
        }
        ISSLogDebug(@"Elements with unresolved layouts: %@", unresolvedLayoutsDescriptions);
    }
}

@end
