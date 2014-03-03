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

- (void) refresh:(NSURL*)url completionHandler:(void (^)(NSString*))completionHandler;

@end
