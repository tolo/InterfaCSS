//
//  Parcoa+ISSAdditions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2013-06-14.
//  Copyright (c) 2013 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "Parcoa.h"

typedef NSUInteger (^MatcherBlock)(NSString* input);

@interface Parcoa (ISSAdditions)

+ (ParcoaParser*) quickUnichar:(unichar)c skipSpace:(BOOL)skipSpace;

+ (ParcoaParser*) quickUnichar:(unichar)c;

+ (ParcoaParser*) stringIgnoringCase:(NSString*)string;

+ (ParcoaParser*) takeUntil:(MatcherBlock)block minCount:(NSUInteger)minCount;

+ (ParcoaParser*) takeUntilInSet:(NSCharacterSet*)characterSet minCount:(NSUInteger)minCount;

+ (ParcoaParser*) takeUntilChar:(unichar)character;

+ (ParcoaParser*) anythingButBasicControlChars:(NSUInteger)minCount;

+ (ParcoaParser*) anythingButWhiteSpaceAndControlChars:(NSUInteger)minCount;

+ (NSCharacterSet*) validIdentifierCharsSet;

+ (ParcoaParser*) validIdentifierChars:(NSUInteger)minCount;

+ (ParcoaParser*) safeDictionary:(ParcoaParser*)parser;

+ (ParcoaResult*) partialParserForPrefix:(NSString*)prefix input:(NSString*)input startIndex:(NSUInteger)i;

+ (ParcoaParser*) parameterStringWithPrefixes:(NSArray*)prefixes;

+ (ParcoaParser*) parameterStringWithPrefix:(NSString*)prefix;

+ (ParcoaParser*) twoParameterFunctionParserWithName:(NSString*)name leftParameterParser:(ParcoaParser*)left rightParameterParser:(ParcoaParser*)right;

+ (ParcoaParser*) nameValueSeparator;

+ (ParcoaParser*) parseLineUpToInvalidCharactersInString:(NSString*)invalid;

+ (ParcoaParser*) commentParser;

@end
