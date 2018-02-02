//
//  ISSStylingContext.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@class ISSStylingManager, ISSStyleSheetScope;


NS_ASSUME_NONNULL_BEGIN


@interface ISSStylingContext : NSObject

@property (nonatomic, weak) ISSStylingManager* stylingManager;

@property (nonatomic, strong, nullable) ISSStyleSheetScope* styleSheetScope;

@property (nonatomic) BOOL ignorePseudoClasses;

@property (nonatomic) BOOL containsPartiallyMatchedDeclarations;


- (instancetype) initWithStylingManager:(ISSStylingManager*)stylingManager styleSheetScope:(nullable ISSStyleSheetScope*)styleSheetScope;
+ (instancetype) contextIgnoringPseudoClasses:(ISSStylingManager*)stylingManager styleSheetScope:(nullable ISSStyleSheetScope*)styleSheetScope;

@end


NS_ASSUME_NONNULL_END
