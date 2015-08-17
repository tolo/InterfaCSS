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

extern NSObject* const ISSPropertyDefinitionUseCurrentValue;


/**
 * Represents the declaration of a property in a stylesheet, along with the declared value.
 */
@interface ISSPropertyDeclaration : NSObject<NSCopying>

@property (nonatomic, readonly) NSString* nestedElementKeyPath;
@property (nonatomic, readonly) ISSPropertyDefinition* property;
@property (nonatomic, readonly) NSArray* parameters;
@property (nonatomic, readonly) NSString* unrecognizedName;
@property (nonatomic, strong) id propertyValue;
@property (nonatomic, copy) ISSLazyValueBlock lazyPropertyTransformationBlock;
@property (nonatomic, readonly) BOOL dynamicValue; // Indicates weather the value of this property may be dynamic, i.e. may need to be re-evaluated every time styles are applied

- (instancetype) initWithProperty:(ISSPropertyDefinition*)property nestedElementKeyPath:(NSString*)nestedElementKeyPath;
- (instancetype) initWithProperty:(ISSPropertyDefinition*)property parameters:(NSArray*)parameters nestedElementKeyPath:(NSString*)nestedElementKeyPath;
- (instancetype) initWithUnrecognizedProperty:(NSString*)unrecognizedPropertyName;

- (BOOL) transformValueIfNeeded;

- (BOOL) applyPropertyValueOnTarget:(id)target;

@end
