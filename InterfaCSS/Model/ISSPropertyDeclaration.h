//
//  ISSPropertyDeclaration.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSLazyValue.h"

NS_ASSUME_NONNULL_BEGIN


@class ISSPropertyDefinition, ISSUIElementDetails;

extern NSObject* const ISSPropertyDefinitionUseCurrentValue;


/**
 * Represents the declaration of a property in a stylesheet, along with the declared value.
 */
@interface ISSPropertyDeclaration : NSObject<NSCopying>

@property (nonatomic, readonly, nullable) NSString* nestedElementKeyPath;
@property (nonatomic, readonly) ISSPropertyDefinition* property;
@property (nonatomic, readonly, nullable) NSArray* parameters;
@property (nonatomic, readonly, nullable) NSString* unrecognizedName;
@property (nonatomic, strong, nullable) id propertyValue;
@property (nonatomic, copy, nullable) ISSLazyValueBlock lazyPropertyTransformationBlock;
@property (nonatomic, readonly) BOOL dynamicValue; // Indicates weather the value of this property may be dynamic, i.e. may need to be re-evaluated every time styles are applied

- (instancetype) initWithProperty:(ISSPropertyDefinition*)property nestedElementKeyPath:(nullable NSString*)nestedElementKeyPath;
- (instancetype) initWithProperty:(ISSPropertyDefinition*)property parameters:(nullable NSArray*)parameters nestedElementKeyPath:(nullable NSString*)nestedElementKeyPath;
- (instancetype) initWithUnrecognizedProperty:(NSString*)unrecognizedPropertyName;

- (BOOL) transformValueIfNeeded;

- (BOOL) applyPropertyValueOnTarget:(ISSUIElementDetails*)targetDetails;

@end


NS_ASSUME_NONNULL_END
