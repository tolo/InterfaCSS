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
#import "NSString+ISSStringAdditions.h"
#import "ISSDateUtils.h"
#import "NSObject+ISSLogSupport.h"


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

- (NSDictionary*) stylesForView:(UIView*)view {
    NSMutableDictionary* styles = [NSMutableDictionary dictionary];

    for(ISSPropertyDeclarations* declarations in _declarations) {
        if ( [declarations matchesView:view] ) {
            [styles addEntriesFromDictionary:declarations.properties];
        }
    }

    return styles;
}


#pragma mark - Refreshable stylesheet methods

- (void) refresh:(void (^)(void))completionHandler parse:(ISSStyleSheetParser*)styleSheetParser {
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
    return [NSString stringWithFormat:@"ISSStyleSheet[%@ - %@]", self.styleSheetURL, str];
}

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSStyleSheet[%@, %d]", self.styleSheetURL, self.declarations.count];
}

@end
