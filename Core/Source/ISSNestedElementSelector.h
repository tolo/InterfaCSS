//
//  ISSNestedElementSelector.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSSelector.h"

NS_ASSUME_NONNULL_BEGIN

NS_SWIFT_NAME(NestedElementSelector)
@interface ISSNestedElementSelector : ISSSelector

+ (instancetype) selectorWithNestedElementKeyPath:(NSString*)nestedElementKeyPath;

@property (nonatomic, strong, readonly) NSString* nestedElementKeyPath;

@end


NS_ASSUME_NONNULL_END
