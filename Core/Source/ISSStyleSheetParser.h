//
//  ISSStyleSheetParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

#import "ISSPropertyDefinition.h"

@class ISSParser, ISSStyleSheetManager, ISSStyleSheetParser;


NS_ASSUME_NONNULL_BEGIN


@protocol ISSStyleSheetPropertyParsingDelegate

- (void) setupPropertyParsersWith:(ISSStyleSheetParser*)styleSheetParser;
- (nullable id) parsePropertyValue:(NSString*)propertyValue ofType:(ISSPropertyType)type;

@end


@interface ISSStyleSheetParser : NSObject

@property (nonatomic, weak) ISSStyleSheetManager* styleSheetManager;

@property (nonatomic, strong, readonly) id<ISSStyleSheetPropertyParsingDelegate> propertyParser;

- (instancetype) init;
- (instancetype) initWithPropertyParser:(nullable id<ISSStyleSheetPropertyParsingDelegate>)propertyParser NS_DESIGNATED_INITIALIZER;


/**
 * Parses the specified stylesheet data into an array of `ISSPropertyDeclarations` objects.
 */
- (nullable NSMutableArray*) parse:(NSString*)styleSheetData;

/**
 * Parses a property value of the specified type from a string. Any variable references in `value` will be replaced with their corresponding values.
 */
- (nullable id) parsePropertyValue:(NSString*)propertyValue asType:(ISSPropertyType)type;

/**
 * Parses a property value of the specified type from a string. Optionally replaces variable references in `value` with the corresponding values.
 */
- (nullable id) parsePropertyValue:(NSString*)propertyValue asType:(ISSPropertyType)type replaceVariableReferences:(BOOL)replaceVariableReferences;


@end


NS_ASSUME_NONNULL_END
