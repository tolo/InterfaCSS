//
//  ISSParser.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//  Inspired by Parcoa (https://github.com/brotchie/Parcoa).
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSParser.h"


@interface ISSParser ()
@property (nonatomic, copy) ISSParserBlock parserBlock;
@property (nonatomic, strong) NSString* name;
@end

@implementation ISSParser

- (instancetype) initWithBlock:(ISSParserBlock)block andName:(NSString*)name {
    if ( self = [super init] ) {
        _parserBlock = block;
        _name = name;
    }
    return self;
}

+ (ISSParser*) parserWithBlock:(ISSParserBlock)block andName:(NSString*)name {
    return [[self alloc] initWithBlock:block andName:name];
}

- (id) parse:(NSString*)string status:(ISSParserStatus*)status {
    return self.parserBlock(string, status);
}

- (NSString*) description {
    return self.name;
}


#pragma mark - Combinators

+ (ISSParser*) choice:(NSArray*)parsers {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        id value = nil;
        for(ISSParser* parser in parsers) {
            value = [parser parse:input status:status];
            if( status->match ) {
                break;
            }
        }
        return value ?: [NSNull null];
    } andName:@"choice"];
}

- (ISSParser*) parserOr:(ISSParser*)parser {
    return [ISSParser choice:@[self, parser]];
}

+ (ISSParser*) sequential:(NSArray*)parsers {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSMutableArray* sequentialResult = nil;
        NSUInteger i = status->index;
        for(ISSParser* parser in parsers) {
            ISSParserStatus parserStatus = {.match = NO, .index = i};
            id parserResult = [parser parse:input status:&parserStatus];
            if( parserStatus.match ) {
                i = parserStatus.index;
                if( !sequentialResult ) sequentialResult = [NSMutableArray array];
                [sequentialResult addObject:parserResult ?: [NSNull null]];
            } else {
                return [NSNull null];
            }
        }
        status->match = YES;
        status->index = i;
        return sequentialResult ?: @[];
    } andName:@"sequential"];
}

+ (ISSParser*) optional:(ISSParser*)parser {
    return [self optional:parser defaultValue:[NSNull null]];
}

+ (ISSParser*) optional:(ISSParser*)parser defaultValue:(id)defaultValue {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        id value = [parser parse:input status:status];
        status->match = YES;
        return value ?: defaultValue;
    } andName:[NSString stringWithFormat:@"optional(%@)", parser.name]];
}

- (ISSParser*) then:(ISSParser*)parser {
    ISSParser* then = [ISSParser sequential:@[self, parser]];
    then.name = @"then";
    return then;
}

- (ISSParser*) keepLeft:(ISSParser*)parser {
    ISSParser* keepLeft = [[ISSParser sequential:@[self, parser]] transform:^id(NSArray* sequentialResult) {
        return sequentialResult[0];
    }];
    keepLeft.name = @"keepLeft";
    return keepLeft;
}

- (ISSParser*) keepRight:(ISSParser*)parser {
    ISSParser* keepRight = [[ISSParser sequential:@[self, parser]] transform:^id(NSArray* sequentialResult) {
        return sequentialResult[1];
    }];
    keepRight.name = @"keepRight";
    return keepRight;
}

- (ISSParser*) between:(ISSParser*)left and:(ISSParser*)right {
    ISSParser* between = [[ISSParser sequential:@[left, self, right]] transform:^id(NSArray* sequentialResult) {
        return sequentialResult[1];
    }];
    between.name = @"between";
    return between;
}

- (ISSParser*) many {
    return [self many:0 onlyValid:NO];
}

- (ISSParser*) many1 {
    ISSParser* many = [self many:1 onlyValid:NO];
    many.name = @"many";
    return many;
}

- (ISSParser*) manyActualValues {
    ISSParser* many = [self many:0 onlyValid:YES];
    many.name = @"manyActualValues";
    return many;
}

- (ISSParser*) many1ActualValues {
    ISSParser* many = [self many:1 onlyValid:YES];
    many.name = @"many1ActualValues";
    return many;
}

- (ISSParser*) many:(NSUInteger)minCount onlyValid:(BOOL)onlyValid {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSMutableArray* values = [NSMutableArray array];
        const NSUInteger len = input.length;
        
        do {
            status->match = NO;
            id value = [self parse:input status:status];
            if( status->match ) {
                if( !onlyValid || value != [NSNull null] ) [values addObject:value];
            }
        } while (status->match && status->index < len);
        
        if( values.count >= minCount ) {
            status->match = YES;
            return values;
        } else {
            return [NSNull null];
        }
    } andName:@"many"];
}

- (ISSParser*) sepBy:(ISSParser*)delimiterParser {
    return [self sepBy:delimiterParser minCount:0 keep:NO];
}

- (ISSParser*) sepBy1:(ISSParser*)delimiterParser {
    ISSParser* sepBy1 = [self sepBy:delimiterParser minCount:1 keep:NO];
    sepBy1.name = @"sepBy1";
    return sepBy1;
}

- (ISSParser*) sepByKeep:(ISSParser*)delimiterParser {
    ISSParser* sepByKeep = [self sepBy:delimiterParser minCount:0 keep:YES];
    sepByKeep.name = @"sepByKeep";
    return sepByKeep;
}

- (ISSParser*) sepBy1Keep:(ISSParser*)delimiterParser {
    ISSParser* sepBy1Keep = [self sepBy:delimiterParser minCount:1 keep:YES];
    sepBy1Keep.name = @"sepBy1Keep";
    return sepBy1Keep;
}

- (ISSParser*) sepBy:(ISSParser*)delimiterParser minCount:(NSUInteger)minCount keep:(BOOL)keep {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        NSUInteger lastValidIndex = i;
        const NSUInteger len = input.length;
        BOOL parsingDelimiter = NO;
        NSUInteger valueCount = 0;
        NSMutableArray* results = [NSMutableArray array];
        id lastSeparator = nil;
        
        while (i < len) {
            ISSParserStatus parserStatus = {.match = NO, .index = i};
            
            if( parsingDelimiter ) {
                id value = [delimiterParser parse:input status:&parserStatus];
                if( parserStatus.match ) {
                    if( keep ) lastSeparator = value ?: [NSNull null];
                } else {
                    break;
                }
            } else {
                id value = [self parse:input status:&parserStatus];
                if( parserStatus.match ) {
                    lastValidIndex = parserStatus.index;
                    if( lastSeparator ) [results addObject:lastSeparator];
                    [results addObject:value ?: [NSNull null]];
                    valueCount++;
                } else {
                    break;
                }
            }
            
            parsingDelimiter = !parsingDelimiter;
            i = parserStatus.index;
        }
        
        if( valueCount >= minCount ) {
            *status = (ISSParserStatus){.match = YES, .index = lastValidIndex};
            return results;
        } else {
            return [NSNull null];
        }
    } andName:@"sepBy"];
}

- (ISSParser*) concat {
    ISSParser* concat = [self transform:^id(id value) {
        return [value componentsJoinedByString:@""];
    }];
    concat.name = @"concat";
    return concat;
}

- (ISSParser*) concatMany {
    ISSParser* concatMany = [[self many] concat];
    concatMany.name = @"concatMany";
    return concatMany;
}

- (ISSParser*) concatMany1 {
    ISSParser* concatMany1 = [[self many1] concat];
    concatMany1.name = @"concatMany1";
    return concatMany1;
}


#pragma mark - Transform

- (ISSParser*) transform:(ISSParserTransformerBlock)transformer {
    return [self transform:transformer name:[NSString stringWithFormat:@"transform(%@)", self.name]];
}

- (ISSParser*) transform:(ISSParserTransformerBlock)transformer name:(NSString*)name {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        id value = [self parse:input status:status];
        if( status->match ) {
            return transformer(value);
        } else {
            return [NSNull null];
        }
    } andName:name];
}


#pragma mark - Matchers

+ (ISSParser*) unichar:(unichar)c {
    return [self unichar:c skipSpaces:NO];
}

+ (ISSParser*) unichar:(unichar)character skipSpaces:(BOOL)skipSpaces {
    return [self charMatching:^BOOL(unichar c) {
        return character == c;
    } skipSpaces:skipSpaces name:@"charInSet"];
}

+ (ISSParser*) charInSet:(NSCharacterSet*)set {
    return [self charInSet:set skipSpaces:NO];
}

+ (ISSParser*) charInSet:(NSCharacterSet*)set skipSpaces:(BOOL)skipSpaces {
    return [self charMatching:^BOOL(unichar c) {
        return [set characterIsMember:c];
    } skipSpaces:skipSpaces name:@"charInSet"];
}

+ (ISSParser*) stringEQIgnoringCase:(NSString*)matcherString {
    matcherString = [matcherString lowercaseString];
    NSUInteger matcherLength = matcherString.length;
    
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        const NSUInteger len = input.length;
        NSUInteger m = 0;
        
        for(; m < matcherLength; i++, m++) {
            unichar inputChar = i < len ? tolower([input characterAtIndex:i]) : 0;
            if( inputChar != [matcherString characterAtIndex:m]) {
                return [NSNull null];
            }
        }
        
        NSString* value = [input substringWithRange:NSMakeRange(status->index, i - status->index)];
        *status = (ISSParserStatus){.match = YES, .index = i};
        return value;
    } andName:[NSString stringWithFormat:@"stringEQIgnoringCase(%@)", matcherString]];
}

+ (ISSParser*) space {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        if ( status->index < input.length && [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[input characterAtIndex:status->index]] ) {
            status->match = YES;
            status->index++;
        }
        return [NSNull null];
    } andName:@"space"];
}

+ (ISSParser*) spaces {
    return [self spaces:0];
}

+ (ISSParser*) spaces:(NSUInteger)minCount {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        ISSParserSkipSpaceAndNewLines(input);
        if ( (i - status->index) >= minCount ) {
            *status = (ISSParserStatus){.match = YES, .index = i};
        }
        return [NSNull null];
    } andName:@"spaces"];
}

- (ISSParser*) skipSurroundingSpaces {
    ISSParser* skipSurroundingSpaces = [self between:[ISSParser spaces] and:[ISSParser spaces]];
    skipSurroundingSpaces.name = @"skipSurroundingSpaces";
    return skipSurroundingSpaces;
}

+ (ISSParser*) digit {
    return [self charMatching:^BOOL(unichar c) {
        return [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:c];
    } skipSpaces:NO name:@"digit"];
}

+ (ISSParser*) charMatching:(ISSParserMatchCondition)matcher skipSpaces:(BOOL)skipSpaces name:(NSString*)name {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        if( skipSpaces ) ISSParserSkipSpaceAndNewLines(input);
        
        unichar c = i < input.length ? [input characterAtIndex:i] : 0;
        if ( matcher(c) ) {
            i++;
            if( skipSpaces ) ISSParserSkipSpaceAndNewLines(input);
            
            *status = (ISSParserStatus){.match = YES, .index = i};
            return [NSString stringWithFormat:@"%C", c];
        }
        return [NSNull null];
    } andName:name];
}


#pragma mark - Extractors

+ (ISSParser*) stringWithEscapesUpToUnichar:(unichar)c {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        const NSUInteger len = input.length;
        
        BOOL isBackslash = NO;
        for(; i < len; i++) {
            unichar charAtIndex = [input characterAtIndex:i];
            if( charAtIndex == c && !isBackslash ) {
                break;
            }
            else {
                if( charAtIndex == '\\' ) {
                    if ( isBackslash ) { // Double backslash
                        isBackslash = NO;
                    } else { // Backslash found
                        isBackslash = YES;
                    }
                } else if( isBackslash )  { // Previous character is backslash
                    isBackslash = NO;
                }
            }
        }
        
        NSString* string = [input substringWithRange:NSMakeRange(status->index, i - status->index)];
        NSUInteger stringLength = string.length;
        for(int c=0; c<stringLength; c++) {
            unichar charAtIndex = [string characterAtIndex:c];
            if( charAtIndex == '\\' ) {
                if ( isBackslash ) { // Double backslash
                    string = [string stringByReplacingCharactersInRange:NSMakeRange(c, 1) withString:@""];
                    stringLength = string.length;
                    c--;
                    isBackslash = NO;
                } else { // Backslash found
                    isBackslash = YES;
                }
            } else if( isBackslash )  { // Previous character is backslash
                isBackslash = NO;
                
                if( charAtIndex == 'n' ) {
                    string = [string stringByReplacingCharactersInRange:NSMakeRange(c-1, 2) withString:@"\n"];
                } else if( charAtIndex == 't' ) {
                    string = [string stringByReplacingCharactersInRange:NSMakeRange(c-1, 2) withString:@"\t"];
                } else if( charAtIndex == '\'' || charAtIndex == '\"' ) {
                    string = [string stringByReplacingCharactersInRange:NSMakeRange(c-1, 1) withString:@""];
                } else {
                    c++;
                }
                stringLength = string.length;
                c--;
            }
        }
        
        *status = (ISSParserStatus){.match = YES, .index = i};
        return string;
    } andName:[NSString stringWithFormat:@"stringWithEscapesUpToUnichar(%C)", c]];
}

+ (ISSParser*) takeUntilInSet:(NSCharacterSet*)characterSet {
    return [self takeUntilInSet:characterSet minCount:0];
}

+ (ISSParser*) takeUntilInSet:(NSCharacterSet*)characterSet minCount:(NSUInteger)minCount {
    return [self takeWhileCharMatches:^ BOOL(unichar c) {
        return ![characterSet characterIsMember:c];
    } initialCharMatcher:nil minCount:minCount skipPastEndChar:NO name:@"takeUntilInSet"];
}

+ (ISSParser*) takeWhileInSet:(NSCharacterSet*)characterSet {
    return [self takeWhileInSet:characterSet initialCharSet:nil minCount:0];
}

+ (ISSParser*) takeWhileInSet:(NSCharacterSet*)characterSet minCount:(NSUInteger)minCount {
    return [self takeWhileInSet:characterSet initialCharSet:nil minCount:minCount];
}

+ (ISSParser*) takeWhileInSet:(NSCharacterSet*)characterSet initialCharSet:(NSCharacterSet*)initialCharSet minCount:(NSUInteger)minCount {
    ISSParserMatchCondition characterSetMatcher = ^BOOL(unichar c) {
        return [characterSet characterIsMember:c];
    };
    
    if( initialCharSet ) {
        return [self takeWhileCharMatches:characterSetMatcher initialCharMatcher:^ BOOL(unichar c) {
            return [initialCharSet characterIsMember:c];
        } minCount:minCount skipPastEndChar:NO name:@"takeWhileInSet"];
    } else {
        return [self takeWhileCharMatches:characterSetMatcher initialCharMatcher:nil minCount:minCount skipPastEndChar:NO name:@"takeWhileInSet"];
    }
}

+ (ISSParser*) takeUntilChar:(unichar)character {
    return [self takeUntilChar:character andSkip:NO minCount:0];
}

+ (ISSParser*) takeUntilChar:(unichar)character andSkip:(BOOL)skip minCount:(NSUInteger)minCount {
    return [self takeWhileCharMatches:^ BOOL(unichar c) {
        return c != character;
    } initialCharMatcher:nil minCount:minCount skipPastEndChar:skip name:@"takeUntilChar"];
}

+ (ISSParser*) takeWhileCharMatches:(ISSParserMatchCondition)matcher initialCharMatcher:(ISSParserMatchCondition)initialCharMatcher minCount:(NSUInteger)minCount skipPastEndChar:(BOOL)skipPastEndChar name:(NSString*)name {
    return [ISSParser parserWithBlock:^id (NSString* input, ISSParserStatus* status) {
        NSUInteger i = status->index;
        const NSUInteger len = input.length;
        
        if( initialCharMatcher ) {
            if( i < len && initialCharMatcher([input characterAtIndex:i]) ) {
                i++;
            } else {
                return [NSNull null];
            }
        }
        
        for(; i < len; i++) {
            if( !matcher([input characterAtIndex:i]) ) {
                break;
            }
        }
        
        if( (i - status->index) >= minCount ) {
            NSString* value = [input substringWithRange:NSMakeRange(status->index, i - status->index)];
            if( skipPastEndChar ) {
                i++; // Increment past termination char
            }
            *status = (ISSParserStatus){.match = YES, .index = i};
            return value;
        } else {
            return [NSNull null];
        }
    } andName:name];
}

@end


@implementation ISSParserWrapper

- (id) parse:(NSString*)string status:(ISSParserStatus*)status {
    return [self.wrappedParser parse:string status:status];
}

@end
