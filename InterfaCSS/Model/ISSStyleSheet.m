//
//  ISSStyleSheet.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSStyleSheet.h"

#import "ISSPropertyDeclarations.h"
#import "ISSStyleSheetParser.h"
#import "NSObject+ISSLogSupport.h"
#import "ISSUIElementDetails.h"
#import "NSMutableArray+ISSAdditions.h"
#import "InterfaCSS.h"
#import "ISSStylingContext.h"


NSString* const ISSStyleSheetRefreshedNotification = @"ISSStyleSheetRefreshedNotification";
NSString* const ISSStyleSheetRefreshFailedNotification = @"ISSStyleSheetRefreshFailedNotification";


@implementation ISSStyleSheetScope {
    ISSStyleSheetScopeMatcher _matcher;
}

+ (ISSStyleSheetScope*) scopeWithElementId:(NSString*)elementId {
    return [[self alloc] initWithMatcher:^(ISSUIElementDetails* elementDetails) {
        if( [elementDetails.elementId isEqualToString:elementId] ) return YES;
        else {
            return (BOOL)([[InterfaCSS sharedInstance] superviewWithElementId:elementId inView:elementDetails.uiElement] != nil);
        }
    }];
}

+ (ISSStyleSheetScope*) scopeWithViewControllerClass:(Class)viewControllerClass {
    return [self scopeWithViewControllerClass:viewControllerClass includeChildViewControllers:NO];
}

+ (ISSStyleSheetScope*) scopeWithViewControllerClass:(Class)viewControllerClass includeChildViewControllers:(BOOL)includeChildViewControllers {
    return [[self alloc] initWithMatcher:^(ISSUIElementDetails* elementDetails) {
        UIViewController* parent = elementDetails.closestViewController;
        while(parent != nil) {
            if( [parent isKindOfClass:viewControllerClass] ) return YES;
            else if( !includeChildViewControllers ) return NO;
            parent = parent.parentViewController;
        }
        return NO;
    }];
}

+ (ISSStyleSheetScope*) scopeWithViewControllerClasses:(NSArray*)viewControllerClasses {
    return [self scopeWithViewControllerClasses:viewControllerClasses includeChildViewControllers:NO];
}

+ (ISSStyleSheetScope*) scopeWithViewControllerClasses:(NSArray*)viewControllerClasses includeChildViewControllers:(BOOL)includeChildViewControllers {
    return [[self alloc] initWithMatcher:^(ISSUIElementDetails* elementDetails) {
        UIViewController* parent = elementDetails.closestViewController;
        while(parent != nil) {
            for(Class clazz in viewControllerClasses) {
                if( [parent isKindOfClass:clazz] ) return YES;
            }
            if( !includeChildViewControllers ) return NO;
            parent = parent.parentViewController;
        }
        return NO;
    }];
}

+ (ISSStyleSheetScope*) scopeWithMatcher:(ISSStyleSheetScopeMatcher)matcher {
    return [[self alloc] initWithMatcher:matcher ];
}

- (instancetype) initWithMatcher:(ISSStyleSheetScopeMatcher)matcher {
    if( self = [super init] ) {
        _matcher = matcher;
    }
    return self;
}

- (BOOL) elementInScope:(ISSUIElementDetails*)elementDetails {
    return _matcher(elementDetails);
}

@end


@interface ISSStyleSheet ()

@property (nonatomic, readwrite, nullable) NSArray* declarations;

@end


@implementation ISSStyleSheet


#pragma mark - Lifecycle

- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(NSArray*)declarations {
    return [self initWithStyleSheetURL:styleSheetURL declarations:declarations refreshable:NO];
}

- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(NSArray*)declarations refreshable:(BOOL)refreshable {
        return [self initWithStyleSheetURL:styleSheetURL declarations:declarations refreshable:refreshable scope:nil];
}

- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(NSArray*)declarations refreshable:(BOOL)refreshable scope:(ISSStyleSheetScope*)scope {
   if ( (self = [super initWithURL:styleSheetURL]) ) {
       _declarations = declarations;
       _refreshable = refreshable;
       _active = YES;
       _scope = scope;
   }
   return self;
}


#pragma mark - Properties

- (NSURL*) styleSheetURL {
    return self.resourceURL;
}


#pragma mark - Matching

- (NSArray*) declarationsMatchingElement:(ISSUIElementDetails*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    ISSLogTrace(@"Getting matching declarations for %@:", elementDetails.uiElement);

    NSMutableArray* matchingDeclarations = [[NSMutableArray alloc] init];

    if( self.scope && ![self.scope elementInScope:elementDetails] ) {
        ISSLogTrace(@"Element not in scope - skipping: %@", elementDetails.uiElement);
    } else {
        for (ISSPropertyDeclarations* declarations in _declarations) {
            ISSPropertyDeclarations* matchingDeclarationBlock = [declarations propertyDeclarationsMatchingElement:elementDetails stylingContext:stylingContext];
            if ( matchingDeclarationBlock ) {
                ISSLogTrace(@"Matching declarations: %@", matchingDeclarationBlock);
                [matchingDeclarations addObject:matchingDeclarationBlock];
            }
        }
    }
    return matchingDeclarations;
}

- (ISSPropertyDeclarations*) findPropertyDeclarationsWithSelectorChain:(ISSSelectorChain*)selectorChain {
    for (ISSPropertyDeclarations* declarations in _declarations) {
        if ( [declarations containsSelectorChain:selectorChain] ) {
            return declarations;
        }
    }
    return nil;
}


#pragma mark - Refreshable stylesheet methods

- (void) refreshStylesheetWithCompletionHandler:(void (^)(void))completionHandler force:(BOOL)force {
    [super refreshWithCompletionHandler:^(BOOL success, NSString* responseString, NSError* error) {
        if( success ) {
            NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
            NSMutableArray* declarations = [[InterfaCSS sharedInstance].parser parse:responseString];
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
    } force:force];
}

- (void) refreshWithCompletionHandler:(ISSRefreshableResourceLoadCompletionBlock)completionHandler force:(BOOL)force {
    [self refreshStylesheetWithCompletionHandler:^{
        completionHandler(YES, nil, nil);
    } force:force];
}


#pragma mark - Description

- (NSString*) displayDescription {
    NSMutableString* str = [NSMutableString string];
    for(ISSPropertyDeclarations* declarations in _declarations) {
        NSString* descr = declarations.displayDescription;
        descr = [descr stringByReplacingOccurrencesOfString:@"\n" withString:@"\n\t"];
        if( str.length == 0 ) [str appendFormat:@"\n\t%@", descr];
        else [str appendFormat:@", \n\t%@", descr];
    }
    if( str.length > 0 ) [str appendString:@"\n"];
    return [NSString stringWithFormat:@"ISSStyleSheet[%@ - %@]", self.styleSheetURL.lastPathComponent, str];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSStyleSheet[%@, %ld decls]", self.styleSheetURL.lastPathComponent, (long)self.declarations.count];
}

@end
