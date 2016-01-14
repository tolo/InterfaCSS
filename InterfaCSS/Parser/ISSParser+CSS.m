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
    NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"_"];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet letterCharacterSet]];
    return [characterSet copy];
}

+ (NSCharacterSet*) iss_validIdentifierExcludingMinusCharsSet {
    NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"_"];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    return [characterSet copy];
}

+ (NSCharacterSet*) iss_validIdentifierCharsSet {
    NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"-_"];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet alphanumericCharacterSet]];
    return [characterSet copy];
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

+ (ISSParser*) iss_propertyPairParser:(BOOL)forVariableDefinition {
    NSCharacterSet* validIdentifierChars;
    if( forVariableDefinition ) validIdentifierChars = [self iss_validIdentifierCharsSet];
    NSCharacterSet* whitespaceChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        const NSUInteger len = input.length;
        ISSParserSkipSpaceAndNewLines(input); // Skip space
        
        BOOL backslashEscape = NO;
        BOOL inSingleQuote = NO;
        BOOL inQuote = NO;
        NSUInteger parameterListNesting = 0;
        NSInteger propertyNameBeginIndex = -1;
        NSInteger propertyNameEndIndex = -1;
        NSInteger propertyValueBeginIndex = -1;
        NSInteger propertyValueEndIndex = -1;
        NSInteger indexOfLastNonWhitespaceChar = -1;
        NSInteger state = -1; // -1 = initial, 0 = property name, 1 = separator, 2 = property value, 3 = end
        
        if( forVariableDefinition ) {
            if( i < len && '@' == [input characterAtIndex:i] ) {
                i++;
            } else {
                return [NSNull null];
            }
        }
        
        for(; i < len; i++) {
            unichar c = [input characterAtIndex:i];
            BOOL initialState = state == -1;
            BOOL inAnyQuote = inSingleQuote || inQuote;
            BOOL isValidChar = YES;
            NSUInteger nextState = state;
            
            if( c == '\\' ) {
                backslashEscape = !backslashEscape;
                continue;
            }
            
            // Property part separators:
            if( (c == ':' || c == '=') ) {
                if( state == 0 && propertyNameBeginIndex > -1 ) {
                    isValidChar = NO;
                    nextState = 1;
                    propertyNameEndIndex = indexOfLastNonWhitespaceChar + 1;
                } else if ( initialState || (!inAnyQuote && parameterListNesting == 0) ) {
                    break;
                }
            }
            else if( c == ';' && !inAnyQuote ) {
                if( state == 2 && propertyValueBeginIndex > -1 ) {
                    propertyValueEndIndex = indexOfLastNonWhitespaceChar + 1;
                    i++;
                    state = 3;
                }
                break; // Done (or error)
            }
            // Invalid chars:
            else if( (c == '{' || c == '}') && !inAnyQuote ) {
                break;
            }
            // Check for quites and parameter lists:
            else if( c == '(' && !initialState && !inAnyQuote ) {
                if( forVariableDefinition && state == 0 ) break;
                parameterListNesting++;
            }
            else if( c == ')' && !initialState && !inAnyQuote ) {
                if( forVariableDefinition && state == 0 ) break;
                parameterListNesting--;
            }
            else if( c == '\'' && !initialState && !inQuote && !backslashEscape ) {
                if( forVariableDefinition && state == 0 ) break;
                inSingleQuote = !inSingleQuote;
            }
            else if( c == '\"' && !initialState && !inSingleQuote && !backslashEscape ) {
                if( forVariableDefinition && state == 0 ) break;
                inQuote = !inQuote;
            }
            // Other chars:
            else {
                isValidChar = ![whitespaceChars characterIsMember:c];
                
                if( forVariableDefinition && state < 1 && ![validIdentifierChars characterIsMember:c] ) {
                    break;
                }
            }
            
            // Check for name and value start positions:
            if( initialState && isValidChar ) {
                propertyNameBeginIndex = indexOfLastNonWhitespaceChar = i;
                nextState = 0;
            }
            else if( state == 1 && isValidChar ) {
                propertyValueBeginIndex = indexOfLastNonWhitespaceChar = i;
                nextState = 2;
            }
            else if( !initialState && isValidChar ) {
                indexOfLastNonWhitespaceChar = i;
            }
            
            backslashEscape = NO;
            state = nextState;
        }
        
        if( state == 3 && propertyNameEndIndex > -1 && propertyValueEndIndex > propertyNameEndIndex ) {
            ISSParserSkipSpaceAndNewLines(input); // Skip space
            
            NSString* name = [input substringWithRange:NSMakeRange(propertyNameBeginIndex, propertyNameEndIndex - propertyNameBeginIndex)];
            NSString* value = [input substringWithRange:NSMakeRange(propertyValueBeginIndex, propertyValueEndIndex - propertyValueBeginIndex)];
            
            *status = (ISSParserStatus){.match = YES, .index = i};
            return @[name, value];
        }
        
        return [NSNull null];
    } andName:@"iss_propertyPairParser"];
}

@end
