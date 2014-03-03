//
//  NSString+ISStringSupport.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2010-10-27.
//  Copyright (c) 2010 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@interface NSString (ISSStringAdditions)

- (BOOL) isEmpty;
- (BOOL) hasData;

- (NSString*) trim;
- (NSString*) trimQuotes;
- (NSArray*) trimmedSplit:(NSString*)sep;
- (NSArray*) trimmedSplitWithSet:(NSCharacterSet*)characterSet;

- (NSString*) stringBySeparatingCamelCaseComponentsWithDash;

- (BOOL) isNumeric;

- (BOOL) isEqualIgnoreCase:(NSString*)otherString;

- (NSDate*) parseHttpDate;

@end
