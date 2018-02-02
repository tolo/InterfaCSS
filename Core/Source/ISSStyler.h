//
//  ISSStyler.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

@class ISSElementStylingProxy;


NS_ASSUME_NONNULL_BEGIN


@protocol ISSStyler <NSObject>

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

@end


NS_ASSUME_NONNULL_END
