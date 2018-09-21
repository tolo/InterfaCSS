//
//  ISSStyleSheetParserSyntax.m
//  InterfaCSS-Core
//
//  Created by Tobias Löfstrand on 2018-09-18.
//  Copyright © 2018 Leafnode AB. All rights reserved.
//

#import "ISSStyleSheetParserSyntax.h"

#import "ISSParser.h"


static ISSStyleSheetParserSyntax* sharedStyleSheetParserSyntax = nil;


@implementation ISSStyleSheetParserSyntax

+ (ISSStyleSheetParserSyntax*) shared {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedStyleSheetParserSyntax = [[ISSStyleSheetParserSyntax alloc] init];
    });

    return sharedStyleSheetParserSyntax;
}

- (instancetype) init {
    if ( (self = [super init]) ) {
        NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"_"];
        [characterSet formUnionWithCharacterSet:[NSCharacterSet letterCharacterSet]];
        _validInitialIdentifierCharacterCharsSet = [characterSet copy];

        characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"_"];
        [characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        _validIdentifierExcludingMinusCharsSet = [characterSet copy];

        characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"-_"];
        [characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        _validIdentifierCharsSet = [characterSet copy];

        characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"+-*/%^=≠<>≤≥|&!()."];
        [characterSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
        [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
        _mathExpressionCharsSet = [characterSet copy];
    }
    return self;
}

@end
