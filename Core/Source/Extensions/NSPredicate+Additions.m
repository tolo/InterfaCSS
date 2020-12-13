//
//  NSPredicate+NSPredicate_Additions.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "NSPredicate+Additions.h"

@implementation NSPredicate (Additions)

+ (NSNumber*) evaluatePredicateAndCatchError:(NSString*)predicateFormat {
  @try {
    NSPredicate* predicate = [NSPredicate predicateWithFormat:predicateFormat];
    return [NSNumber numberWithBool:[predicate evaluateWithObject:nil]];
  } @catch (NSException *exception) {
    return nil;
  }
}

+ (nullable NSObject*) evaluateExpressionAndCatchError:(NSString* _Nonnull)expressionFormat {
  @try {
    NSExpression* expression = [NSExpression expressionWithFormat:expressionFormat];
    return [expression expressionValueWithObject:nil context:nil];
  } @catch (NSException *exception) {
    return nil;
  }
}

@end
