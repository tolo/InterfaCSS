//
//  ISSStyler.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

@class ISSElementStylingProxy, ISSStylingManager, ISSStyleSheetScope, ISSPropertyManager, ISSStyleSheetManager, ISSStyleSheet;


NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(Styler)
@protocol ISSStyler <NSObject>

@property (nonatomic, readonly) ISSStyleSheetScope* styleSheetScope;
@property (nonatomic, readonly) ISSStylingManager* stylingManager;
@property (nonatomic, readonly) ISSPropertyManager* propertyManager;
@property (nonatomic, readonly) ISSStyleSheetManager* styleSheetManager;


- (id<ISSStyler>) stylerWithScope:(ISSStyleSheetScope*)styleSheetScope includeCurrent:(BOOL)includeCurrent;

- (nullable ISSElementStylingProxy*) stylingProxyFor:(id)uiElement;

/**
 * Applies styling of the specified UI object and also all its children.
 */
- (void) applyStyling:(id)uiElement;

/**
 * Applies styling of the specified UI object and optionally also all its children.
 */
- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews;

/**
 * Applies styling of the specified UI object and optionally also all its children.
 */
- (void) applyStyling:(id)uiElement includeSubViews:(BOOL)includeSubViews force:(BOOL)force;


- (void) clearCachedStylingInformationFor:(id)uiElement includeSubViews:(BOOL)includeSubViews;


#pragma mark - StyleSheetManager methods

- (nullable ISSStyleSheet*) loadStyleSheetFromMainBundleFile:(NSString*)styleSheetFileName;
- (nullable ISSStyleSheet*) loadStyleSheetFromFileURL:(NSURL*)styleSheetFileURL;
- (nullable ISSStyleSheet*) loadRefreshableStyleSheetFromURL:(NSURL*)styleSheetFileURL;

@end


NS_ASSUME_NONNULL_END
