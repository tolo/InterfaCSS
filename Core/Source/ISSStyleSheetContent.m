//
//  ISSStyleSheetContent.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSStyleSheetContent.h"

#import "NSDictionary+ISSAdditions.h"

@implementation ISSStyleSheetContent

- (instancetype) initWithRulesets:(ISSRulesets*)rulesets variables:(ISSVariables*)variables {
    if ( self = [super init] ) {
        _rulesets = rulesets;
        _variables = variables;
    }
    return self;
}

- (void) setValue:(NSString*)value forStyleSheetVariableWithName:(NSString*)variableName {
    _variables = [_variables iss_dictionaryByAddingValue:value forKey:variableName];
}

@end
