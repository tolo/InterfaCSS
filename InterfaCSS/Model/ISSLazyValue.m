//
//  ISSLazyValue.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSLazyValue.h"

@interface ISSLazyValue ()
@property (nonatomic, copy) ISSLazyValueBlock lazyValueBlock;
@end

@implementation ISSLazyValue

+ (instancetype) lazyValueWithBlock:(ISSLazyValueBlock)block {
    return [[(id)self.class alloc] initWithLazyEvaluationBlock:block];
}

- (instancetype) initWithLazyEvaluationBlock:(ISSLazyValueBlock)block {
    self = [super init];
    if ( self ) {
        self.lazyValueBlock = block;
    }
    return self;
}

- (id) evaluate {
    return self.lazyValueBlock(nil);
}

- (id) evaluateWithParameter:(id)parameter {
    return self.lazyValueBlock(parameter);
}

@end
