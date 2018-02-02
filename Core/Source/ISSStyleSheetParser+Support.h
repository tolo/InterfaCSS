//
//  ISSStyleSheetParser+Support.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

#import "ISSParser.h"


NS_ASSUME_NONNULL_BEGIN


@interface ISSStyleSheetParser (Support)

- (ISSParser*) anythingButBasicControlChars:(NSUInteger)minCount;

- (ISSParser*) anythingButBasicControlCharsExceptColon:(NSUInteger)minCount;

- (ISSParser*) anythingButWhiteSpaceAndExtendedControlChars:(NSUInteger)minCount;

- (ISSParser*) validIdentifierChars:(NSUInteger)minCount;

- (ISSParser*) validIdentifierChars:(NSUInteger)minCount onlyAlphpaAndUnderscore:(BOOL)onlyAlphpaAndUnderscore;

- (ISSParser*) logicalExpressionParser;

- (ISSParser*) mathExpressionParser;

- (id) parseMathExpression:(NSString*)value;

- (ISSParser*) parameterStringWithPrefixes:(NSArray*)prefixes;

- (ISSParser*) parameterStringWithPrefix:(nullable NSString*)prefix;

- (ISSParser*) parameterString;

- (ISSParser*) twoParameterFunctionParserWithName:(NSString*)name leftParameterParser:(ISSParser*)left rightParameterParser:(ISSParser*)right;

- (ISSParser*) singleParameterFunctionParserWithName:(NSString*)name parameterParser:(ISSParser*)parameterParser;

- (ISSParser*) singleParameterFunctionParserWithNames:(NSArray*)names parameterParser:(ISSParser*)parameterParser;

- (ISSParser*) parseLineUpToInvalidCharactersInString:(NSString*)invalid;

- (ISSParser*) commentParser;

- (ISSParser*) propertyPairParser:(BOOL)forVariableDefinition;

@end


NS_ASSUME_NONNULL_END
