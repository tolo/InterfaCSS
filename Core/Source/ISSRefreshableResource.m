//
//  ISSRefreshableResource.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSRefreshableResource.h"

#import "ISSDateUtils.h"

#import "NSString+ISSAdditions.h"
#import "NSObject+ISSLogSupport.h"

NSString* const ISSRefreshableResourceErrorDomain = @"InterfaCSS.RefreshableResource";


@interface ISSRefreshableResource()

@property (nonatomic, strong) NSDate* lastModified;
@property (nonatomic) NSTimeInterval lastErrorTime;

@end

@implementation ISSRefreshableResource

- (instancetype) initWithURL:(NSURL*)url {
    if( (self = [super init]) ) {
        _resourceURL = url;
    }
    return self;
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

- (BOOL) resourceModificationMonitoringSupported {
    return NO;
}

- (BOOL) resourceModificationMonitoringEnabled {
    return NO;
}

- (void) startMonitoringResourceModification:(ISSRefreshableResourceObserverBlock)modificationObserver {}
- (void) endMonitoringResourceModification {}

- (void) refreshWithCompletionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler refreshIntervalDuringError:(NSTimeInterval)refreshIntervalDuringError force:(BOOL)force {}

- (void) unload {}

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSRefreshableResource[%@]", self.resourceURL.lastPathComponent];
}

@end


#pragma mark - ISSRefreshableLocalResource

@implementation ISSRefreshableLocalResource {
    dispatch_source_t _fileChangeSource;
}

- (void) dealloc {
    [self endMonitoringResourceModification];
}

- (BOOL) resourceModificationMonitoringSupported {
    return YES;
}

- (BOOL) resourceModificationMonitoringEnabled {
    return _fileChangeSource != nil;
}

- (void) startMonitoringResourceModification:(void (^)(ISSRefreshableResource*))callbackBlock {
    if( self.resourceModificationMonitoringEnabled ) {
        [self endMonitoringResourceModification];
    }

    int fd = open([self.resourceURL.path fileSystemRepresentation], O_EVTONLY);

    if( fd < 0 ) {
        ISSLogWarning(@"Unable to monitor '%@' for changes (file could not be opened)", self.resourceURL);
        return;
    }

    _fileChangeSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, fd, DISPATCH_VNODE_WRITE | DISPATCH_VNODE_DELETE, DISPATCH_TARGET_QUEUE_DEFAULT);
    if( _fileChangeSource ) {
        __weak ISSRefreshableLocalResource* weakSelf = self;
        dispatch_source_set_event_handler(_fileChangeSource, ^() {
            unsigned long const data = dispatch_source_get_data(self->_fileChangeSource);
            dispatch_async(dispatch_get_main_queue(), ^{
                callbackBlock(weakSelf);
                if( data & DISPATCH_VNODE_DELETE ) {
                    [weakSelf iss_logDebug:@"'%@' seems to have been deleted - attempting to restart monitoring of file", weakSelf.resourceURL];
                    [weakSelf startMonitoringResourceModification:callbackBlock];
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

- (void) endMonitoringResourceModification {
    if( _fileChangeSource ) dispatch_source_cancel(_fileChangeSource);
    _fileChangeSource = nil;
}

- (void) refreshWithCompletionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler refreshIntervalDuringError:(NSTimeInterval)refreshIntervalDuringError force:(BOOL)force {
    if( self.hasErrorOccurred ) {
        if( ([NSDate timeIntervalSinceReferenceDate] - self.lastErrorTime) < refreshIntervalDuringError ) return;
    }

    NSFileManager* fm = [NSFileManager defaultManager];
    NSDictionary* attrs = [fm attributesOfItemAtPath:self.resourceURL.path error:nil];
    NSDate* date;
    if (attrs != nil) {
        date = (NSDate*)attrs[NSFileModificationDate];
        if( !date ) date = (NSDate*)attrs[NSFileCreationDate];
    }
    if( force || !self.lastModified || ![self.lastModified isEqualToDate:date] ) {
        completionHandler(YES, [[NSString alloc] initWithContentsOfFile:self.resourceURL.path usedEncoding:nil error:nil], nil);
        self.lastModified = date;
    }
}

@end


#pragma mark - ISSRefreshableRemoteResource

@interface ISSRefreshableRemoteResource()

@property (nonatomic, strong) NSString* eTag;

@end

@implementation ISSRefreshableRemoteResource

- (void) refreshWithCompletionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler refreshIntervalDuringError:(NSTimeInterval)refreshIntervalDuringError force:(BOOL)force {
    if( self.hasErrorOccurred ) {
        if( ([NSDate timeIntervalSinceReferenceDate] - self.lastErrorTime) < refreshIntervalDuringError ) return;
    }

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.resourceURL];
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    if( !force ) {
        if( self.lastModified ) [request setValue:[ISSDateUtils formatHttpDate:self.lastModified] forHTTPHeaderField:@"If-Modified-Since"];
        if( self.eTag ) [request setValue:self.eTag forHTTPHeaderField:@"If-None-Match"];
    }

    if( !force && (self.lastModified || self.eTag) ) [self performHeadRequest:request completionHandler:completionHandler];
    else [self performGetRequest:request completionHandler:completionHandler];
}

- (NSDate*) parseLastModifiedFromResponse:(NSHTTPURLResponse*)response {
    NSDate* updatedLastModified = [response.allHeaderFields[@"Last-Modified"] iss_parseHttpDate];
    if( !updatedLastModified ) updatedLastModified = [response.allHeaderFields[@"Date"] iss_parseHttpDate];
    return updatedLastModified;
}

- (void) performHeadRequest:(NSMutableURLRequest*)request completionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler {
    [request setHTTPMethod:@"HEAD"];

    NSURLSessionTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:request
        completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        BOOL signalErrorOccurred = NO;
        if ( error == nil ) {
            NSHTTPURLResponse* httpURLResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse*)response : nil;
            if( 200 == httpURLResponse.statusCode ) {
                NSString* updatedETag = httpURLResponse.allHeaderFields[@"ETag"];
                BOOL eTagModified = self->_eTag != nil && ![self->_eTag isEqualToString:updatedETag];
                NSDate* updatedLastModified = [self parseLastModifiedFromResponse:httpURLResponse];
                BOOL lastModifiedModified = self.lastModified != nil && ![self.lastModified isEqualToDate:updatedLastModified];
                if( eTagModified || lastModifiedModified ) { // In case server didn't honor etag/last modified
                    ISSLogDebug(@"Remote resource modified - executing get request");
                    [self performGetRequest:request completionHandler:completionHandler];
                } else {
                    ISSLogTrace(@"Remote resource NOT modified - %@/%@, %@/%@", self.eTag, updatedETag, self.lastModified, updatedLastModified);
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
    [task resume];
}

- (void) performGetRequest:(NSMutableURLRequest*)request completionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler {
    [request setHTTPMethod:@"GET"];

    NSURLSessionTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:request
       completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
           BOOL signalErrorOccurred = NO;
           if ( error == nil ) {
               NSHTTPURLResponse* httpURLResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse*)response : nil;
               if( 200 == httpURLResponse.statusCode ) {
                   ISSLogDebug(@"Remote resource downloaded - parsing response data");
                   self.eTag = httpURLResponse.allHeaderFields[@"ETag"];
                   self.lastModified = [self parseLastModifiedFromResponse:httpURLResponse];

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
    [task resume];
}

@end
