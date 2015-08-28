//
//  ISSRefreshableResource.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-07.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>


@interface ISSRefreshableResource : NSObject

@property (nonatomic, readonly) NSURL* resourceURL;
@property (nonatomic, readonly) BOOL usingLocalFileChangeMonitoring;


- (instancetype) initWithURL:(NSURL*)url;

- (void) startMonitoringLocalFileChanges:(void (^)(ISSRefreshableResource*))callbackBlock;
- (void) endMonitoringLocalFileChanges;

- (void) refreshWithCompletionHandler:(void (^)(NSString*))completionHandler;

@end
