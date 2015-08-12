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


@implementation ISSStyleSheet {
    NSArray* _declarations;
}

- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(NSArray*)declarations {
    return [self initWithStyleSheetURL:styleSheetURL declarations:declarations refreshable:NO];
}

- (id) initWithStyleSheetURL:(NSURL*)styleSheetURL declarations:(NSArray*)declarations refreshable:(BOOL)refreshable {
   if ( (self = [super init]) ) {
       _styleSheetURL = styleSheetURL;
       _declarations = declarations;
       _refreshable = refreshable;
       _active = YES;
   }
   return self;
}

- (NSArray*) stylesForElement:(ISSUIElementDetails*)elementDetails {
    NSMutableArray* styles = [[NSMutableArray alloc] init];

    ISSLogTrace(@"Getting styles for %@:", elementDetails.uiElement);

    for(ISSPropertyDeclarations* declarations in _declarations) {
        if ( [declarations matchesElement:elementDetails ignoringPseudoClasses:NO] ) {
            ISSLogTrace(@"Matching declarations: %@", declarations);
            [styles iss_addAndReplaceUniqueObjectsInArray:declarations.properties];
        }
    }

    return styles;
}

- (NSArray*) declarationsMatchingElement:(ISSUIElementDetails*)elementDetails ignoringPseudoClasses:(BOOL)ignorePseudoClasses {
    ISSLogTrace(@"Getting matching declarations for %@:", elementDetails.uiElement);

    NSMutableArray* matchingDeclarations = [[NSMutableArray alloc] init];
    for(ISSPropertyDeclarations* declarations in _declarations) {
        ISSPropertyDeclarations* matchingDeclarationBlock = [declarations propertyDeclarationsMatchingElement:elementDetails ignoringPseudoClasses:ignorePseudoClasses];
        if( matchingDeclarationBlock ) {
            ISSLogTrace(@"Matching declarations: %@", matchingDeclarationBlock);
            [matchingDeclarations addObject:matchingDeclarationBlock];
        }
    }
    return matchingDeclarations;
}


#pragma mark - Refreshable stylesheet methods

- (void) refresh:(void (^)(void))completionHandler parse:(id<ISSStyleSheetParser>)styleSheetParser {
    [super refresh:self.styleSheetURL completionHandler:^(NSString* responseString) {
        NSMutableArray* declarations = [styleSheetParser parse:responseString];
        if( declarations ) {
            _declarations = declarations;
            completionHandler();
        } else {
            ISSLogDebug(@"Remote stylesheet didn't contain any declarations!");
        }
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
