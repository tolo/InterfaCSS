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

NS_SWIFT_NAME(StylingContext)
@interface ISSStylingContext : NSObject

// MARK: - Input
@property (nonatomic, weak, readonly) ISSStylingManager* stylingManager; 

@property (nonatomic, strong, readonly) ISSStyleSheetScope* styleSheetScope;

@property (nonatomic, readonly) BOOL ignorePseudoClasses;

// MARK: - Output
@property (nonatomic) BOOL containsPartiallyMatchedDeclarations;
@property (nonatomic) BOOL stylesCacheable;


// MARK: - Creation
- (instancetype) initWithStylingManager:(ISSStylingManager*)stylingManager styleSheetScope:(ISSStyleSheetScope*)styleSheetScope;
- (instancetype) initWithStylingManager:(ISSStylingManager*)stylingManager styleSheetScope:(ISSStyleSheetScope*)styleSheetScope ignorePseudoClasses:(BOOL)ignorePseudoClasses;

@end


NS_ASSUME_NONNULL_END
