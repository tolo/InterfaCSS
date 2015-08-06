//
//  ISSNestedElementSelector.h
//  InterfaCSS
//
//  Created by PMB on 2015-08-05.
//  Copyright (c) 2015 Leafnode AB. All rights reserved.
//

#import "ISSSelector.h"

@interface ISSNestedElementSelector : ISSSelector

+ (instancetype) selectorWithNestedElementKeyPath:(NSString*)nestedElementKeyPath;

@property (nonatomic, strong, readonly) NSString* nestedElementKeyPath;

@end
