//
//  NSPredicate+NSPredicate_Additions.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

@interface NSPredicate (Additions)

+ (nullable NSNumber*) evaluatePredicateAndCatchError:(NSString* _Nonnull)predicateFormat;

+ (nullable NSObject*) evaluateExpressionAndCatchError:(NSString* _Nonnull)predicateFormat;

@end
