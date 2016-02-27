//
//  ISSRemoteFont.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSRemoteFont.h"
#import "ISSDownloadableResource.h"

@implementation ISSRemoteFont

- (instancetype) initWithRemoteFont:(ISSDownloadableResource*)remoteFont fontSize:(CGFloat)fontSize {
    if ( self = [super init] ) {
        _remoteFont = remoteFont;
        _fontSize = fontSize;

        [_remoteFont addValueUpdateObserver:self selector:@selector(remoteFontUpdated:)];
    }
    return self;
}

+ (instancetype) remoteFontWithResource:(ISSDownloadableResource*)remoteFont fontSize:(CGFloat)fontSize {
    return [[self alloc] initWithRemoteFont:remoteFont fontSize:fontSize];
}

+ (instancetype) remoteFontWithURL:(NSURL*)url fontSize:(CGFloat)fontSize {
    return [self remoteFontWithResource:[ISSDownloadableResource downloadableFontWithURL:url] fontSize:fontSize];
}

- (void) dealloc {
    [_remoteFont removeValueUpdateObserver:self];
}


#pragma mark - Notifications

- (void) remoteFontUpdated:(NSNotification*)notification {
    [self valueUpdated];
}


#pragma mark - ISSUpdatableValue

- (void) requestUpdate {
    [self.remoteFont requestUpdate];
}

- (id) lastValue {
    if( self.remoteFont.cachedResource ) return [UIFont fontWithName:self.remoteFont.cachedResource size:self.fontSize];
    else return nil;
}


#pragma mark - NSObject overrides

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if( [object isKindOfClass:ISSRemoteFont.class] ) {
        return [self.remoteFont isEqual:((ISSRemoteFont*)object).remoteFont] && self.fontSize == ((ISSRemoteFont*)object).fontSize;
    }
    return NO;
}

- (NSUInteger) hash {
    return 31 * self.remoteFont.hash + (NSUInteger)self.fontSize;
}

- (NSString*) description {
    if( self.remoteFont.cachedResource ) return [NSString stringWithFormat:@"%@[%@, %@]", NSStringFromClass(self.class), self.remoteFont.resourceURL.lastPathComponent, self.lastValue];
    else return [NSString stringWithFormat:@"%@[%@, size: %f]", NSStringFromClass(self.class), self.remoteFont.resourceURL.lastPathComponent, self.fontSize];
}

@end
