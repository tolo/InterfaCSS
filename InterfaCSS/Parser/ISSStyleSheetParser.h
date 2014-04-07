//
//  ISSStyleSheetParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-10.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPropertyDefinition.h"

@class ISSStyleSheet;
@class ISSPropertyDefinition;

@protocol ISSStyleSheetParser <NSObject>

- (NSMutableArray*) parse:(NSString*)styleSheetData;

- (id) transformValue:(NSString*)value asPropertyType:(ISSPropertyType)propertyType;

- (id) transformValue:(NSString*)value forPropertyDefinition:(ISSPropertyDefinition*)propertyDefinition;

@end
