//
//  ISSStylingContext.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSStylingContext.h"

@implementation ISSStylingContext

- (instancetype) initWithStylingManager:(ISSStylingManager*)stylingManager styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    if (self = [super init]) {
        _stylingManager = stylingManager;
        _styleSheetScope = styleSheetScope;
    }
    return self;
}

+ (instancetype) contextIgnoringPseudoClasses:(ISSStylingManager*)stylingManager styleSheetScope:(ISSStyleSheetScope*)styleSheetScope {
    ISSStylingContext* context = [[self alloc] initWithStylingManager:stylingManager styleSheetScope:styleSheetScope];
    context.ignorePseudoClasses = YES;
    return context;
}

@end
