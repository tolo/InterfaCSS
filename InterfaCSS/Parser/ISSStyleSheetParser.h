//
//  ISSStyleSheetParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-10.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@class ISSStyleSheet;

@interface ISSStyleSheetParser : NSObject

- (NSMutableArray*) parse:(NSString*)styleSheetData;

@end
