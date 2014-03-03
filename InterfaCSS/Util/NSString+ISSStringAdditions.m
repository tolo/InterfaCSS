//
//  NSString+ISStringSupport.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2010-10-27.
//  Copyright (c) 2010 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "NSString+ISSStringAdditions.h"

#import "ISSDateUtils.h"


@implementation NSString (ISSStringAdditions)

- (BOOL) isEmpty {
	return [[self trim] length] == 0;
}

- (BOOL) hasData {
    return ![self isEmpty];
}

- (NSString*) trim {
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString*) trimQuotes {
	return [[self trim] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\"\'"]];
}

- (NSArray*) trimmedSplit:(NSString*)sep {
    NSMutableArray* vals = [[self componentsSeparatedByString:sep] mutableCopy];
    for (unsigned int i=0; i<vals.count; i++) {
        vals[i] = [vals[i] trim];
    }
    return vals;
}

- (NSArray*) trimmedSplitWithSet:(NSCharacterSet*)characterSet {
    NSMutableArray* vals = [[self componentsSeparatedByCharactersInSet:characterSet] mutableCopy];
    for (unsigned int i=0; i<vals.count; i++) {
        vals[i] = [vals[i] trim];
    }
    return vals;
}

- (NSString*) stringBySeparatingCamelCaseComponentsWithDash {
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

- (BOOL) isNumeric {
    NSRange r = [self rangeOfString:@"^(?:|0|[1-9]\\d+)(?:\\.\\d*)?$" options:NSRegularExpressionSearch];
    return r.location != NSNotFound;
}

- (BOOL) isEqualIgnoreCase:(NSString*)otherString {
    return [self caseInsensitiveCompare:otherString] == NSOrderedSame;
}

+ (NSDateFormatter*) httpDateFormatterWithFormat:(NSString*)format {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = format;
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    return dateFormatter;
}

- (NSDate*) parseHttpDate {
    return [ISSDateUtils parseHttpDate:self];
}

@end
