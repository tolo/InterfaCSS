//
//  ISSLazyValue.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-16.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSLazyValue.h"

@interface ISSLazyValue ()
@property (nonatomic, copy) ISSLazyValueBlock lazyValueBlock;
@end

@implementation ISSLazyValue

- (id) initWithLazyEvaluationBlock:(ISSLazyValueBlock)block {
    self = [super init];
    if ( self ) {
        self.lazyValueBlock = block;
    }
    return self;
}

- (id) evaluateWithViewObject:(id)viewObject {
    return self.lazyValueBlock(viewObject);
}

@end
