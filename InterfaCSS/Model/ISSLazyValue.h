//
//  ISSLazyValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>


typedef id (^ISSLazyValueBlock)(id parameter);


@interface ISSLazyValue : NSObject

+ (instancetype) lazyValueWithBlock:(ISSLazyValueBlock)block;
- (instancetype) initWithLazyEvaluationBlock:(ISSLazyValueBlock)block;

- (id) evaluate;
- (id) evaluateWithParameter:(id)parameter;

@end