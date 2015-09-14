//
//  ISSRemoteFont.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2015-09-14.
//  Copyright (c) 2015 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSUpdatableValue.h"

@class ISSDownloadableResource;

@interface ISSRemoteFont : ISSUpdatableValue

@property (nonatomic, strong, readonly) ISSDownloadableResource* remoteFont;
@property (nonatomic, readonly) CGFloat fontSize;

+ (instancetype) remoteFontWithResource:(ISSDownloadableResource*)remoteFont fontSize:(CGFloat)fontSize;
+ (instancetype) remoteFontWithURL:(NSURL*)url fontSize:(CGFloat)fontSize;

@end
