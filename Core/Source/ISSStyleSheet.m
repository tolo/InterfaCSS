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


@interface ISSStyleSheet ()

@property (nonatomic, readwrite, nullable) NSArray* declarations;

@end


@implementation ISSStyleSheet {
    NSArray* _declarations;
}


#pragma mark - Lifecycle

- (instancetype) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(nullable NSArray*)declarations refreshable:(BOOL)refreshable {
    return [self initWithStyleSheetURL:styleSheetURL name:nil group:nil declarations:declarations refreshable:refreshable];
}

- (instancetype) initWithStyleSheetURL:(NSURL*)styleSheetURL name:(NSString*)name group:(NSString*)groupName declarations:(nullable NSArray*)declarations refreshable:(BOOL)refreshable {
    if ( (self = [super initWithURL:styleSheetURL]) ) {
        _declarations = declarations;
        _refreshable = refreshable;
        _active = YES;
        _name = name ?: [styleSheetURL lastPathComponent];
        _group = groupName;
    }
    return self;
}


#pragma mark - Properties

- (NSURL*) styleSheetURL {
    return self.resourceURL;
}


#pragma mark - Matching

- (NSArray<ISSRuleset*>*) rulesetsMatchingElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    if ( stylingContext.styleSheetScope && ![stylingContext.styleSheetScope containsStyleSheet:self] ) {
        ISSLogTrace(@"Stylesheet not in scope - skipping for element: %@", elementDetails.uiElement);
        return nil;
    }
    
    ISSLogTrace(@"Getting matching declarations for %@:", elementDetails.uiElement);

    NSMutableArray* matchingDeclarations = [[NSMutableArray alloc] init];
    
    for (ISSRuleset* ruleset in self.rulesets) {
        ISSRuleset* matchingDeclarationBlock = [ruleset propertyDeclarationsMatchingElement:elementDetails stylingContext:stylingContext];
        if ( matchingDeclarationBlock ) {
            ISSLogTrace(@"Matching declarations: %@", matchingDeclarationBlock);
            [matchingDeclarations addObject:matchingDeclarationBlock];
        }
    }

    return matchingDeclarations;
}

- (ISSRuleset*) findPropertyDeclarationsWithSelectorChain:(ISSSelectorChain*)selectorChain {
    for (ISSRuleset* declarations in _declarations) {
        if ( [declarations containsSelectorChain:selectorChain] ) {
            return declarations;
        }
    }
    return nil;
}


#pragma mark - Refreshable stylesheet methods

- (void) refreshStylesheetWith:(ISSStyleSheetManager*)styleSheetManager andCompletionHandler:(void (^)(void))completionHandler force:(BOOL)force {
    [super refreshWithCompletionHandler:^(BOOL success, NSString* responseString, NSError* error) {
        if( success ) {
            NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
            NSMutableArray* declarations = [styleSheetManager.styleSheetParser parse:responseString];
            if( declarations ) {
                BOOL hasDeclarations = self.declarations != nil;
                self.declarations = declarations;

                if( hasDeclarations ) ISSLogDebug(@"Reloaded stylesheet '%@' in %f seconds", [self.styleSheetURL lastPathComponent], ([NSDate timeIntervalSinceReferenceDate] - t));
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


#pragma mark - Description

- (NSString*) displayDescription {
    NSMutableString* str = [NSMutableString string];
    for(ISSRuleset* declarations in _declarations) {
        NSString* descr = declarations.displayDescription;
        descr = [descr stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
        if( str.length == 0 ) [str appendFormat:@"\n\t%@", descr];
        else [str appendFormat:@", \n\t%@", descr];
    }
    if( str.length > 0 ) [str appendString:@"\n"];
    return [NSString stringWithFormat:@"ISSStyleSheet[%@ - %@]", self.styleSheetURL.lastPathComponent, str];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSStyleSheet[%@, %ld decls]", self.styleSheetURL.lastPathComponent, (long)self.rulesets.count];
}

@end
