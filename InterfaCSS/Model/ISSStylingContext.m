//
//  ISSStylingContext.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSStylingContext.h"

@implementation ISSStylingContext

+ (instancetype) contextIgnoringPseudoClasses {
    ISSStylingContext* context = [[self alloc] init];
    context.ignorePseudoClasses = YES;
    return context;
}

@end
