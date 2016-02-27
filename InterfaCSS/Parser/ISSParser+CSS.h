//
//  ISSParser+CSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSParser.h"

@interface ISSParser (CSS)

+ (ISSParser*) iss_anythingButBasicControlChars:(NSUInteger)minCount;

+ (ISSParser*) iss_anythingButBasicControlCharsExceptColon:(NSUInteger)minCount;

+ (ISSParser*) iss_anythingButWhiteSpaceAndExtendedControlChars:(NSUInteger)minCount;

+ (NSCharacterSet*) iss_validIdentifierCharsSet;

+ (ISSParser*) iss_validIdentifierChars:(NSUInteger)minCount;

+ (ISSParser*) iss_validIdentifierChars:(NSUInteger)minCount onlyAlphpaAndUnderscore:(BOOL)onlyAlphpaAndUnderscore;

+ (ISSParser*) iss_logicalExpressionParser;

+ (ISSParser*) iss_mathExpressionParser;

+ (id) iss_parseMathExpression:(NSString*)value;

+ (ISSParser*) iss_parameterStringWithPrefixes:(NSArray*)prefixes;

+ (ISSParser*) iss_parameterStringWithPrefix:(NSString*)prefix;

+ (ISSParser*) iss_parameterString;

+ (ISSParser*) iss_twoParameterFunctionParserWithName:(NSString*)name leftParameterParser:(ISSParser*)left rightParameterParser:(ISSParser*)right;

+ (ISSParser*) iss_singleParameterFunctionParserWithName:(NSString*)name parameterParser:(ISSParser*)parameterParser;

+ (ISSParser*) iss_singleParameterFunctionParserWithNames:(NSArray*)names parameterParser:(ISSParser*)parameterParser;

+ (ISSParser*) iss_parseLineUpToInvalidCharactersInString:(NSString*)invalid;

+ (ISSParser*) iss_commentParser;

+ (ISSParser*) iss_propertyPairParser:(BOOL)forVariableDefinition;

@end
