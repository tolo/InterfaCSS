//
//  ISSStyleSheetParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

#import "ISSProperty.h"

@class ISSParser, ISSStyleSheetManager, ISSStyleSheetParser, ISSStyleSheetContent;


NS_ASSUME_NONNULL_BEGIN


@protocol ISSStyleSheetPropertyParsingDelegate

- (void) setupPropertyParsersWith:(ISSStyleSheetParser*)styleSheetParser;
- (nullable id) parsePropertyValue:(NSString*)propertyValue ofType:(ISSPropertyType)type;

@end

@protocol ISSStyleSheetParserType
@end

@interface ISSStyleSheetParser : NSObject<ISSStyleSheetParserType>

@property (nonatomic, weak) ISSStyleSheetManager* styleSheetManager;

@property (nonatomic, strong, readonly) id<ISSStyleSheetPropertyParsingDelegate> propertyParser;

- (instancetype) init;
- (instancetype) initWithPropertyParser:(nullable id<ISSStyleSheetPropertyParsingDelegate>)propertyParser NS_DESIGNATED_INITIALIZER;


/**
 * Parses the specified stylesheet data into an array of `ISSRuleset` objects.
 */
- (nullable ISSStyleSheetContent*) parse:(NSString*)styleSheetData; // TODO: Async

/**
 * Parses a property value of the specified type from a string. Any variable references in `value` will be replaced with their corresponding values.
 */
- (nullable id) parsePropertyValue:(NSString*)propertyValue asType:(ISSPropertyType)type;

@end


NS_ASSUME_NONNULL_END
