//
//  ISSLayoutContextView.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class ISSLayout;


NS_ASSUME_NONNULL_BEGIN


typedef void (^ISSLayoutProcessingBlock)(UIView* view, ISSLayout* _Nullable layout);


/**
 * ISSLayoutContextView handles processing of any `ISSLayout`s defined in subviews. To enable use of `ISSLayout` is a view controller, use this class
 * (or a subclass such as `ISSRootView`) as the root view .
 */
@interface ISSLayoutContextView : UIView

/** Pre processing block for any additional customization of layout before layout is resolved. */
@property (nonatomic, copy, nullable) ISSLayoutProcessingBlock layoutPreProcessingBlock;

/** Post processing block for any additional customization of frame after layout has been resolved. */
@property (nonatomic, copy, nullable) ISSLayoutProcessingBlock layoutPostProcessingBlock;

@end


NS_ASSUME_NONNULL_END
