//
//  Parcoa+ISSAdditions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2013-06-14.
//  Copyright (c) 2013 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Parcoa/Parcoa.h>

typedef NSUInteger (^MatcherBlock)(NSString* input);

@interface Parcoa (ISSAdditions)

+ (ParcoaParser*) iss_quickUnichar:(unichar)c skipSpace:(BOOL)skipSpace;

+ (ParcoaParser*) iss_anythingButUnichar:(unichar)c escapesEnabled:(BOOL)escapes;

+ (ParcoaParser*) iss_quickUnichar:(unichar)c;

+ (ParcoaParser*) iss_stringIgnoringCase:(NSString*)string;

+ (ParcoaParser*) iss_takeUntil:(MatcherBlock)block minCount:(NSUInteger)minCount;

+ (ParcoaParser*) iss_takeUntilInSet:(NSCharacterSet*)characterSet minCount:(NSUInteger)minCount;

+ (ParcoaParser*) iss_takeUntilChar:(unichar)character;

+ (ParcoaParser*) iss_anythingButBasicControlChars:(NSUInteger)minCount;

+ (ParcoaParser*) iss_anythingButBasicControlCharsExceptColon:(NSUInteger)minCount;

+ (ParcoaParser*) iss_anythingButWhiteSpaceAndExtendedControlChars:(NSUInteger)minCount;

+ (NSCharacterSet*) iss_validIdentifierCharsSet;

+ (ParcoaParser*) iss_validIdentifierChars:(NSUInteger)minCount;

+ (ParcoaParser*) iss_validIdentifierChars:(NSUInteger)minCount onlyAlphpaAndUnderscore:(BOOL)onlyAlphpaAndUnderscore;

+ (ParcoaParser*) iss_logicalExpressionParser;

+ (ParcoaParser*) iss_mathExpressionParser;

+ (id) iss_parseMathExpression:(NSString*)value;

+ (ParcoaParser*) iss_safeDictionary:(ParcoaParser*)parser;

+ (ParcoaParser*) iss_safeArray:(ParcoaParser*)parser;

+ (ParcoaParser*) iss_parameterStringWithPrefixes:(NSArray*)prefixes;

+ (ParcoaParser*) iss_parameterStringWithPrefix:(NSString*)prefix;

+ (ParcoaParser*) iss_parameterString;

+ (ParcoaParser*) iss_twoParameterFunctionParserWithName:(NSString*)name leftParameterParser:(ParcoaParser*)left rightParameterParser:(ParcoaParser*)right;

+ (ParcoaParser*) iss_singleParameterFunctionParserWithName:(NSString*)name parameterParser:(ParcoaParser*)parameterParser;

+ (ParcoaParser*) iss_singleParameterFunctionParserWithNames:(NSArray*)names parameterParser:(ParcoaParser*)parameterParser;

+ (ParcoaParser*) iss_nameValueSeparator;

+ (ParcoaParser*) iss_parseLineUpToInvalidCharactersInString:(NSString*)invalid;

+ (ParcoaParser*) iss_commentParser;

@end
