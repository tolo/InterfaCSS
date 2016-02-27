//
//  ISSParser+CSS.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2016-01-10.
//  Copyright (c) 2016 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//


#import "ISSParser+CSS.h"

#import "NSString+ISSStringAdditions.h"


@implementation ISSParser (CSS)

+ (ISSParser*) iss_anythingButBasicControlChars:(NSUInteger)minCount {
    NSCharacterSet* characterSet = [[NSMutableCharacterSet characterSetWithCharactersInString:@":;{}"] copy];
    return [self takeUntilInSet:characterSet minCount:minCount];
}

+ (ISSParser*) iss_anythingButBasicControlCharsExceptColon:(NSUInteger)minCount {
    NSCharacterSet* characterSet = [[NSMutableCharacterSet characterSetWithCharactersInString:@";{}"] copy];
    return [self takeUntilInSet:characterSet minCount:minCount];
}

+ (ISSParser*) iss_anythingButWhiteSpaceAndExtendedControlChars:(NSUInteger)minCount {
    NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@",:;{}()"];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [self takeUntilInSet:[characterSet copy] minCount:minCount];
}

+ (NSCharacterSet*) iss_validInitialIdentifierCharacterCharsSet {
    static NSCharacterSet* characterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet* _characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"_"];
        [_characterSet formUnionWithCharacterSet:[NSCharacterSet letterCharacterSet]];
        characterSet = [_characterSet copy];
    });
    
    return characterSet;
}

+ (NSCharacterSet*) iss_validIdentifierExcludingMinusCharsSet {
    static NSCharacterSet* characterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet* _characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"_"];
        [_characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        characterSet = [_characterSet copy];
    });
    
    return characterSet;
}

+ (NSCharacterSet*) iss_validIdentifierCharsSet {
    static NSCharacterSet* characterSet = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet* _characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"-_"];
        [_characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
        characterSet = [_characterSet copy];
    });
    
    return characterSet;
}

+ (ISSParser*) iss_validIdentifierChars:(NSUInteger)minCount {
    return [self iss_validIdentifierChars:minCount onlyAlphpaAndUnderscore:NO];
}

+ (ISSParser*) iss_validIdentifierChars:(NSUInteger)minCount onlyAlphpaAndUnderscore:(BOOL)onlyAlphpaAndUnderscore {
    NSCharacterSet* characterSet;
    if( onlyAlphpaAndUnderscore ) characterSet = [self iss_validIdentifierExcludingMinusCharsSet];
    else characterSet = [self iss_validIdentifierCharsSet];
    
    return [self takeWhileInSet:characterSet initialCharSet:[self iss_validInitialIdentifierCharacterCharsSet] minCount:minCount]; // First identifier char must not be digit...
}

+ (NSCharacterSet*) iss_mathExpressionCharsSet {
    NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"+-*/%^=≠<>≤≥|&!()."];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
    return [characterSet copy];
}

+ (ISSParser*) iss_logicalExpressionParser {
    NSCharacterSet* invertedCharacterSet = [[self iss_mathExpressionCharsSet] invertedSet];
    return [[self takeUntilInSet:invertedCharacterSet minCount:1] transform:^id(id value) {
        NSPredicate* expr = [NSPredicate predicateWithFormat:value];
        return @([expr evaluateWithObject:nil]);
    }];
}

+ (ISSParser*) iss_mathExpressionParser {
    NSCharacterSet* invertedCharacterSet = [[self iss_mathExpressionCharsSet] invertedSet];
    return [[self takeUntilInSet:invertedCharacterSet minCount:1] transform:^id(id value) {
        return [self iss_parseMathExpression:value];
    }];
}

+ (id) iss_parseMathExpression:(NSString*)value {
    NSExpression* expr = [NSExpression expressionWithFormat:value];
    return [expr expressionValueWithObject:nil context:nil];
}

+ (id) iss_partialParameterStringWithPrefix:(NSString*)prefix input:(NSString*)input status:(ISSParserStatus*)status {
    NSUInteger i = status->index;
    
    NSRange prefixRange = prefix ? [input rangeOfString:prefix options:NSCaseInsensitiveSearch range:NSMakeRange(i, input.length-i)] : NSMakeRange(i, 0);
    if( prefixRange.location == i ) {
        i += prefix.length;
        ISSParserSkipSpaceAndNewLines(input); // Skip space
        if( i < input.length && [input characterAtIndex:i] == '(' ) {
            i++;
            NSInteger nestingLevel = 0;
            NSMutableArray* parameters = [NSMutableArray array];
            NSUInteger currentParameterIndex = i;
            
            while ( i < input.length ) {
                NSRange residualRange = NSMakeRange(i, input.length-i);
                NSInteger nextCommaLocation = [input rangeOfString:@"," options:0 range:residualRange].location;
                NSInteger nestedParamStringLocation = [input rangeOfString:@"(" options:0 range:residualRange].location;
                i = [input rangeOfString:@")" options:0 range:residualRange].location;
                
                // Comma separator found on top level - add parameter to array
                if( nestingLevel == 0 && nextCommaLocation != NSNotFound && nextCommaLocation < i && nextCommaLocation < nestedParamStringLocation ) {
                    NSString* parameterString = [input substringWithRange:NSMakeRange(currentParameterIndex, (NSUInteger)nextCommaLocation - currentParameterIndex)];
                    parameterString = [parameterString iss_trim];
                    [parameters addObject:parameterString];
                    currentParameterIndex = (NSUInteger)nextCommaLocation + 1;
                    i = currentParameterIndex;
                }
                // Nested parameter string begin marker '(' found
                else if( nestedParamStringLocation != NSNotFound && nestedParamStringLocation < i ) {
                    nestingLevel++;
                    i = (NSUInteger)nestedParamStringLocation + 1;
                }
                // Parameter string end marker ')' (potentially) found
                else {
                    if ( i != NSNotFound && nestingLevel == 0 ) {
                        // Add last parameter
                        NSString* parameterString = [input substringWithRange:NSMakeRange(currentParameterIndex, (NSUInteger)i - currentParameterIndex)];
                        parameterString = [parameterString iss_trim];
                        [parameters addObject:parameterString];
                        i++;
                        
                        *status = (ISSParserStatus){.match = YES, .index = i};
                        return parameters;
                    }
                    else if ( i != NSNotFound ) {
                        nestingLevel--;
                        i++;
                    }
                    else {
                        break;
                    }
                }
            }
        }
    }
    return nil;
}

+ (ISSParser*) iss_parameterStringWithPrefixes:(NSArray*)prefixes {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        ISSParserSkipSpaceAndNewLines(input); // Skip space
        
        for(NSString* prefix in prefixes) {
            ISSParserStatus prefixStatus = (ISSParserStatus){.match = NO, .index = i};
            id result = [self iss_partialParameterStringWithPrefix:prefix input:input status:&prefixStatus];
            if( prefixStatus.match ) {
                *status = prefixStatus;
                return result;
            }
        }
        return [NSNull null];
    } andName:@"iss_parameterStringWithPrefixes"];
}

+ (ISSParser*) iss_parameterStringWithPrefix:(NSString*)prefix {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        ISSParserSkipSpaceAndNewLines(input); // Skip space
        
        ISSParserStatus prefixStatus = (ISSParserStatus){.match = NO, .index = i};
        id result = [self iss_partialParameterStringWithPrefix:prefix input:input status:&prefixStatus];
        if( prefixStatus.match ) {
            *status = prefixStatus;
            return result;
        }
        else {
            return [NSNull null];
        }
    } andName:@"iss_parameterStringWithPrefix"];
}

+ (ISSParser*) iss_parameterString {
    return [self iss_parameterStringWithPrefix:nil];
}

+ (ISSParser*) iss_twoParameterFunctionParserWithName:(NSString*)name leftParameterParser:(ISSParser*)left rightParameterParser:(ISSParser*)right {
    ISSParser* parser = [[self stringEQIgnoringCase:name] then:[self unichar:'(' skipSpaces:YES]];
    parser = [[[parser keepRight:left] keepLeft:[self unichar:',' skipSpaces:YES]] then:right];
    return [parser keepLeft:[self unichar:')' skipSpaces:YES]];
}

+ (ISSParser*) iss_singleParameterFunctionParserWithName:(NSString*)name parameterParser:(ISSParser*)parameterParser {
    ISSParser* parser = [[self stringEQIgnoringCase:name] then:[self unichar:'(' skipSpaces:YES]];
    parser = [parser keepRight:parameterParser];
    return [parser keepLeft:[self sequential:@[[self spaces], [self unichar:')']]]];
}

+ (ISSParser*) iss_singleParameterFunctionParserWithNames:(NSArray*)names parameterParser:(ISSParser*)parameterParser {
    NSMutableArray* nameParsers = [NSMutableArray array];
    for(NSString* name in names) {
        [nameParsers addObject:[self stringEQIgnoringCase:name]];
    }
    
    ISSParser* parser = [[self choice:nameParsers] then:[self unichar:'(' skipSpaces:YES]];
    parser = [parser keepRight:parameterParser];
    return [parser keepLeft:[self unichar:')' skipSpaces:YES]];
}

+ (ISSParser*) iss_parseLineUpToInvalidCharactersInString:(NSString*)invalid {
    NSCharacterSet* invalidChars = [NSCharacterSet characterSetWithCharactersInString:[@"\r\n" stringByAppendingString:invalid]];
    
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        const NSUInteger len = input.length;
        ISSParserSkipSpaceAndNewLines(input); // Skip space
        
        NSRange range = [input rangeOfCharacterFromSet:invalidChars options:0 range:NSMakeRange(i, len - i)];
        if( range.location != NSNotFound && range.location != 0 ) {
            i = range.location;
            while( i < len ) {
                unichar c = [input characterAtIndex:i];
                if( c == '\r' || c == '\n' ) i++;
                else break;
            }
        }
        
        if( (i - status->index) > 0 ) {
            NSString* value = [input substringWithRange:NSMakeRange(status->index, i - status->index)];
            *status = (ISSParserStatus){.match = YES, .index = i};
            return value;
        } else {
            return [NSNull null];
        }
    } andName:@"iss_parseLineUpToInvalidCharactersInString"];
}

+ (ISSParser*) iss_commentParser {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        const NSUInteger len = input.length;
        ISSParserSkipSpaceAndNewLines(input); // Skip space

        if( i < len && [input characterAtIndex:i] == '/' ) {
            i++;
            BOOL singleLineComment = NO;
            unichar c = [input characterAtIndex:i];
            if( i < len && (c == '*' || (singleLineComment = (c == '/'))) ) {
                i++;
                NSUInteger commentBeginIndex = i;
                NSUInteger commentEndIndex = 0;
                BOOL commentMatch = NO;
                if( singleLineComment ) {
                    NSRange range = [input rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:NSMakeRange(i, len-i)];
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
                    while( i < len ) {
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
                    *status = (ISSParserStatus){.match = YES, .index = i};
                    return value;
                }
            }
        }
        
        return [NSNull null];
    } andName:@"iss_commentParser"];
}

+ (NSString*) iss_parseEscapedAndParameterizedStringUpToChar:(unichar)char1 orChar:(unichar)char2 inString:(NSString*)input index:(NSUInteger*)index {
    NSUInteger i = *index;
    const NSUInteger len = input.length;
    
    BOOL backslashEscape = NO;
    BOOL inSingleQuote = NO;
    BOOL inQuote = NO;
    NSInteger parameterListNesting = 0;
    NSInteger indexAfterLastNonWhitespaceChar = -1;
    NSCharacterSet* whitespaceChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    for(; i < len; i++) {
        unichar c = [input characterAtIndex:i];
        BOOL inAnyQuote = inSingleQuote || inQuote;
        BOOL isWhiteSpace = NO;
        
        if( c == '\\' ) {
            backslashEscape = !backslashEscape;
            continue;
        }
        
        // Check if unescaped end char is reached:
        if( (c == char1 || c == char2) && !inAnyQuote && parameterListNesting == 0 && indexAfterLastNonWhitespaceChar > -1 ) {
            NSString* value = [input substringWithRange:NSMakeRange(*index, indexAfterLastNonWhitespaceChar - *index)];
            *index = i + 1;
            return value;
        }
        // Invalid chars:
        else if( (c == '{' || c == '}') && !inAnyQuote ) {
            break;
        }
        // Check for quites and parameter lists:
        else if( c == '(' && !inAnyQuote ) {
            parameterListNesting++;
        }
        else if( c == ')' && !inAnyQuote ) {
            parameterListNesting--;
        }
        else if( c == '\'' && !inQuote && !backslashEscape ) {
            inSingleQuote = !inSingleQuote;
        }
        else if( c == '\"' && !inSingleQuote && !backslashEscape ) {
            inQuote = !inQuote;
        }
        else if([whitespaceChars characterIsMember:c]) {
            isWhiteSpace = YES;
        }
        
        if( !isWhiteSpace ) {
            indexAfterLastNonWhitespaceChar = i + 1;
        }
        
        backslashEscape = NO;
    }
    
    return nil;
}

+ (ISSParser*) iss_propertyPairParser:(BOOL)forVariableDefinition {
    NSCharacterSet* validInitialIdentifierChars = [self iss_validInitialIdentifierCharacterCharsSet];
    
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        const NSUInteger len = input.length;
        ISSParserSkipSpaceAndNewLines(input); // Skip space
        
        if( forVariableDefinition ) {
            if( i < len && '@' == [input characterAtIndex:i] ) {
                i++;
            } else {
                return [NSNull null];
            }
        }
        
        if( [validInitialIdentifierChars characterIsMember:[input characterAtIndex:i]] ) { // Make sure name starts with valid initial idenfifier char
            
            // Parse name and separator:
            NSString* name = nil;
            if( forVariableDefinition ) {
                ISSParser* parser = [ISSParser takeWhileInSet:[self iss_validIdentifierCharsSet]];
                ISSParserStatus nameStatus = {.match = NO, .index = i};
                name = [parser parse:input status:&nameStatus];
                i = nameStatus.index;
                
                ISSParserSkipSpaceAndNewLines(input); // Skip space
                
                unichar c = [input characterAtIndex:i];
                if(c == ':' || c == '=') {
                    i++;
                } else {
                    name = nil;
                }
            } else {
                name = [self iss_parseEscapedAndParameterizedStringUpToChar:':' orChar:'=' inString:input index:&i];
            }
            
            if( name && name.length > 0 ) {
                ISSParserSkipSpaceAndNewLines(input); // Skip space
                
                // Parse value:
                NSString* value = [self iss_parseEscapedAndParameterizedStringUpToChar:';' orChar:0 inString:input index:&i];
                if( value ) {
                    *status = (ISSParserStatus){.match = YES, .index = i + 1};
                    return @[name, value];
                }
            }
        }
        
        return [NSNull null];
    } andName:@"iss_propertyPairParser"];
}

@end
