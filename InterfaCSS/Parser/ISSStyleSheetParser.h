//
//  ISSStyleSheetParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPropertyDefinition.h"

NS_ASSUME_NONNULL_BEGIN


@class ISSStyleSheet;
@class ISSPropertyDefinition;

/**
 * Protocol for stylesheet parser implementations.
 */
@protocol ISSStyleSheetParser <NSObject>

/**
 * Parses the specified stylesheet data into an array of `ISSPropertyDeclarations` objects.
 */
- (nullable NSMutableArray*) parse:(NSString*)styleSheetData;

/**
 * Transforms the specified value, using the specified propertyType. Any variable references in `value` will be replaced with their corresponding values.
 */
- (nullable id) transformValue:(NSString*)value asPropertyType:(ISSPropertyType)propertyType;

/**
 * Transforms the specified value, using the specified propertyType. Optionally replaces variable references in `value` with the corresponding values.
 */
- (nullable id) transformValue:(NSString*)value asPropertyType:(ISSPropertyType)propertyType replaceVariableReferences:(BOOL)replaceVariableReferences;

/**
 * Transforms the specified value, using the specified propertyDefinition. Any variable references in `value` will be replaced with their corresponding values.
 */
- (nullable id) transformValue:(NSString*)value forPropertyDefinition:(ISSPropertyDefinition*)propertyDefinition;

/**
 * Transforms the specified value, using the specified propertyDefinition. Optionally replaces variable references in `value` with the corresponding values.
 */
- (nullable id) transformValue:(NSString*)value forPropertyDefinition:(ISSPropertyDefinition*)propertyDefinition replaceVariableReferences:(BOOL)replaceVariableReferences;

@end


NS_ASSUME_NONNULL_END
