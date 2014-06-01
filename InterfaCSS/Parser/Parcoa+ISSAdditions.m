//
//  Parcoa+ISSAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2013-06-14.
//  Copyright (c) 2013 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "Parcoa+ISSAdditions.h"

#define SKIP_SPACE_AND_NEWLINES while( i < input.length && [[self iss_whitespaceAndNewLineSet] characterIsMember:[input characterAtIndex:i]] ) i++

static NSCharacterSet* whitespaceAndNewLineSet = nil;

@implementation Parcoa (ISSAdditions)

+ (NSCharacterSet*) iss_whitespaceAndNewLineSet {
    if( !whitespaceAndNewLineSet ) whitespaceAndNewLineSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    return whitespaceAndNewLineSet;
}

+ (ParcoaParser*) iss_quickUnichar:(unichar)c skipSpace:(BOOL)skipSpace {
    return [ParcoaParser parserWithBlock:^ParcoaResult *(NSString *input) {
        NSUInteger i = 0;
        if( skipSpace ) SKIP_SPACE_AND_NEWLINES;

        if ( input.length && [input characterAtIndex:i] == c ) {
            NSString *value = [input substringWithRange:NSMakeRange(i, 1)];
            i++;
            if( skipSpace ) SKIP_SPACE_AND_NEWLINES;

            NSString *residual = [input substringFromIndex:i];
            return [ParcoaResult ok:value residual:residual expected:[ParcoaExpectation unsatisfiable]];
        } else {
            return [ParcoaResult failWithRemaining:input expected:@"Character matching unichar"];
        }
    } name:@"satisfy" summary:@"quickUnichar"];
}

+ (ParcoaParser*) iss_quickUnichar:(unichar)c {
    return [self iss_quickUnichar:c skipSpace:NO];
}

+ (ParcoaParser*) iss_stringIgnoringCase:(NSString*)string {
    return [ParcoaParser parserWithBlock:^ParcoaResult *(NSString *input) {
        if ( [[input lowercaseString] hasPrefix:string]) {
            return [ParcoaResult ok:string residual:[input substringFromIndex:string.length] expected:[ParcoaExpectation unsatisfiable]];
        } else {
            return [ParcoaResult failWithRemaining:input expectedWithFormat:@"String literal \"%@\"", string];
        }
    } name:@"stringIgnoringCase" summaryWithFormat:@"\"%@\"", string];
}

+ (ParcoaParser*) iss_takeUntil:(MatcherBlock)block minCount:(NSUInteger)minCount {
    return [ParcoaParser parserWithBlock:^ParcoaResult *(NSString *input) {
        NSUInteger i = block(input);

        NSString* value = input;
        NSString* residual = @"";
        if( i != NSNotFound ) {
            value = [input substringToIndex:i];
            residual = [input substringFromIndex:i];
        } else i = input.length;

        if( i >= minCount ) {
            return [ParcoaResult ok:value residual:residual expected:@"Character not matching predicate"];
        } else {
            return [ParcoaResult failWithRemaining:input expected:@"Character matching predicate"];
        }
    } name:@"takeUntil" summary:@"takeUntil"];
}

+ (ParcoaParser*) iss_takeUntilInSet:(NSCharacterSet*)characterSet minCount:(NSUInteger)minCount {
    return [self iss_takeUntil:^NSUInteger(NSString* input) {
        return [input rangeOfCharacterFromSet:characterSet].location;
    }                 minCount:minCount];
}

+ (ParcoaParser*) iss_takeUntilChar:(unichar)character {
    NSString* characterString = [NSString stringWithFormat:@"%C", character];
    return [self iss_takeUntil:^NSUInteger(NSString* input) {
        return [input rangeOfString:characterString].location;
    }                 minCount:0];
}

+ (ParcoaParser*) iss_anythingButBasicControlChars:(NSUInteger)minCount {
    NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@":;{}"];
    return [self iss_takeUntilInSet:characterSet minCount:minCount];
}

+ (ParcoaParser*) iss_anythingButWhiteSpaceAndExtendedControlChars:(NSUInteger)minCount {
    NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@",:;{}()"];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [self iss_takeUntilInSet:characterSet minCount:minCount];
}

+ (NSCharacterSet*) iss_validIdentifierCharsSet {
    NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"-_"];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    return characterSet;
}

+ (ParcoaParser*) iss_validIdentifierChars:(NSUInteger)minCount {
    NSCharacterSet* characterSet = [self iss_validIdentifierCharsSet];
    return [self iss_takeUntilInSet:[characterSet invertedSet] minCount:minCount];
}

+ (ParcoaParser*) iss_safeDictionary:(ParcoaParser*)parser {
    return [parser transform:^id(id value) {
        NSMutableDictionary* dict = [NSMutableDictionary dictionary];
        [value enumerateObjectsUsingBlock:^(NSArray *obj, NSUInteger idx, BOOL *stop) {
            if( [obj isKindOfClass:NSArray.class] && [obj count] > 1 && obj[0] && obj[1] ) {
                dict[obj[0]] = obj[1];
            }
        }];
        return dict;
    } name:@"safeDictionary"];
}

+ (ParcoaParser*) iss_safeArray:(ParcoaParser*)parser {
    return [parser transform:^id(id value) {
        NSMutableArray* array = [[NSMutableArray alloc] init];
        if( [value isKindOfClass:NSArray.class] ) {
            for(id element in value) {
                if( element != NSNull.null ) {
                    [array addObject:element];
                }
            }
        }
        return array;
    } name:@"safeDictionary"];
}

+ (ParcoaResult*) iss_partialParserForPrefix:(NSString*)prefix input:(NSString*)input startIndex:(NSUInteger)i {
    NSRange prefixRange = [input rangeOfString:prefix options:NSCaseInsensitiveSearch range:NSMakeRange(i, input.length-i)];
    if( prefixRange.location == i ) {
        i += prefix.length;
        SKIP_SPACE_AND_NEWLINES; // Skip space
        if( i < input.length && [input characterAtIndex:i] == '(' ) {
            NSUInteger paramBeginIndex = ++i;
            i = [input rangeOfString:@")" options:0 range:NSMakeRange(i, input.length-i)].location;
            if( i != NSNotFound ) {
                NSString* value = [input substringWithRange:NSMakeRange(paramBeginIndex, i-paramBeginIndex)];
                i++;
                NSString* residual = [input substringFromIndex:i];
                return [ParcoaResult ok:value residual:residual expected:[ParcoaExpectation unsatisfiable]];
            }
        }
    }
    return nil;
}

+ (ParcoaParser*) iss_parameterStringWithPrefixes:(NSArray*)prefixes {
    return [ParcoaParser parserWithBlock:^ParcoaResult *(NSString *input) {
        NSUInteger i = 0;
        SKIP_SPACE_AND_NEWLINES; // Skip space

        for(NSString* prefix in prefixes) {
            ParcoaResult* result = [self iss_partialParserForPrefix:prefix input:input startIndex:i];
            if( result ) return result;
        }
        return [ParcoaResult failWithRemaining:input expected:@"Line matching parameter string"];
    } name:@"parameterStringWithPrefix" summary:@"parameterStringWithPrefix"];
}

+ (ParcoaParser*) iss_parameterStringWithPrefix:(NSString*)prefix {
    return [ParcoaParser parserWithBlock:^ParcoaResult *(NSString *input) {
        NSUInteger i = 0;
        SKIP_SPACE_AND_NEWLINES; // Skip space

        ParcoaResult* result = [self iss_partialParserForPrefix:prefix input:input startIndex:i];
        if( result ) return result;
        else return [ParcoaResult failWithRemaining:input expected:@"Line matching parameter string"];
    } name:@"parameterStringWithPrefix" summary:prefix];
}

+ (ParcoaParser*) iss_twoParameterFunctionParserWithName:(NSString*)name leftParameterParser:(ParcoaParser*)left rightParameterParser:(ParcoaParser*)right {
    ParcoaParser* parser = [[self iss_stringIgnoringCase:name] then:[self iss_quickUnichar:'(' skipSpace:YES]];
    parser = [[[parser keepRight:left] keepLeft:[self iss_quickUnichar:',' skipSpace:YES]] then:right];
    return [parser keepLeft:[self iss_quickUnichar:')' skipSpace:YES]];
}

+ (ParcoaParser*) iss_nameValueSeparator {
    return [ParcoaParser parserWithBlock:^ParcoaResult *(NSString *input) {
        NSUInteger i = 0;
        SKIP_SPACE_AND_NEWLINES; // Skip space

        unichar c = [input characterAtIndex:i];
        if ( input.length && (c == ':' | c == '=') ) {
            NSString *value = [input substringWithRange:NSMakeRange(i, 1)];
            i++;
            SKIP_SPACE_AND_NEWLINES; // Skip space
            NSString *residual = [input substringFromIndex:i];
            return [ParcoaResult ok:value residual:residual expected:[ParcoaExpectation unsatisfiable]];
        } else {
            return [ParcoaResult failWithRemaining:input expected:@"Character matching unichar"];
        }
    } name:@"nameValueSeparator" summary:@""];
}

+ (ParcoaParser*) iss_parseLineUpToInvalidCharactersInString:(NSString*)invalid {
    NSCharacterSet* invalidChars = [NSMutableCharacterSet characterSetWithCharactersInString:[@"\r\n" stringByAppendingString:invalid]];

    return [ParcoaParser parserWithBlock:^ParcoaResult *(NSString *input) {
        NSUInteger i = 0;
        SKIP_SPACE_AND_NEWLINES; // Skip space

        NSRange range = [input rangeOfCharacterFromSet:invalidChars options:0 range:NSMakeRange(i, input.length - i)];
        if( range.location != NSNotFound && range.location != 0 ) {
            i = range.location;
            while( i < input.length ) {
                unichar c = [input characterAtIndex:i];
                if( c == '\r' || c == '\n' ) i++;
                else break;
            }
        }

        if( i > 0 ) {
            NSString* value = [input substringToIndex:i];
            NSString* residual = [input substringFromIndex:i];
            return [ParcoaResult ok:value residual:residual expected:[ParcoaExpectation unsatisfiable]];
        } else {
            return [ParcoaResult failWithRemaining:input expected:@"Line not containing invalid characters"];
        }
    } name:@"parseLineUpToInvalidCharactersInString" summary:invalid];
}

+ (ParcoaParser*) iss_commentParser {
    return [ParcoaParser parserWithBlock:^ParcoaResult *(NSString *input) {
        NSUInteger i = 0;

        SKIP_SPACE_AND_NEWLINES; // Skip space
        if( i < input.length && [input characterAtIndex:i] == '/' ) {
            i++;
            BOOL singleLineComment = NO;
            unichar c = [input characterAtIndex:i];
            if( i < input.length && (c == '*' || (singleLineComment = (c == '/'))) ) {
                i++;
                NSUInteger commentBeginIndex = i;
                NSUInteger commentEndIndex = 0;
                BOOL commentMatch = NO;
                if( singleLineComment ) {
                    NSRange range = [input rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:NSMakeRange(i, input.length-i)];
                    if( range.location != NSNotFound ) {
                        i = range.location;
                        commentEndIndex = i;
                        commentMatch = YES;
                        c = [input characterAtIndex:i];
                        if( i < input.length && (c == '\r' || c == '\n') && c != [input characterAtIndex:range.location] ) { // Skip next \n if \r found etc...
                            i++;
                        }
                    }
                } else {
                    BOOL starFound = NO;
                    while( i < input.length ) {
                        c = [input characterAtIndex:i];
                        if( c == '*' ) {
                            starFound = YES;
                        } else if( starFound && c == '/' ) {
                            commentMatch = YES;
                            commentEndIndex = i - 1;
                            i++;
                            break;
                        } else /*if( ![whitespaceSet characterIsMember:[input characterAtIndex:i]] )*/ {
                            starFound = NO;
                        }
                        i++;
                    }
                }

                if( commentMatch ) {
                    NSString* value = [input substringWithRange:NSMakeRange(commentBeginIndex, commentEndIndex-commentBeginIndex)];
                    NSString* residual = [input substringFromIndex:i];
                    return [ParcoaResult ok:value residual:residual expected:[ParcoaExpectation unsatisfiable]];
                }
            }
        }

        return [ParcoaResult failWithRemaining:input expected:@"Line matching comment string"];
    } name:@"commentParser" summary:@"commentParser"];
}

@end
