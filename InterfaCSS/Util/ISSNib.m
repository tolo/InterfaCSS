//
//  ISSNib.m
//  InterfaCSS
//
//  Created by Todd Brannam on 10/24/14.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import "ISSNib.h"
#import "ISSViewPrototype.h"

@interface ISSNib()
@property (nonatomic, strong) ISSViewPrototype *viewPrototype;
@end

@implementation ISSNib

- (instancetype)initWithPrototype:(ISSViewPrototype *)viewPrototype
{
    self = [super init];
    self.viewPrototype = viewPrototype;
    return self;
}

- (NSArray *)instantiateWithOwner:(id)ownerOrNil options:(NSDictionary *)optionsOrNil
{
    UIView *view = nil;
    view = [self.viewPrototype createViewObjectFromPrototype:nil];
    return view ? @[view] : @[];
}

@end
