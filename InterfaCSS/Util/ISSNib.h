//
//  ISSNib.h
//  InterfaCSS
//
//  Created by Todd Brannam on 10/24/14.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ISSViewPrototype;

@interface ISSNib : UINib
- (instancetype)initWithPrototype:(ISSViewPrototype *)viewPrototype;
@end
