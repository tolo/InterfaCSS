//
//  ISSRefreshableResource.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-07.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSRefreshableResource.h"
#import "NSString+ISSStringAdditions.h"
#import "NSObject+ISSLogSupport.h"
#import "ISSDateUtils.h"
#import "InterfaCSS.h"


@implementation ISSRefreshableResource {
    NSDate* _lastModified;
    NSString* _eTag;
    NSTimeInterval _lastErrorTime;
    dispatch_source_t _fileChangeSource;
}

- (instancetype) initWithURL:(NSURL*)url {
    if( (self = [super init]) ) {
        _resourceURL = url;
    }
    return self;
}

- (void) dealloc {
    [self endMonitoringLocalFileChanges];
}

- (BOOL) usingLocalFileChangeMonitoring {
    return _fileChangeSource != nil;
}

- (void) endMonitoringLocalFileChanges {
    if( _fileChangeSource ) dispatch_source_cancel(_fileChangeSource);
    _fileChangeSource = nil;
}

- (void) startMonitoringLocalFileChanges:(void (^)(ISSRefreshableResource*))callbackBlock {
    if( self.usingLocalFileChangeMonitoring ) {
        [self endMonitoringLocalFileChanges];
    }
    
    int fd = open([self.resourceURL.path fileSystemRepresentation], O_EVTONLY);
    
    if( fd < 0 ) {
        ISSLogWarning(@"Unable to monitor '%@' for changes", self.resourceURL);
        return;
    }
    
    _fileChangeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE, DISPATCH_TARGET_QUEUE_DEFAULT);
    
    __weak ISSRefreshableResource* weakSelf = self;
    dispatch_source_set_event_handler(_fileChangeSource, ^() {
        unsigned long const data = dispatch_source_get_data(_fileChangeSource);
        dispatch_async(dispatch_get_main_queue(), ^{
            if( data & DISPATCH_VNODE_WRITE ) {
                callbackBlock(weakSelf);
            } else if( data & DISPATCH_VNODE_DELETE ) {
                [weakSelf endMonitoringLocalFileChanges];
                [weakSelf iss_logWarning:@"'%@' deleted - file monitoring aborted", weakSelf.resourceURL];
            }
        });
    });
    
    dispatch_source_set_cancel_handler(_fileChangeSource, ^(){
        close(fd);
    });
    
    dispatch_resume(_fileChangeSource);
    
    ISSLogDebug(@"Started monitoring '%@' for changes", self.resourceURL);
}

- (NSDate*) parseLastModifiedFromResponse:(NSHTTPURLResponse*)response {
    NSDate* updatedLastModified = [response.allHeaderFields[@"Last-Modified"] iss_parseHttpDate];
    if( !updatedLastModified ) updatedLastModified = [response.allHeaderFields[@"Date"] iss_parseHttpDate];
    return updatedLastModified;
}

- (BOOL) hasErrorOccurred {
    return _lastErrorTime != 0;
}

- (void) resetErrorOccurred {
    _lastErrorTime = 0;
}

- (void) errorOccurred {
    _lastErrorTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void) performHeadRequest:(NSMutableURLRequest*)request completionHandler:(void (^)(NSString*))completionHandler {
    [request setHTTPMethod:@"HEAD"];

    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        BOOL signalErrorOccurred = NO;
        if ( error == nil ) {
            NSHTTPURLResponse* httpURLResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse*)response : nil;
            if( 200 == httpURLResponse.statusCode ) {
                NSString* updatedETag = httpURLResponse.allHeaderFields[@"ETag"];
                BOOL eTagModified = _eTag != nil && ![_eTag isEqualToString:updatedETag];
                NSDate* updatedLastModified = [self parseLastModifiedFromResponse:httpURLResponse];
                BOOL lastModifiedModified = _lastModified != nil && ![_lastModified isEqualToDate:updatedLastModified];
                if( eTagModified || lastModifiedModified ) { // In case server didn't honor etag/last modified
                    ISSLogDebug(@"Remote stylesheet modified - executing get request");
                    [self performGetRequest:request completionHandler:completionHandler];
                } else {
                    ISSLogTrace(@"Remote stylesheet NOT modified - %@/%@, %@/%@", _eTag, updatedETag, _lastModified, updatedLastModified);
                }
            } else if( 304 == httpURLResponse.statusCode ) {
                ISSLogTrace(@"Remote stylesheet not modified");
            } else {
                if( self.hasErrorOccurred ) ISSLogTrace(@"Unable to verify if remote stylesheet is modified - got HTTP response code %d", httpURLResponse.statusCode);
                else ISSLogDebug(@"Unable to verify if remote stylesheet is modified - got HTTP response code %d", httpURLResponse.statusCode);
                signalErrorOccurred = YES;
            }
        } else {
            if( self.hasErrorOccurred ) ISSLogTrace(@"Error verifying if remote stylesheet is modified - %@", error);
            else ISSLogDebug(@"Error verifying if remote stylesheet is modified - %@", error);
            signalErrorOccurred = YES;
        }

        if( signalErrorOccurred ) [self errorOccurred];
        else [self resetErrorOccurred];
    }];
}

- (void) performGetRequest:(NSMutableURLRequest*)request completionHandler:(void (^)(NSString*))completionHandler {
    [request setHTTPMethod:@"GET"];

    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init]
       completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
           BOOL signalErrorOccurred = NO;
           if ( error == nil ) {
               NSHTTPURLResponse* httpURLResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse*)response : nil;
               if( 200 == httpURLResponse.statusCode ) {
                   ISSLogDebug(@"Remote stylesheet downloaded - parsing response data");
                   _eTag = httpURLResponse.allHeaderFields[@"ETag"];
                   _lastModified = [self parseLastModifiedFromResponse:httpURLResponse];

                   NSString* encodingName = [httpURLResponse textEncodingName];
                   NSStringEncoding encoding = NSUTF8StringEncoding;
                   if( encodingName ) {
                       CFStringEncoding cfStringEncoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)encodingName);
                       if( cfStringEncoding != kCFStringEncodingInvalidId ) {
                           encoding = CFStringConvertEncodingToNSStringEncoding(cfStringEncoding);
                       }
                   }
                   NSString* responseString = [[NSString alloc] initWithData:data encoding:encoding];

                   dispatch_async(dispatch_get_main_queue(), ^{
                       completionHandler(responseString);
                   });
               } else if( 304 == httpURLResponse.statusCode ) {
                   ISSLogTrace(@"Remote stylesheet not modified");
               } else {
                   if( self.hasErrorOccurred ) ISSLogTrace(@"Unable to download remote stylesheet - got HTTP response code %d", httpURLResponse.statusCode);
                   else ISSLogDebug(@"Unable to download remote stylesheet - got HTTP response code %d", httpURLResponse.statusCode);
                   signalErrorOccurred = YES;
               }
           } else {
               if( self.hasErrorOccurred ) ISSLogTrace(@"Error downloading stylesheet - %@", error);
               else ISSLogDebug(@"Error downloading stylesheet - %@", error);
               signalErrorOccurred = YES;
           }

           if( signalErrorOccurred ) [self errorOccurred];
           else [self resetErrorOccurred];
       }];
}

- (void) refreshWithCompletionHandler:(void (^)(NSString*))completionHandler {
    if( self.hasErrorOccurred ) {
        NSTimeInterval refreshIntervalDuringError = [InterfaCSS interfaCSS].stylesheetAutoRefreshInterval * 3;
        if( ([NSDate timeIntervalSinceReferenceDate] - _lastErrorTime) < refreshIntervalDuringError ) return;
    }

    if( self.resourceURL.isFileURL ) {
        NSFileManager* fm = [NSFileManager defaultManager];
        NSDictionary* attrs = [fm attributesOfItemAtPath:self.resourceURL.path error:nil];
        NSDate* date;
        if (attrs != nil) {
            date = (NSDate*)attrs[NSFileModificationDate];
            if( !date ) date = (NSDate*)attrs[NSFileCreationDate];
        }
        if( !_lastModified || ![_lastModified isEqualToDate:date] ) {
            completionHandler([[NSString alloc] initWithContentsOfFile:self.resourceURL.path usedEncoding:nil error:nil]);
            _lastModified = date;
        }
    } else {
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.resourceURL];
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        if( _lastModified ) [request setValue:[ISSDateUtils formatHttpDate:_lastModified] forHTTPHeaderField:@"If-Modified-Since"];
        if( _eTag ) [request setValue:_eTag forHTTPHeaderField:@"If-None-Match"];

        if( _lastModified || _eTag ) [self performHeadRequest:request completionHandler:completionHandler];
        else [self performGetRequest:request completionHandler:completionHandler];
    }
}

@end