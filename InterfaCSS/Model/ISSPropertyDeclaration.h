//
//  ISSPropertyDeclaration.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSLazyValue.h"

@class ISSPropertyDefinition;

@interface ISSPropertyDeclaration : NSObject<NSCopying>

@property (nonatomic, readonly) NSString* prefix;
@property (nonatomic, readonly) ISSPropertyDefinition* property;
@property (nonatomic, readonly) NSArray* parameters;
@property (nonatomic, readonly) NSString* unrecognizedName;
@property (nonatomic, strong) id propertyValue;
@property (nonatomic, copy) ISSLazyValueBlock lazyPropertyTransformationBlock;

- (instancetype) initWithProperty:(ISSPropertyDefinition*)property prefix:(NSString*)prefix;
- (instancetype) initWithProperty:(ISSPropertyDefinition*)property parameters:(NSArray*)parameters prefix:(NSString*)prefix;
- (instancetype) initWithUnrecognizedProperty:(NSString*)unrecognizedPropertyName;

- (void) transformValueIfNeeded;

- (BOOL) applyPropertyValueOnTarget:(id)target;

@end
