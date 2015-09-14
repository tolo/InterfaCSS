//
//  ISSRefreshableResource.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2015-09-12.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSUpdatableValue.h"


extern NSString* const ISSResourceDownloadedNotification;
extern NSString* const ISSResourceDownloadFailedNotification;


@interface ISSDownloadableResource : ISSUpdatableValue

@property (nonatomic, readonly) NSURL* resourceURL;
@property (nonatomic, weak, readonly) id cachedResource;

+ (instancetype) downloadableFontWithURL:(NSURL*)url;
+ (instancetype) downloadableImageWithURL:(NSURL*)url;

+ (void) clearCaches;

- (void) download:(BOOL)force;

@end
