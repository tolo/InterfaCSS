//
//  ISSStylingContext.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSStylingContext.h"

#import "ISSStyleSheet.h"

@implementation ISSStylingContext

- (instancetype) initWithStylingManager:(ISSStylingManager*)stylingManager styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    return [self initWithStylingManager:stylingManager styleSheetScope:styleSheetScope ignorePseudoClasses:NO];
}

- (instancetype) initWithStylingManager:(ISSStylingManager*)stylingManager styleSheetScope:(ISSStyleSheetScope*)styleSheetScope ignorePseudoClasses:(BOOL)ignorePseudoClasses {
    if (self = [super init]) {
        _stylingManager = stylingManager;
        _styleSheetScope = styleSheetScope;
        _ignorePseudoClasses = ignorePseudoClasses;

        _containsPartiallyMatchedDeclarations = NO;
        _stylesCacheable = YES;
    }
    return self;
}

@end
