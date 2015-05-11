//
// Created by Tobias Löfstrand on 2015-01-24.
// Copyright (c) 2015 Leafnode AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ISSLayout;


typedef void (^ISSLayoutPostProcessingBlock)(UIView* view, ISSLayout* layout);


/**
 * ISSLayoutContextView
 */
@interface ISSLayoutContextView : UIView

@property (nonatomic, copy) ISSLayoutPostProcessingBlock layoutPostProcessingBlock;

@end
