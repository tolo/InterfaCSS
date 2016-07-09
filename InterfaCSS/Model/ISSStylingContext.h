//
//  ISSStylingContext.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


@interface ISSStylingContext : NSObject

@property (nonatomic) BOOL ignorePseudoClasses;

@property (nonatomic) BOOL containsPartiallyMatchedDeclarations;

+ (instancetype) contextIgnoringPseudoClasses;

@end


NS_ASSUME_NONNULL_END
