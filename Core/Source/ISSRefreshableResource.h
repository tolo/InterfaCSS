//
//  ISSRefreshableResource.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@class ISSStylingManager;


NS_ASSUME_NONNULL_BEGIN


extern NSString* const ISSRefreshableResourceErrorDomain;


typedef void (^ISSRefreshableResourceLoadCompletionBlock)(BOOL success,  NSString* _Nullable responseString, NSError* _Nullable error);


@interface ISSRefreshableResource : NSObject

@property (nonatomic, readonly) NSURL* resourceURL;
@property (nonatomic, readonly) BOOL usingLocalFileChangeMonitoring;
@property (nonatomic, readonly) BOOL hasErrorOccurred;
@property (nonatomic, readonly) NSError* lastError;


- (instancetype) initWithURL:(NSURL*)url;

- (void) startMonitoringLocalFileChanges:(void (^)(ISSRefreshableResource*))callbackBlock;
- (void) endMonitoringLocalFileChanges;

- (void) refreshWithCompletionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler refreshIntervalDuringError:(NSTimeInterval)refreshIntervalDuringError force:(BOOL)force;

@end


NS_ASSUME_NONNULL_END
