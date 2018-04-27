//
//  ISSRefreshableResource.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSRefreshableResource.h"
#import "NSString+ISSStringAdditions.h"
#import "NSObject+ISSLogSupport.h"
#import "ISSDateUtils.h"
#import "InterfaCSS.h"


NSString* const ISSRefreshableResourceErrorDomain = @"InterfaCSS.RefreshableResource";


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
        ISSLogWarning(@"Unable to monitor '%@' for changes (file could not be opened)", self.resourceURL);
        return;
    }
    
    _fileChangeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE, DISPATCH_TARGET_QUEUE_DEFAULT);
    if( _fileChangeSource ) {
        __weak ISSRefreshableResource* weakSelf = self;
        dispatch_source_set_event_handler(_fileChangeSource, ^() {
            unsigned long const data = dispatch_source_get_data(self->_fileChangeSource);
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock(weakSelf);
                if( data & DISPATCH_VNODE_DELETE ) {
                    [weakSelf iss_logDebug:@"'%@' seems to have been deleted - attempting to restart monitoring of file", weakSelf.resourceURL];
                    [weakSelf startMonitoringLocalFileChanges:callbackBlock];
                }
            });
        });
        
        dispatch_source_set_cancel_handler(_fileChangeSource, ^(){
            close(fd);
        });
        
        dispatch_resume(_fileChangeSource);
        
        ISSLogDebug(@"Started monitoring '%@' for changes", self.resourceURL);
    } else {
        ISSLogWarning(@"Unable to monitor '%@' for changes (error creating dispatch source)", self.resourceURL);
    }
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
    _lastError = nil;
    _lastErrorTime = 0;
}

- (void) errorOccurred:(NSError*)error {
    _lastError = error;
    _lastErrorTime = [NSDate timeIntervalSinceReferenceDate];
}

- (void) performHeadRequest:(NSMutableURLRequest*)request completionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler {
    [request setHTTPMethod:@"HEAD"];

    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        BOOL signalErrorOccurred = NO;
        if ( error == nil ) {
            NSHTTPURLResponse* httpURLResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse*)response : nil;
            if( 200 == httpURLResponse.statusCode ) {
                NSString* updatedETag = httpURLResponse.allHeaderFields[@"ETag"];
                BOOL eTagModified = self->_eTag != nil && ![self->_eTag isEqualToString:updatedETag];
                NSDate* updatedLastModified = [self parseLastModifiedFromResponse:httpURLResponse];
                BOOL lastModifiedModified = self->_lastModified != nil && ![self->_lastModified isEqualToDate:updatedLastModified];
                if( eTagModified || lastModifiedModified ) { // In case server didn't honor etag/last modified
                    ISSLogDebug(@"Remote resource modified - executing get request");
                    [self performGetRequest:request completionHandler:completionHandler];
                } else {
                    ISSLogTrace(@"Remote resource NOT modified - %@/%@, %@/%@", self->_eTag, updatedETag, self->_lastModified, updatedLastModified);
                }
            } else if( 304 == httpURLResponse.statusCode ) {
                ISSLogTrace(@"Remote resource not modified");
            } else {
                error = [NSError errorWithDomain:ISSRefreshableResourceErrorDomain code:1001 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unable to verify if remote resource is modified - got HTTP response code %ld", (long)httpURLResponse.statusCode]}];
                if( self.hasErrorOccurred ) ISSLogTrace(error.localizedDescription);
                else ISSLogDebug(error.localizedDescription);
                signalErrorOccurred = YES;
            }
        } else {
            if( self.hasErrorOccurred ) ISSLogTrace(@"Error verifying if remote resource is modified - %@", error);
            else ISSLogDebug(@"Error verifying if remote resource is modified - %@", error);
            signalErrorOccurred = YES;
        }

        if( signalErrorOccurred ) {
            [self errorOccurred:error];
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(NO, nil, error);
            });
        }
        else [self resetErrorOccurred];
    }];
}

- (void) performGetRequest:(NSMutableURLRequest*)request completionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler {
    [request setHTTPMethod:@"GET"];

    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init]
       completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
           BOOL signalErrorOccurred = NO;
           if ( error == nil ) {
               NSHTTPURLResponse* httpURLResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse*)response : nil;
               if( 200 == httpURLResponse.statusCode ) {
                   ISSLogDebug(@"Remote resource downloaded - parsing response data");
                   self->_eTag = httpURLResponse.allHeaderFields[@"ETag"];
                   self->_lastModified = [self parseLastModifiedFromResponse:httpURLResponse];

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
                       completionHandler(YES, responseString, nil);
                   });
               } else if( 304 == httpURLResponse.statusCode ) {
                   ISSLogTrace(@"Remote resource not modified");
               } else {
                   error = [NSError errorWithDomain:ISSRefreshableResourceErrorDomain code:1002 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Unable to download remote resource- got HTTP response code %ld", (long)httpURLResponse.statusCode]}];
                   if( self.hasErrorOccurred ) ISSLogTrace(error.localizedDescription);
                   else ISSLogDebug(error.localizedDescription);
                   signalErrorOccurred = YES;
               }
           } else {
               if( self.hasErrorOccurred ) ISSLogTrace(@"Error downloading resource - %@", error);
               else ISSLogDebug(@"Error downloading resource - %@", error);
               signalErrorOccurred = YES;
           }

           if( signalErrorOccurred ) {
               [self errorOccurred:error];
               dispatch_async(dispatch_get_main_queue(), ^{
                   completionHandler(NO, nil, error);
               });
           }
           else [self resetErrorOccurred];
       }];
}

- (void) refreshWithCompletionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler force:(BOOL)force {
    if( self.hasErrorOccurred ) {
        NSTimeInterval refreshIntervalDuringError = [InterfaCSS sharedInstance].stylesheetAutoRefreshInterval * 3;
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
        if( force || !_lastModified || ![_lastModified isEqualToDate:date] ) {
            completionHandler(YES, [[NSString alloc] initWithContentsOfFile:self.resourceURL.path usedEncoding:nil error:nil], nil);
            _lastModified = date;
        }
    } else {
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.resourceURL];
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        if( !force ) {
            if( _lastModified ) [request setValue:[ISSDateUtils formatHttpDate:_lastModified] forHTTPHeaderField:@"If-Modified-Since"];
            if( _eTag ) [request setValue:_eTag forHTTPHeaderField:@"If-None-Match"];
        }

        if( !force && (_lastModified || _eTag) ) [self performHeadRequest:request completionHandler:completionHandler];
        else [self performGetRequest:request completionHandler:completionHandler];
    }
}

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSRefreshableResource[%@]", self.resourceURL.lastPathComponent];
}

@end
