//
//  ISSRuntimeProperty.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(RuntimeProperty)
@interface ISSRuntimeProperty : NSObject

@property (nonatomic, readonly) NSString* propertyName;
@property (nonatomic, readonly) NSString* type;

@property (nonatomic, readonly, nullable) Class propertyClass;
@property (nonatomic, readonly) BOOL isNumericType;
@property (nonatomic, readonly) BOOL isBooleanType;

@property (nonatomic, readonly) Class foundInClass;

@property (nonatomic, readonly, nullable) NSString* customGetterName;
@property (nonatomic, readonly) SEL getterSelector;
@property (nonatomic, readonly) NSMethodSignature* getterMethod;
@property (nonatomic, readonly, nullable) NSString* customSetterName;
@property (nonatomic, readonly) SEL setterSelector;
@property (nonatomic, readonly) NSMethodSignature* setterMethod;


- (instancetype) initWithPropertyName:(NSString*)propertyName type:(NSString*)type getter:(nullable NSString*)customGetterName setter:(nullable  NSString*)customSetterName inClass:(Class)clazz;

- (BOOL) isType:(char*)typeName;

+ (NSString*) defaultSetterNameForProperty:(NSString*)propertyName;

@end


NS_ASSUME_NONNULL_END
