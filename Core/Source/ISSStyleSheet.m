//
//  ISSStyleSheet.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSStyleSheet.h"

#import "ISSStyleSheetManager.h"
#import "ISSStyleSheetParser.h"

#import "ISSRuleset.h"
#import "ISSStylingContext.h"
#import "ISSElementStylingProxy.h"
#import "ISSRefreshableResource.h"

#import "NSObject+ISSLogSupport.h"
#import "NSArray+ISSAdditions.h"


NSString* const ISSStyleSheetRefreshedNotification = @"ISSStyleSheetRefreshedNotification";
NSString* const ISSStyleSheetRefreshFailedNotification = @"ISSStyleSheetRefreshFailedNotification";


@interface ISSStyleSheetScope ()

@property (nonatomic, copy) ISSStyleSheetMatcher matcher;

@end

@implementation ISSStyleSheetScope

+ (ISSStyleSheetScope*) scopeWithStyleSheetNames:(NSArray*)names {
    NSSet* nameSet = [NSSet setWithArray:names];
    return [[self alloc] initWithMatcher:^BOOL(ISSStyleSheet* styleSheet) {
        return [nameSet containsObject:styleSheet.name];
    }];
}

+ (ISSStyleSheetScope*) scopeWithStyleSheetGroups:(NSArray*)groups {
    NSSet* groupsSet = [NSSet setWithArray:groups];
    return [[self alloc] initWithMatcher:^BOOL(ISSStyleSheet* styleSheet) {
        return [groupsSet containsObject:styleSheet.group];
    }];
}

- (instancetype) initWithMatcher:(ISSStyleSheetMatcher)matcher {
    if( self = [super init] ) {
        _matcher = matcher;
    }
    return self;
}

- (BOOL) containsStyleSheet:(ISSStyleSheet*)styleSheet {
    return self.matcher(styleSheet);
}

@end


#pragma mark - ISSStyleSheet

@interface ISSStyleSheet ()

@property (nonatomic, strong, readwrite, nullable) ISSStyleSheetContent* content;

@end


@implementation ISSStyleSheet

#pragma mark - Lifecycle

- (instancetype) init {
    @throw([NSException exceptionWithName:NSInternalInconsistencyException reason:@"Hold on there professor, init not allowed!" userInfo:nil]);
}

- (instancetype) initWithStyleSheetURL:(NSURL*)styleSheetURL content:(ISSStyleSheetContent*)content {
    return [self initWithStyleSheetURL:styleSheetURL name:nil group:nil content:content];
}

- (instancetype) initWithStyleSheetURL:(NSURL*)styleSheetURL name:(NSString*)name group:(NSString*)groupName content:(ISSStyleSheetContent*)content {
    //if ( (self = [super initWithURL:styleSheetURL]) ) {
    if ( self = [super init] ) {
        _styleSheetURL = styleSheetURL;
        _content = content;
        _active = YES;
        _name = name ?: [styleSheetURL lastPathComponent];
        _group = groupName;
    }
    return self;
}

- (void) unload {}


#pragma mark - Properties

- (BOOL) refreshable {
    return NO;
}


#pragma mark - Matching

- (ISSRulesets*) rulesetsMatchingElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    if ( stylingContext.styleSheetScope && ![stylingContext.styleSheetScope containsStyleSheet:self] ) {
        ISSLogTrace(@"Stylesheet not in scope - skipping for element: %@", elementDetails.uiElement);
        return nil;
    }
    
    ISSLogTrace(@"Getting matching declarations for %@:", elementDetails.uiElement);

    NSMutableArray* matchingDeclarations = [[NSMutableArray alloc] init];
    
    for (ISSRuleset* ruleset in self.content.rulesets) {
        ISSRuleset* matchingDeclarationBlock = [ruleset propertyDeclarationsMatchingElement:elementDetails stylingContext:stylingContext];
        if ( matchingDeclarationBlock ) {
            ISSLogTrace(@"Matching declarations: %@", matchingDeclarationBlock);
            [matchingDeclarations addObject:matchingDeclarationBlock];
        }
    }

    return matchingDeclarations;
}

- (ISSRuleset*) findPropertyDeclarationsWithSelectorChain:(ISSSelectorChain*)selectorChain {
    for (ISSRuleset* ruleset in self.content.rulesets) {
        if ( [ruleset containsSelectorChain:selectorChain] ) {
            return ruleset;
        }
    }
    return nil;
}


#pragma mark - Description

- (NSString*) displayDescription {
    NSMutableString* str = [NSMutableString string];
    for(ISSRuleset* ruleset in self.content.rulesets) {
        NSString* descr = ruleset.displayDescription;
        descr = [descr stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
        if( str.length == 0 ) [str appendFormat:@"\n\t%@", descr];
        else [str appendFormat:@", \n\t%@", descr];
    }
    if( str.length > 0 ) [str appendString:@"\n"];
    return [NSString stringWithFormat:@"ISSStyleSheet[%@ - %@]", self.styleSheetURL.lastPathComponent, str];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSStyleSheet[%@, %ld decls]", self.styleSheetURL.lastPathComponent, (long)self.content.rulesets.count];
}

@end


#pragma mark - ISSRefreshableStyleSheet

@implementation ISSRefreshableStyleSheet

- (instancetype) initWithStyleSheetURL:(NSURL*)styleSheetURL name:(NSString*)name group:(NSString*)groupName content:(nullable ISSStyleSheetContent*)content {
    if ( self = [super initWithStyleSheetURL:styleSheetURL name:name group:groupName content:content] ) {
        if( styleSheetURL.isFileURL ) {
            _refreshableResource = [[ISSRefreshableLocalResource alloc] initWithURL:styleSheetURL];
        } else {
            _refreshableResource = [[ISSRefreshableRemoteResource alloc] initWithURL:styleSheetURL];
        }
    }
    return self;
}


#pragma mark - Properties

- (BOOL) refreshable {
    return YES;
}

- (BOOL) styleSheetModificationMonitoringSupported {
    return self.refreshableResource.resourceModificationMonitoringSupported;
}

- (BOOL) styleSheetModificationMonitoringEnabled {
    return self.refreshableResource.resourceModificationMonitoringEnabled;
}

//- (ISSRulesets*) rulesets {
//    return self.content.rulesets;
//}


#pragma mark - ISSStyleSheet overrides

- (void) unload {
    [self.refreshableResource endMonitoringResourceModification];
}


#pragma mark - Refreshable stylesheet methods

- (void) startMonitoringStyleSheetModification:(ISSRefreshableStyleSheetObserverBlock)modificationObserver {
    __weak ISSRefreshableStyleSheet* weakSelf = self;
    [self.refreshableResource startMonitoringResourceModification:^(ISSRefreshableResource* _Nonnull refreshableResource) {
        modificationObserver(weakSelf);
    }];
}

- (void) refreshStylesheetWith:(ISSStyleSheetManager*)styleSheetManager andCompletionHandler:(void (^)(void))completionHandler force:(BOOL)force {
    [self.refreshableResource refreshWithCompletionHandler:^(BOOL success, NSString* responseString, NSError* error) {
        if( success ) {
            NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
            ISSStyleSheetContent* styleSheetContent = [styleSheetManager.styleSheetParser parse:responseString];
            if( styleSheetContent ) {
                BOOL hasRulesets = self.content != nil;
                self.content = styleSheetContent;

                if( hasRulesets ) ISSLogDebug(@"Reloaded stylesheet '%@' in %f seconds", [self.styleSheetURL lastPathComponent], ([NSDate timeIntervalSinceReferenceDate] - t));
                else ISSLogDebug(@"Loaded stylesheet '%@' in %f seconds", [self.styleSheetURL lastPathComponent], ([NSDate timeIntervalSinceReferenceDate] - t));

                completionHandler();
            } else {
                ISSLogDebug(@"Remote stylesheet didn't contain any declarations!");
            }

            [[NSNotificationCenter defaultCenter] postNotificationName:ISSStyleSheetRefreshedNotification object:self];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:ISSStyleSheetRefreshFailedNotification object:self];
        }
    } refreshIntervalDuringError:styleSheetManager.stylesheetAutoRefreshInterval * 3 force:force];
}


@end

