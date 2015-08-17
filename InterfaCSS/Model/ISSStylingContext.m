//
//  ISSStylingContext.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2015-08-16.
//  Copyright (c) 2015 Leafnode AB.
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
