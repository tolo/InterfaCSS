//
//  ISSStyleSheetPropertyParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

#import "ISSStyleSheetParser.h"
#import "ISSPropertyDefinition.h"

@class ISSParser;


NS_ASSUME_NONNULL_BEGIN


@interface ISSStyleSheetPropertyParser : NSObject <ISSStyleSheetPropertyParsingDelegate>

@property (nonatomic, weak, readonly) ISSStyleSheetParser* styleSheetParser;


- (ISSParser*) parserForPropertyType:(ISSPropertyType)propertyType;
- (void) setParser:(ISSParser*)parser forPropertyType:(ISSPropertyType)propertyType;

@end


NS_ASSUME_NONNULL_END
