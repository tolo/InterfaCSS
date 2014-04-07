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


@implementation ISSRefreshableResource {
    NSDate* _lastModified;
    NSString* _eTag;
}

- (NSDate*) parseLastModifiedFromResponse:(NSHTTPURLResponse*)response {
    NSDate* updatedLastModified = [response.allHeaderFields[@"Last-Modified"] iss_parseHttpDate];
    if( !updatedLastModified ) updatedLastModified = [response.allHeaderFields[@"Date"] iss_parseHttpDate];
    return updatedLastModified;
}

- (void) performHeadRequest:(NSMutableURLRequest*)request completionHandler:(void (^)(NSString*))completionHandler {
    [request setHTTPMethod:@"HEAD"];

    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
        if ( error == nil ) {
            NSHTTPURLResponse* httpURLResponse = [response isKindOfClass:NSHTTPURLResponse.class] ? (NSHTTPURLResponse*)response : nil;
            if( 200 == httpURLResponse.statusCode ) {
                NSString* updatedETag = httpURLResponse.allHeaderFields[@"ETag"];
                BOOL eTagModified = _eTag ? ![updatedETag isEqualToString:updatedETag] : NO;
                NSDate* updatedLastModified = [self parseLastModifiedFromResponse:httpURLResponse];
                BOOL lastModifiedModified = _lastModified ? ![_lastModified isEqualToDate:updatedLastModified] : NO;
                if( eTagModified || lastModifiedModified ) { // In case server didn't honor etag/last modified
                    ISSLogDebug(@"Remote stylesheet modified - executing get request");
                    [self performGetRequest:request completionHandler:completionHandler];
                } else {
                    ISSLogTrace(@"Remote stylesheet NOT modified - %@/%@, %@/%@", _eTag, updatedETag, _lastModified, updatedLastModified);
                }
            } else if( 304 == httpURLResponse.statusCode ) {
                ISSLogTrace(@"Remote stylesheet not modified");
            } else {
                ISSLogDebug(@"Unable to verify if remote stylesheet is modified - got HTTP response code %d", httpURLResponse.statusCode);
            }
        } else {
            ISSLogDebug(@"Error verifying if remote stylesheet is modified - %@", error);
        }
    }];
}

- (void) performGetRequest:(NSMutableURLRequest*)request completionHandler:(void (^)(NSString*))completionHandler {
    [request setHTTPMethod:@"GET"];

    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init]
       completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
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
                   ISSLogDebug(@"Unable to download remote stylesheet - got HTTP response code %d", httpURLResponse.statusCode);
               }
           } else {
               ISSLogDebug(@"Error downloading stylesheet - %@", error);
           }
       }];
}

- (void) refresh:(NSURL*)url completionHandler:(void (^)(NSString*))completionHandler {
    if( url.isFileURL ) {
        NSFileManager* fm = [NSFileManager defaultManager];
        NSDictionary* attrs = [fm attributesOfItemAtPath:url.path error:nil];
        NSDate* date;
        if (attrs != nil) {
            date = (NSDate*)attrs[NSFileModificationDate];
            if( !date ) date = (NSDate*)attrs[NSFileCreationDate];
        }
        if( !_lastModified || ![_lastModified isEqualToDate:date] ) {
            completionHandler([[NSString alloc] initWithContentsOfFile:url.path usedEncoding:nil error:nil]);
            _lastModified = date;
        }
    } else {
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
        if( _lastModified ) [request setValue:[ISSDateUtils formatHttpDate:_lastModified] forHTTPHeaderField:@"If-Modified-Since"];
        if( _eTag ) [request setValue:_eTag forHTTPHeaderField:@"If-None-Match"];

        if( _lastModified || _eTag ) [self performHeadRequest:request completionHandler:completionHandler];
        else [self performGetRequest:request completionHandler:completionHandler];
    }
}

@end