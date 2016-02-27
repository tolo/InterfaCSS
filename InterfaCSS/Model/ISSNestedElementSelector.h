//
//  ISSNestedElementSelector.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSSelector.h"

@interface ISSNestedElementSelector : ISSSelector

+ (instancetype) selectorWithNestedElementKeyPath:(NSString*)nestedElementKeyPath;

@property (nonatomic, strong, readonly) NSString* nestedElementKeyPath;

@end
