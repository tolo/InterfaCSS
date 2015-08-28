//
//  ISSSelectorChain.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-03-10.
//  Copyright (c) 2012 Leafnode AB.
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


@implementation ISSStyleSheet {
    NSArray* _declarations;
}


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


#pragma mark - Refreshable stylesheet methods

- (void) refreshStylesheetWithCompletionHandler:(void (^)(void))completionHandler {
    [super refreshWithCompletionHandler:^(NSString* responseString) {
        NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];
        NSMutableArray* declarations = [[InterfaCSS sharedInstance].parser parse:responseString];
        if( declarations ) {
            if( _declarations ) ISSLogDebug(@"Reloaded stylesheet '%@' in %f seconds", [self.styleSheetURL lastPathComponent], ([NSDate timeIntervalSinceReferenceDate] - t));
            else ISSLogDebug(@"Loaded stylesheet '%@' in %f seconds", [self.styleSheetURL lastPathComponent], ([NSDate timeIntervalSinceReferenceDate] - t));
            
            _declarations = declarations;
            completionHandler();
        } else {
            ISSLogDebug(@"Remote stylesheet didn't contain any declarations!");
        }
    }];
}

- (void) refreshWithCompletionHandler:(void (^)(NSString*))completionHandler {
    [self refreshStylesheetWithCompletionHandler:^{
        completionHandler(nil);
    }];
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
