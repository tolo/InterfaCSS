//
//  ISSStyleSheetParser+Protected.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSStyleSheetParser.h"

@class ISSParser, ISSSelectorChain;


NS_ASSUME_NONNULL_BEGIN


extern NSArray* iss_nonNullElementArray(NSArray* array);
extern id iss_elementOrNil(NSArray* array, NSUInteger index);
extern id iss_elementOfTypeOrNil(NSArray* array, NSUInteger index, Class clazz);
extern float iss_floatAt(NSArray* array, NSUInteger index);


/**
 * Placeholder for bad data, to support better error feedback.
 */
@interface ISSStyleSheetParserBadData : NSObject

@property (nonatomic, strong) NSString* badDataDescription;

+ (instancetype) badDataWithDescription:(NSString*)badDataDescription;

@end


/**
 * Internal placeholder class to reference a declaration that is to be extended.
 */
@interface ISSDeclarationExtension: NSObject

@property (nonatomic, strong, readonly) ISSSelectorChain* extendedDeclaration;

+ (instancetype) extensionOfDeclaration:(ISSSelectorChain*)extendedDeclaration;

@end


/**
 * Internal ruleset declaration wrapper class, to keep track of property ordering and of nested declarations
 */
@interface ISSRulesetDeclaration : NSObject<NSCopying>

@property (nonatomic, strong, readonly) NSMutableArray* chains;
@property (nonatomic, readonly, nullable) NSString* nestedElementKeyPath;

@property (nonatomic, strong) NSMutableArray* properties;

+ (instancetype) rulesetWithSelectorChains:(NSMutableArray*)chains;
+ (instancetype) rulesetWithSelectorChains:(NSMutableArray*)chains nestedElementKeyPath:(NSString* _Nullable)nestedElementKeyPath;

@end


/**
 * ISSStyleSheetParser
 */
@interface ISSStyleSheetParser ()

// Common charsets
@property (nonatomic, strong, readonly) NSCharacterSet* validInitialIdentifierCharacterCharsSet;
@property (nonatomic, strong, readonly) NSCharacterSet* validIdentifierExcludingMinusCharsSet;
@property (nonatomic, strong, readonly) NSCharacterSet* validIdentifierCharsSet;
@property (nonatomic, strong, readonly) NSCharacterSet* mathExpressionCharsSet;

// Common parsers
@property (nonatomic, strong, readonly) ISSParser* dot;
@property (nonatomic, strong, readonly) ISSParser* hashSymbol;
@property (nonatomic, strong, readonly) ISSParser* comma;
@property (nonatomic, strong, readonly) ISSParser* openBraceSkipSpace;
@property (nonatomic, strong, readonly) ISSParser* closeBraceSkipSpace;
@property (nonatomic, strong, readonly) ISSParser* identifier;
@property (nonatomic, strong, readonly) ISSParser* anyName;
@property (nonatomic, strong, readonly) ISSParser* anythingButControlChars;
@property (nonatomic, strong, readonly) ISSParser* plainNumber;
@property (nonatomic, strong, readonly) ISSParser* numberValue;
@property (nonatomic, strong, readonly) ISSParser* numberOrExpressionValue;
@property (nonatomic, strong, readonly) ISSParser* quotedString;
@property (nonatomic, strong, readonly) ISSParser* quotedIdentifier;

//@property (nonatomic, strong, readonly) ISSStyleSheetPropertyParser* propertyParser;


//- (ISSPropertyValue*) transformPropertyPair:(NSArray*)propertyPair;

@end


NS_ASSUME_NONNULL_END

