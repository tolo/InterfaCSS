//
//  ISSDateUtils.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSDateUtils.h"


static NSDateFormatter* rfc1123DateFormatter = nil;
static NSDateFormatter* rfc850DateFormatter = nil;
static NSDateFormatter* asctimeFormatter = nil;


@implementation ISSDateUtils

+ (NSDateFormatter*) httpDateFormatterWithFormat:(NSString*)format {
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = format;
    dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
    return dateFormatter;
}

+ (NSDate*) parseHttpDate:(NSString*)string {
    NSDate* date = nil;

    static dispatch_once_t rfc1123DateFormatterOnceToken;
    dispatch_once(&rfc1123DateFormatterOnceToken, ^{
        rfc1123DateFormatter = [self httpDateFormatterWithFormat:@"EEE',' dd MMM yyyy HH':'mm':'ss z"];
    });
    date = [rfc1123DateFormatter dateFromString:string];

    if ( !date ) {
        static dispatch_once_t rfc850DateFormatterOnceToken;
        dispatch_once(&rfc850DateFormatterOnceToken, ^{
            rfc850DateFormatter = [self httpDateFormatterWithFormat:@"EEEE',' dd'-'MMM'-'yy HH':'mm':'ss z"];
        });
        date = [rfc850DateFormatter dateFromString:string];

        if ( !date ) {
            static dispatch_once_t asctimeFormatterOnceToken;
            dispatch_once(&asctimeFormatterOnceToken, ^{
                asctimeFormatter = [self httpDateFormatterWithFormat:@"EEE MMM d HH':'mm':'ss yyyy"];
            });
            date = [asctimeFormatter dateFromString:string];
        }
    }

    return date;
}

+ (NSString*) formatHttpDate:(NSDate*)date {
    if ( !rfc1123DateFormatter ) rfc1123DateFormatter = [self httpDateFormatterWithFormat:@"EEE',' dd MMM yyyy HH':'mm':'ss z"];
    return [rfc1123DateFormatter stringFromDate:date];
}

@end