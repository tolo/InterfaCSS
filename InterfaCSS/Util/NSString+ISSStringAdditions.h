//
//  NSString+ISStringSupport.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2010-10-27.
//  Copyright (c) 2010 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@interface NSString (ISSStringAdditions)

+ (BOOL) iss_string:(NSString*)string1 isEqualToString:(NSString*)string2;

- (BOOL) iss_isEmpty;
- (BOOL) iss_hasData;

- (NSString*) iss_trim;
- (NSString*) iss_trimQuotes;
- (NSArray*) iss_trimmedSplit:(NSString*)sep;
- (NSArray*) iss_trimmedSplitWithSet:(NSCharacterSet*)characterSet;

- (NSString*) iss_stringBySeparatingCamelCaseComponentsWithDash;

- (BOOL) iss_isNumeric;

- (BOOL) iss_isEqualIgnoreCase:(NSString*)otherString;

- (NSDate*) iss_parseHttpDate;

@end
