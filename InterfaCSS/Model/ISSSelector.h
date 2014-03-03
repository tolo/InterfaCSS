//
//  ISSSelector.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@interface ISSSelector : NSObject<NSCopying>

@property (nonatomic, readonly) NSString* type;
@property (nonatomic, readonly) NSString* styleClass;
@property (nonatomic, readonly) NSString* displayDescription;

- (id) initWithType:(NSString*)type class:(NSString*)styleClass;

- (BOOL) matchesComponent:(id)component;

@end
