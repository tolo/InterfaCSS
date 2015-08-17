//
//  ISSStylingContext.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2015-08-16.
//  Copyright (c) 2015 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@interface ISSStylingContext : NSObject

@property (nonatomic) BOOL ignorePseudoClasses;

@property (nonatomic) BOOL containsPartiallyMatchedDeclarations;

+ (instancetype) contextIgnoringPseudoClasses;

@end
