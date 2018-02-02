//
//  NSString+ISSStringAdditions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "NSString+ISSAdditions.h"

#import "ISSDateUtils.h"


@implementation NSString (ISSStringAdditions)

+ (BOOL) iss_string:(NSString*)string1 isEqualToString:(NSString*)string2 {
    return string1 == string2 || [string1 isEqualToString:string2];
}

- (BOOL) iss_isEmpty {
	return [[self iss_trim] length] == 0;
}

- (BOOL) iss_hasData {
    return ![self iss_isEmpty];
}

- (NSString*) iss_trim {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString*) iss_trimQuotes {
	return [[self iss_trim] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"\'"]];
}

- (NSArray*) iss_trimmedSplit:(NSString*)sep {
    NSMutableArray* vals = [[self componentsSeparatedByString:sep] mutableCopy];
    for (unsigned int i=0; i<vals.count; i++) {
        vals[i] = [vals[i] iss_trim];
    }
    return vals;
}

- (NSArray*) iss_trimmedSplitWithSet:(NSCharacterSet*)characterSet {
    NSMutableArray* vals = [[self componentsSeparatedByCharactersInSet:characterSet] mutableCopy];
    for (unsigned int i=0; i<vals.count; i++) {
        vals[i] = [vals[i] iss_trim];
    }
    return vals;
}

- (NSArray*) iss_splitOnSpaceOrComma {
    static NSCharacterSet* characterSet = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        characterSet = [NSCharacterSet characterSetWithCharactersInString:@" ,"];
    });
    NSArray* elements = [self componentsSeparatedByCharactersInSet:characterSet];
    NSMutableArray* result = [[NSMutableArray alloc] init];
    for (NSString* element in elements) {
        if( [element iss_hasData] ) [result addObject:element];
    }
    return result;
}

- (NSString*) iss_stringBySeparatingCamelCaseComponentsWithDash {
    NSMutableString* result = [NSMutableString stringWithString:self];
    NSCharacterSet* uppercaseLetterCharacterSet = [NSCharacterSet uppercaseLetterCharacterSet];

    NSRange range, searchRange = NSMakeRange(0, self.length);
    do {
        range = [result rangeOfCharacterFromSet:uppercaseLetterCharacterSet options:0 range:searchRange];
        if( range.location != NSNotFound ) {
            [result insertString:@"-" atIndex:range.location];
            searchRange = NSMakeRange(range.location + 2, result.length - (range.location + 2));
        }
    } while (range.location != NSNotFound);

    return [result lowercaseString];
}

- (BOOL) iss_isNumeric {
    NSRange r = [self rangeOfString:@"^(?:|0|[1-9]\\d*)(?:\\.\\d*)?$" options:NSRegularExpressionSearch];
    return r.location != NSNotFound;
}

- (BOOL) iss_isEqualIgnoreCase:(NSString*)otherString {
    return [self caseInsensitiveCompare:otherString] == NSOrderedSame;
}

+ (NSDateFormatter*) httpDateFormatterWithFormat:(NSString*)format {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = format;
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    return dateFormatter;
}

- (NSDate*) iss_parseHttpDate {
    return [ISSDateUtils parseHttpDate:self];
}


#pragma mark - Unicode support

- (NSString*) iss_stringByReplacingUnicodeSequences {
    NSUInteger location = 0;

    NSString* result = self;
    while( location < result.length ) {
        // Scan for \u or \U
        NSRange uRange = [result rangeOfString:@"\\u" options:NSCaseInsensitiveSearch range:NSMakeRange(location, result.length - location)];
        if( uRange.location != NSNotFound ) {
            // Set expected length to 4 for \u and 8 for \U
            if( [result characterAtIndex:uRange.location+1] == 'u' ) {
                uRange.length += 4;
            } else {
                uRange.length += 8;
            }

            // Attempt parsing of unicode char
            if( (uRange.location + uRange.length) <= result.length ) {
                NSString* unicodeCharString = [self iss_unicodeCharacterStringFromSequenceStringInRange:NSMakeRange(uRange.location, uRange.length)];
                if( unicodeCharString ) {
                    result = [result stringByReplacingCharactersInRange:uRange withString:unicodeCharString];
                    location = uRange.location + uRange.length;
                } else {
                    location += 2;
                }
            } else {
                location = result.length;
            }
        } else {
            location = result.length;
        }
    }

    return result;
}

- (NSString*) iss_unicodeCharacterStringFromSequenceStringInRange:(NSRange)range {
    return [[self substringWithRange:range] iss_unicodeCharacterStringFromSequenceString];
}

- (NSString*) iss_unicodeCharacterStringFromSequenceString {
    UTF32Char unicodeChar = [self iss_unicodeCharacterFromSequenceString];
    if( unicodeChar == UINT32_MAX ) return nil;
    else return [NSString iss_stringFromUTF32Char:unicodeChar];
}

- (UTF32Char) iss_unicodeCharacterFromSequenceString {
    // Remove prefix
    NSString* hexString = self;
    while( [hexString hasPrefix:@"\\"] ) hexString = [hexString substringFromIndex:1];
    if( [hexString hasPrefix:@"U"] || [hexString hasPrefix:@"u"] ) hexString = [hexString substringFromIndex:1];

    // Scan UTF32Char
    UTF32Char unicodeChar = 0;
    NSScanner* scanner = [NSScanner scannerWithString:hexString];
    if( [scanner scanHexInt:(unsigned int *)&unicodeChar] ) {
        return unicodeChar;
    } else {
        return UINT32_MAX;
    }
}

+ (NSString*) iss_stringFromUTF32Char:(UTF32Char)unicodeChar {
    if ( (unicodeChar & 0xFFFF0000) != 0 ) {
        unicodeChar -= 0x10000;
        unichar highSurrogate = (unichar)(unicodeChar >> 10); // use top ten bits
        highSurrogate += 0xD800;
        unichar lowSurrogate = (unichar)(unicodeChar & 0x3FF); // use low ten bits
        lowSurrogate += 0xDC00;
        return [NSString stringWithCharacters:(unichar[]){highSurrogate, lowSurrogate} length:2];
    } else {
        return [NSString stringWithCharacters:(unichar[]){(unichar)unicodeChar} length:1];
    }
}

@end
