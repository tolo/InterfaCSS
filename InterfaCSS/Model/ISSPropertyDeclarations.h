//
//  ISSPropertyDeclarations.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@interface ISSPropertyDeclarations : NSObject

@property (nonatomic, readonly) NSArray* selectorChains;
@property (nonatomic, readonly) NSDictionary* properties;
@property (nonatomic, readonly) NSString* displayDescription;

- (id) initWithSelectorChains:(NSArray*)selectorChains andProperties:(NSDictionary*)properties;

- (BOOL) matchesView:(UIView*)view;

@end
