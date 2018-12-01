//
//  ISSRelativeNumber.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSRelativeNumber.h"

@implementation ISSRelativeNumber {
    NSNumber* _numberValue;
}

- (instancetype) initWithNumber:(NSNumber*)number andUnit:(ISSRelativeNumberUnit)unit {
    if ( self = [super init] ) {
        _numberValue = number;
        _unit = unit;
    }
    return self;
}

- (NSNumber*) value {
    switch (self.unit) {
        case ISSRelativeNumberUnitPercent:
            return @([_numberValue doubleValue] / 100.0);
        default:
            return _numberValue;
    }
}

@end
