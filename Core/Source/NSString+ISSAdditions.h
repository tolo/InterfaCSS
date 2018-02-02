//
//  NSString+ISSStringAdditions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@interface NSString (ISSStringAdditions)

+ (BOOL) iss_string:(NSString*)string1 isEqualToString:(NSString*)string2;

- (BOOL) iss_isEmpty;
- (BOOL) iss_hasData;

- (NSString*) iss_trim;
- (NSString*) iss_trimQuotes;
- (NSArray*) iss_trimmedSplit:(NSString*)sep;
- (NSArray*) iss_trimmedSplitWithSet:(NSCharacterSet*)characterSet;
- (NSArray*) iss_splitOnSpaceOrComma;

- (NSString*) iss_stringBySeparatingCamelCaseComponentsWithDash;

- (BOOL) iss_isNumeric;

- (BOOL) iss_isEqualIgnoreCase:(NSString*)otherString;

- (NSDate*) iss_parseHttpDate;


- (NSString*) iss_stringByReplacingUnicodeSequences;
- (NSString*) iss_unicodeCharacterStringFromSequenceString;
- (UTF32Char) iss_unicodeCharacterFromSequenceString;
+ (NSString*) iss_stringFromUTF32Char:(UTF32Char)unicodeChar;

@end
