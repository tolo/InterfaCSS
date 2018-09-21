//
//  ISSRefreshableResource.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@class ISSStylingManager, ISSRefreshableResource;


NS_ASSUME_NONNULL_BEGIN


extern NSString* const ISSRefreshableResourceErrorDomain;


typedef void (^ISSRefreshableResourceObserverBlock)(ISSRefreshableResource* refreshableResource);
typedef void (^ISSRefreshableResourceLoadCompletionBlock)(BOOL success,  NSString* _Nullable responseString, NSError* _Nullable error);


@interface ISSRefreshableResource : NSObject

@property (nonatomic, readonly) NSURL* resourceURL;

@property (nonatomic, readonly) BOOL hasErrorOccurred;
@property (nonatomic, readonly, nullable) NSError* lastError;

@property (nonatomic, readonly) BOOL resourceModificationMonitoringSupported;
@property (nonatomic, readonly) BOOL resourceModificationMonitoringEnabled;

- (instancetype) initWithURL:(NSURL*)url;

- (void) startMonitoringResourceModification:(ISSRefreshableResourceObserverBlock)modificationObserver;
- (void) endMonitoringResourceModification;

- (void) refreshWithCompletionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler refreshIntervalDuringError:(NSTimeInterval)refreshIntervalDuringError force:(BOOL)force;

@end


@interface ISSRefreshableLocalResource : ISSRefreshableResource
@end

@interface ISSRefreshableRemoteResource : ISSRefreshableResource
@end


NS_ASSUME_NONNULL_END
