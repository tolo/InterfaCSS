//
//  ISSParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//  Inspired by Parcoa (https://github.com/brotchie/Parcoa).
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN


#define ISSParserSkipSpaceAndNewLines(input) while( i < input.length && [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[input characterAtIndex:i]] ) i++;


typedef struct ISSParserStatus {
    BOOL match;
    NSUInteger index;
    void* _Nullable context;
} ISSParserStatus;


typedef id _Nonnull (^ISSParserBlock)(NSString* input, ISSParserStatus* status);
typedef BOOL (^ISSParserMatchCondition)(unichar c);
typedef id _Nonnull (^ISSParserTransformerBlock)(id value, void* context);


/**
 * A simple and generic parser builder that uses an API similar to that of the Parcoa parser, but with a different and more performance focused implementation.
 */
@interface ISSParser : NSObject

+ (ISSParser*) parserWithBlock:(ISSParserBlock)block andName:(NSString*)name;

- (id) parse:(NSString*)string status:(ISSParserStatus*)status;


#pragma mark - Combinators

+ (ISSParser*) choice:(NSArray*)parsers;
- (ISSParser*) parserOr:(ISSParser*)parser;

+ (ISSParser*) sequential:(NSArray*)parsers;

+ (ISSParser*) optional:(ISSParser*)parser;
+ (ISSParser*) optional:(ISSParser*)parser defaultValue:(id)defaultValue;

- (ISSParser*) then:(ISSParser*)parser;

- (ISSParser*) keepLeft:(ISSParser*)parser;

- (ISSParser*) keepRight:(ISSParser*)parser;

- (ISSParser*) between:(ISSParser*)left and:(ISSParser*)right;

- (ISSParser*) many;
- (ISSParser*) many1;
- (ISSParser*) manyActualValues;
- (ISSParser*) manyActualValuesFlat;
- (ISSParser*) many1ActualValues;
- (ISSParser*) many1ActualValuesFlat;

- (ISSParser*) sepBy:(ISSParser*)delimiterParser;
- (ISSParser*) sepBy1:(ISSParser*)delimiterParser;
- (ISSParser*) sepByKeep:(ISSParser*)delimiterParser;
- (ISSParser*) sepBy1Keep:(ISSParser*)delimiterParser;

- (ISSParser*) concat:(NSString*)separator;
- (ISSParser*) concat;
- (ISSParser*) concatMany;
- (ISSParser*) concatMany1;

- (ISSParser*) beforeEOI;
+ (ISSParser*) endOfInput;


#pragma mark - Transform

- (ISSParser*) transform:(ISSParserTransformerBlock)transformer;
- (ISSParser*) transform:(ISSParserTransformerBlock)transformer name:(NSString*)name;


#pragma mark - Matchers

+ (ISSParser*) unichar:(unichar)c;
+ (ISSParser*) unichar:(unichar)c skipSpaces:(BOOL)skipSpaces;

+ (ISSParser*) charInSet:(NSCharacterSet*)set;
+ (ISSParser*) charInSet:(NSCharacterSet*)set skipSpaces:(BOOL)skipSpaces;

+ (ISSParser*) stringEQIgnoringCase:(NSString*)matcherString;

+ (ISSParser*) space;
+ (ISSParser*) spaces;
+ (ISSParser*) spaces:(NSUInteger)minCount;
- (ISSParser*) skipSurroundingSpaces;

+ (ISSParser*) digit;

+ (ISSParser*) charMatching:(ISSParserMatchCondition)matcher skipSpaces:(BOOL)skipSpaces name:(NSString*)name;


#pragma mark - Extractors

+ (ISSParser*) stringWithEscapesUpToUnichar:(unichar)c;

+ (ISSParser*) takeUntilInSet:(NSCharacterSet*)characterSet;
+ (ISSParser*) takeUntilInSet:(NSCharacterSet*)characterSet minCount:(NSUInteger)minCount;

+ (ISSParser*) takeWhileInSet:(NSCharacterSet*)characterSet;
+ (ISSParser*) takeWhileInSet:(NSCharacterSet*)characterSet minCount:(NSUInteger)minCount;
+ (ISSParser*) takeWhileInSet:(NSCharacterSet*)characterSet initialCharSet:(nullable NSCharacterSet*)initialCharSet minCount:(NSUInteger)minCount;

+ (ISSParser*) takeUntilChar:(unichar)character;
+ (ISSParser*) takeUntilChar:(unichar)character andSkip:(BOOL)skip minCount:(NSUInteger)minCount;

+ (ISSParser*) takeWhileCharMatches:(ISSParserMatchCondition)matcher initialCharMatcher:(nullable ISSParserMatchCondition)initialCharMatcher minCount:(NSUInteger)minCount skipPastEndChar:(BOOL)skipPastEndChar name:(NSString*)name;

@end


@interface ISSParserWrapper : ISSParser
@property (nonatomic, strong) ISSParser* wrappedParser;
@end


NS_ASSUME_NONNULL_END
