//
//  ISSSelectorChain.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-03-10.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

#import "ISSRefreshableResource.h"

@class ISSStyleSheetParser;


@interface ISSStyleSheet : ISSRefreshableResource

@property (nonatomic, readonly) NSURL* styleSheetURL;
@property (nonatomic, readonly) NSArray* declarations; // ISSPropertyDeclarations
@property (nonatomic) BOOL active;
@property (nonatomic, readonly) BOOL refreshable;
@property (nonatomic, readonly) NSString* displayDescription;

- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(NSArray*)declarations;
- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(NSArray*)declarations refreshable:(BOOL)refreshable;

- (NSDictionary*) stylesForView:(UIView*)view;

- (void) refresh:(void (^)(void))completionHandler parse:(ISSStyleSheetParser*)styleSheetParser;

@end
