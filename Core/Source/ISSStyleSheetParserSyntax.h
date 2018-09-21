//
//  ISSStyleSheetParserSyntax.h
//  InterfaCSS-Core
//
//  Created by Tobias Löfstrand on 2018-09-18.
//  Copyright © 2018 Leafnode AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ISSParser;


@interface ISSStyleSheetParserSyntax : NSObject

+ (ISSStyleSheetParserSyntax*) shared;

// Common charsets
@property (nonatomic, strong, readonly) NSCharacterSet* validInitialIdentifierCharacterCharsSet;
@property (nonatomic, strong, readonly) NSCharacterSet* validIdentifierExcludingMinusCharsSet;
@property (nonatomic, strong, readonly) NSCharacterSet* validIdentifierCharsSet;
@property (nonatomic, strong, readonly) NSCharacterSet* mathExpressionCharsSet;

@end
