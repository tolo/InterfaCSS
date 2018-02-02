//
//  ISSLazyValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


typedef id _Nullable (^ISSLazyValueBlock)(id _Nullable parameter);


@interface ISSLazyValue : NSObject

+ (instancetype) lazyValueWithBlock:(ISSLazyValueBlock)block;
- (instancetype) initWithLazyEvaluationBlock:(ISSLazyValueBlock)block;

- (nullable id) evaluate;
- (nullable id) evaluateWithParameter:(nullable id)parameter;

@end


NS_ASSUME_NONNULL_END
