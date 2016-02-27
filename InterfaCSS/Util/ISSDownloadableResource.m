//
//  ISSDownloadableResource.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSDownloadableResource.h"

#import <CoreText/CoreText.h>

#import "NSObject+ISSLogSupport.h"


NSString* const ISSResourceDownloadedNotification = @"ISSResourceDownloadedNotification";
NSString* const ISSResourceDownloadFailedNotification = @"ISSResourceDownloadFailedNotification";


static NSMapTable* activeDownloadableResources;
static NSCache* downloadableResourceCache;


@interface ISSDownloadableResource()

@property (nonatomic) BOOL downloading;
@property (nonatomic, weak, readwrite) id cachedResource;

- (id) resourceWithData:(NSData*)data;

@end


@interface ISSDownloadableFontResource : ISSDownloadableResource

@property (nonatomic, strong) id loadedFont;

@end
@implementation ISSDownloadableFontResource

- (id) resourceWithData:(NSData*)data {
    if( self.loadedFont ) CTFontManagerUnregisterGraphicsFont((__bridge CGFontRef)self.loadedFont, nil);

    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    CGFontRef font = CGFontCreateWithDataProvider(provider);
    self.loadedFont = (__bridge id)font;
    NSString* fontName = nil;
    if ( font ) {
        CFErrorRef error;
        if ( CTFontManagerRegisterGraphicsFont(font, &error) ) {
            fontName = CFBridgingRelease(CGFontCopyPostScriptName(font));
            [self iss_logDebug:@"Loaded font: %@", fontName];
        }
        CFRelease(font);
    }
    CFRelease(provider);

    if ( fontName ) return fontName;
    else {
        [self iss_logWarning:@"Failed to create font from downloaded data!"];
        return [UIFont systemFontOfSize:1].fontName;
    }
}

@end


@interface ISSDownloadableImageResource : ISSDownloadableResource
@end
@implementation ISSDownloadableImageResource

- (id) resourceWithData:(NSData*)data {
    UIImage* image = [UIImage imageWithData:data];
    if( image ) return image;
    else {
        [self iss_logWarning:@"Failed to create image from downloaded data!"];
        return [[UIImage alloc] init];
    }
}

@end


@implementation ISSDownloadableResource

+ (void) load {
    downloadableResourceCache = [[NSCache alloc] init];
    activeDownloadableResources = [NSMapTable strongToWeakObjectsMapTable];
}

+ (void) clearCaches {
    [downloadableResourceCache removeAllObjects];
}

+ (instancetype) downloadableFontWithURL:(NSURL*)url {
    return [ISSDownloadableFontResource downloadableResourceWithURL:url];
}

+ (instancetype) downloadableImageWithURL:(NSURL*)url {
    return [ISSDownloadableImageResource downloadableResourceWithURL:url];
}

+ (instancetype) downloadableResourceWithURL:(NSURL*)url {
    ISSDownloadableResource* resource = [activeDownloadableResources objectForKey:url];
    if( resource ) return resource;
    else return [[self alloc] initWithURL:url];
}

- (instancetype) initWithURL:(NSURL*)url {
    if( self = [super init] ) {
        _resourceURL = url;
        [activeDownloadableResources setObject:self forKey:url];
    }
    return self;
}

- (id) cachedResource {
    return [downloadableResourceCache objectForKey:self.resourceURL];
}

- (void) setCachedResource:(id)cachedResource {
    if( cachedResource ) {
        [downloadableResourceCache setObject:cachedResource forKey:self.resourceURL];
    } else {
        [downloadableResourceCache removeObjectForKey:self.resourceURL];
    }
}

- (void) download:(BOOL)force {
    if( !force && (self.downloading || self.cachedResource) ) return;

    self.downloading = YES;
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:self.resourceURL];
    if( force ) {
        [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    }
    
    __weak ISSDownloadableResource* weakSelf = self;
    NSURLSession* urlSession = [NSURLSession sharedSession];
    NSURLSessionDataTask* dataDownloadTask = [urlSession dataTaskWithRequest:request completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.downloading = NO;
            __strong ISSDownloadableResource* self = weakSelf;
            if( error || !data ) {
                [self iss_logDebug:@"Error downloading resource - %@", error];
                [[NSNotificationCenter defaultCenter] postNotificationName:ISSResourceDownloadFailedNotification object:weakSelf];
            } else {
                [self iss_logDebug:@"Resource downloaded (%d bytes)", data.length];
                __strong id cachedResource = [self resourceWithData:data]; // Store in local strong ref, just to make sure cachedResource doesn't go away (since it's stored as weak ref in NSMapTable)
                self.cachedResource = cachedResource;
                [[NSNotificationCenter defaultCenter] postNotificationName:ISSResourceDownloadedNotification object:weakSelf];
                [self valueUpdated];
            }
        });
    }];
    [dataDownloadTask resume];
}

- (id) resourceWithData:(NSData*)data { return nil; }


#pragma mark - ISSUpdatableValue

- (void) requestUpdate {
    [self download:NO];
}

- (id) lastValue {
    return self.cachedResource;
}


#pragma mark - NSObject overrides

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if( [object isKindOfClass:ISSDownloadableResource.class] ) {
        return [self.resourceURL isEqual:((ISSDownloadableResource*)object).resourceURL];
    }
    return NO;
}

- (NSUInteger) hash {
    return self.resourceURL.hash;
}

- (NSString*) description {
    if( self.cachedResource ) return [NSString stringWithFormat:@"%@[%@, cachedResource: %@]", NSStringFromClass(self.class), self.resourceURL.lastPathComponent, self.cachedResource];
    else return [NSString stringWithFormat:@"%@[%@]", NSStringFromClass(self.class), self.resourceURL.lastPathComponent];
}

@end
