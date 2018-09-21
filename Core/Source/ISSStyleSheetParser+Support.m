//
//  ISSStyleSheetParser+Support.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSStyleSheetParser+Protected.h"
#import "ISSStyleSheetParser+Support.h"

#import "NSString+ISSAdditions.h"


@implementation ISSStyleSheetParser (Support)

- (ISSParser*) anythingButBasicControlChars:(NSUInteger)minCount {
    NSCharacterSet* characterSet = [[NSMutableCharacterSet characterSetWithCharactersInString:@":;{}"] copy];
    return [ISSParser takeUntilInSet:characterSet minCount:minCount];
}

- (ISSParser*) anythingButBasicControlCharsExceptColon:(NSUInteger)minCount {
    NSCharacterSet* characterSet = [[NSMutableCharacterSet characterSetWithCharactersInString:@";{}"] copy];
    return [ISSParser takeUntilInSet:characterSet minCount:minCount];
}

- (ISSParser*) anythingButWhiteSpaceAndExtendedControlChars:(NSUInteger)minCount {
    NSMutableCharacterSet* characterSet = [NSMutableCharacterSet characterSetWithCharactersInString:@",:;{}()"];
    [characterSet formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [ISSParser takeUntilInSet:[characterSet copy] minCount:minCount];
}

- (ISSParser*) validIdentifierChars:(NSUInteger)minCount {
    return [self validIdentifierChars:minCount onlyAlphpaAndUnderscore:NO];
}

- (ISSParser*) validIdentifierChars:(NSUInteger)minCount onlyAlphpaAndUnderscore:(BOOL)onlyAlphpaAndUnderscore {
    NSCharacterSet* characterSet;
    if( onlyAlphpaAndUnderscore ) characterSet = self.validIdentifierExcludingMinusCharsSet;
    else characterSet = self.validIdentifierCharsSet;
    
    return [ISSParser takeWhileInSet:characterSet initialCharSet:self.validInitialIdentifierCharacterCharsSet minCount:minCount]; // First identifier char must not be digit...
}

- (ISSParser*) logicalExpressionParser {
    NSCharacterSet* invertedCharacterSet = [self.mathExpressionCharsSet invertedSet];
    return [[ISSParser takeUntilInSet:invertedCharacterSet minCount:1] transform:^id(id value, void* context) {
        NSPredicate* expr = [NSPredicate predicateWithFormat:value];
        return @([expr evaluateWithObject:nil]);
    }];
}

- (ISSParser*) mathExpressionParser {
    NSCharacterSet* invertedCharacterSet = [self.mathExpressionCharsSet invertedSet];
    return [[ISSParser takeUntilInSet:invertedCharacterSet minCount:1] transform:^id(id value, void* context) {
        return [self parseMathExpression:value];
    }];
}

- (id) parseMathExpression:(NSString*)value {
    NSExpression* expr = [NSExpression expressionWithFormat:value];
    return [expr expressionValueWithObject:nil context:nil];
}

- (id) partialParameterStringWithPrefix:(NSString*)prefix input:(NSString*)input status:(ISSParserStatus*)status {
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
                        
                        *status = (ISSParserStatus){.match = YES, .index = i, .context = status->context};
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

- (ISSParser*) parameterStringWithPrefixes:(NSArray*)prefixes {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        ISSParserSkipSpaceAndNewLines(input); // Skip space
        
        for(NSString* prefix in prefixes) {
            ISSParserStatus prefixStatus = (ISSParserStatus){.match = NO, .index = i, .context = status->context};
            id result = [self partialParameterStringWithPrefix:prefix input:input status:&prefixStatus];
            if( prefixStatus.match ) {
                *status = prefixStatus;
                return result;
            }
        }
        return [NSNull null];
    } andName:@"iss_parameterStringWithPrefixes"];
}

- (ISSParser*) parameterStringWithPrefix:(NSString*)prefix {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        ISSParserSkipSpaceAndNewLines(input); // Skip space
        
        ISSParserStatus prefixStatus = (ISSParserStatus){.match = NO, .index = i, .context = status->context};
        id result = [self partialParameterStringWithPrefix:prefix input:input status:&prefixStatus];
        if( prefixStatus.match ) {
            *status = prefixStatus;
            return result;
        }
        else {
            return [NSNull null];
        }
    } andName:@"iss_parameterStringWithPrefix"];
}

- (ISSParser*) parameterString {
    return [self parameterStringWithPrefix:nil];
}

- (ISSParser*) twoParameterFunctionParserWithName:(NSString*)name leftParameterParser:(ISSParser*)left rightParameterParser:(ISSParser*)right {
    ISSParser* parser = [[ISSParser stringEQIgnoringCase:name] then:[ISSParser unichar:'(' skipSpaces:YES]];
    parser = [[[parser keepRight:left] keepLeft:[ISSParser unichar:',' skipSpaces:YES]] then:right];
    return [parser keepLeft:[ISSParser unichar:')' skipSpaces:YES]];
}

- (ISSParser*) singleParameterFunctionParserWithName:(NSString*)name parameterParser:(ISSParser*)parameterParser {
    ISSParser* parser = [[ISSParser stringEQIgnoringCase:name] then:[ISSParser unichar:'(' skipSpaces:YES]];
    parser = [parser keepRight:parameterParser];
    return [parser keepLeft:[ISSParser sequential:@[[ISSParser spaces], [ISSParser unichar:')']]]];
}

- (ISSParser*) singleParameterFunctionParserWithNames:(NSArray*)names parameterParser:(ISSParser*)parameterParser {
    NSMutableArray* nameParsers = [NSMutableArray array];
    for(NSString* name in names) {
        [nameParsers addObject:[ISSParser stringEQIgnoringCase:name]];
    }
    
    ISSParser* parser = [[ISSParser choice:nameParsers] then:[ISSParser unichar:'(' skipSpaces:YES]];
    parser = [parser keepRight:parameterParser];
    return [parser keepLeft:[ISSParser unichar:')' skipSpaces:YES]];
}

- (ISSParser*) parseLineUpToInvalidCharactersInString:(NSString*)invalid {
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
            *status = (ISSParserStatus){.match = YES, .index = i, .context = status->context};
            return value;
        } else {
            return [NSNull null];
        }
    } andName:@"iss_parseLineUpToInvalidCharactersInString"];
}

- (ISSParser*) commentParser {
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
                    *status = (ISSParserStatus){.match = YES, .index = i, .context = status->context};
                    return value;
                }
            }
        }
        
        return [NSNull null];
    } andName:@"iss_commentParser"];
}

- (NSString*) parseEscapedAndParameterizedStringUpToChar:(unichar)char1 orChar:(unichar)char2 inString:(NSString*)input index:(NSUInteger*)index {
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

- (ISSParser*) propertyPairParser:(BOOL)forVariableDefinition {
    NSCharacterSet* validInitialIdentifierChars = [self validInitialIdentifierCharacterCharsSet];
    
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
                ISSParser* parser = [ISSParser takeWhileInSet:[self validIdentifierCharsSet]];
                ISSParserStatus nameStatus = {.match = NO, .index = i, .context = status->context};
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
                name = [self parseEscapedAndParameterizedStringUpToChar:':' orChar:'=' inString:input index:&i];
            }
            
            if( name && name.length > 0 ) {
                ISSParserSkipSpaceAndNewLines(input); // Skip space
                
                // Parse value:
                NSString* value = [self parseEscapedAndParameterizedStringUpToChar:';' orChar:0 inString:input index:&i];
                if( value ) {
                    *status = (ISSParserStatus){.match = YES, .index = i + 1, .context = status->context};
                    return @[name, value];
                }
            }
        }
        
        return [NSNull null];
    } andName:@"iss_propertyPairParser"];
}

@end
