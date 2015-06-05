//
// Created by Tobias Löfstrand on 2015-01-24.
// Copyright (c) 2015 Leafnode AB. All rights reserved.
//

#import "ISSLayoutContextView.h"

#import "ISSUIElementDetails.h"
#import "ISSLayout.h"


@implementation ISSLayoutContextView

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
            resolvedElements[elementDetails.elementId] = elementDetails;
            didResolveElements = YES;
        } else {
            [unresolved addObject:elementDetails];
        }
    }

    *shouldContinueResolve = didResolveElements && unresolved.count > 0;

    return unresolved;
}

- (void) layoutSubviews {
    [super layoutSubviews];

    ISSUIElementDetails* selfDetails = [[InterfaCSS sharedInstance] detailsForUIElement:self];

    // Get top and bottom layout guides (thank you Apple)
    UIViewController* parentViewController = selfDetails.parentViewController;
    id<UILayoutSupport> topLayoutGuide = [parentViewController respondsToSelector:@selector(topLayoutGuide)] ? parentViewController.topLayoutGuide : nil;
    id<UILayoutSupport> bottomLayoutGuide = [parentViewController respondsToSelector:@selector(bottomLayoutGuide)] ? parentViewController.bottomLayoutGuide : nil;
    UIEdgeInsets layoutGuideInsets = UIEdgeInsetsMake(topLayoutGuide.length, 0, bottomLayoutGuide.length, 0);

    // Make sure styling is applied before proceeding
    if( !selfDetails.stylingApplied ) {
        [[InterfaCSS interfaCSS] applyStyling:self];
    }

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
