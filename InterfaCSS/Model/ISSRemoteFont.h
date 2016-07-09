//
//  ISSRemoteFont.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "ISSUpdatableValue.h"

NS_ASSUME_NONNULL_BEGIN


@class ISSDownloadableResource;

@interface ISSRemoteFont : ISSUpdatableValue

@property (nonatomic, strong, readonly) ISSDownloadableResource* remoteFont;
@property (nonatomic, readonly) CGFloat fontSize;

+ (instancetype) remoteFontWithResource:(ISSDownloadableResource*)remoteFont fontSize:(CGFloat)fontSize;
+ (instancetype) remoteFontWithURL:(NSURL*)url fontSize:(CGFloat)fontSize;

@end


NS_ASSUME_NONNULL_END
