//
//  ISSStylingContext.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@interface ISSStylingContext : NSObject

@property (nonatomic) BOOL ignorePseudoClasses;

@property (nonatomic) BOOL containsPartiallyMatchedDeclarations;

+ (instancetype) contextIgnoringPseudoClasses;

@end
