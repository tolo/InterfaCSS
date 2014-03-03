//
//  ISSLazyValue.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//  
//  Created by Tobias Löfstrand on 2014-02-16.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

typedef id (^ISSLazyValueBlock)(id uiObject);


@interface ISSLazyValue : NSObject

- (id) initWithLazyEvaluationBlock:(ISSLazyValueBlock)block;

- (id) evaluateWithViewObject:(id)viewObject;

@end