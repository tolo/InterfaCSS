//
//  ISSNestedElementSelector.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2015-08-05.
//  Copyright (c) 2015 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSSelector.h"

@interface ISSNestedElementSelector : ISSSelector

+ (instancetype) selectorWithNestedElementKeyPath:(NSString*)nestedElementKeyPath;

@property (nonatomic, strong, readonly) NSString* nestedElementKeyPath;

@end
