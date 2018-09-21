//
//  ISSStyleSheetContent.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@class ISSRuleset;


NS_ASSUME_NONNULL_BEGIN

typedef NSArray<ISSRuleset*> ISSRulesets;
typedef NSDictionary<NSString*, NSString*> ISSVariables;

@interface ISSStyleSheetContent : NSObject

@property (nonatomic, strong, readonly) ISSRulesets* rulesets;
@property (nonatomic, strong, readonly) ISSVariables* variables;

- (instancetype) initWithRulesets:(ISSRulesets*)rulesets variables:(ISSVariables*)variables;

- (void) setValue:(NSString*)value forStyleSheetVariableWithName:(NSString*)variableName;

@end


NS_ASSUME_NONNULL_END
