//
//  ISSRuntimeIntrospectionUtils.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <Foundation/Foundation.h>

@class ISSRuntimeProperty;


NS_ASSUME_NONNULL_BEGIN


NS_SWIFT_NAME(PropertySetterInvocationValueBlock)
typedef id _Nonnull (^ISSPropertySetterInvocationValueBlock)(ISSRuntimeProperty* _Nonnull propertyDetails);

extern char* const ISSCGColorTypeId;
extern char* const ISSCGRectTypeId;
extern char* const ISSCGPointTypeId;
extern char* const ISSUIEdgeInsetsTypeId;
extern char* const ISSUIOffsetTypeId;
extern char* const ISSCGSizeTypeId;
extern char* const ISSCGAffineTransformTypeId;

NS_SWIFT_NAME(RuntimeIntrospectionUtils)
@interface ISSRuntimeIntrospectionUtils : NSObject

+ (void) clearCaches;

+ (Class _Nullable) classWithName:(NSString*)className;

+ (nullable SEL) findSelectorWithCaseInsensitiveName:(NSString*)name inClass:(Class)clazz;

+ (void) invokeSingleObjectArgumentSelector:(SEL)selector inObject:(id)object parameter:(id)parameter;


+ (NSSet<NSString*>*) propertyNamesForClass:(Class)class;

+ (NSSet<NSString*>*) propertyNamesForClass:(Class)clazz lowercased:(BOOL)lowercased;

+ (ISSRuntimeProperty* _Nullable) runtimePropertyWithName:(NSString*)name inClass:(Class)clazz lowercasedNames:(BOOL)lowercasedNames;

+ (NSDictionary<NSString*, ISSRuntimeProperty*>*) runtimePropertiesForClass:(Class)clazz lowercasedNames:(BOOL)lowercasedNames;

+ (NSDictionary<NSString*, ISSRuntimeProperty*>*) runtimePropertiesForClass:(Class)clazz excludingRootClasses:(NSArray<Class>*)rootClasses lowercasedNames:(BOOL)lowercasedNames;

+ (Class _Nullable) classFromTypeAttribute:(NSString*)typeAttribute;


+ (BOOL) doesClass:(Class)clazz havePropertyWithName:(NSString*)propertyName;

+ (NSString* _Nullable) actualPropertyNameForCaseInsensitiveName:(NSString*)caseInsensitivePropertyName inClass:(Class)class;

+ (NSString* _Nullable) validKeyPathForCaseInsensitivePath:(NSString*)caseInsensitiveKeyPath inClass:(Class)class;


+ (BOOL) invokeSetterForKeyPath:(NSString*)keyPath ignoringCase:(BOOL)ignoringCase withValue:(id)value inObject:(id)object;

+ (BOOL) invokeSetterForProperty:(NSString*)propertyName ignoringCase:(BOOL)ignoringCase withValue:(id)value inObject:(id)object;

+ (BOOL) invokeSetterForRuntimeProperty:(ISSRuntimeProperty*)propertyDetails withValue:(id)value inObject:(id)object;

+ (id _Nullable) invokeGetterForKeyPath:(NSString*)keyPath ignoringCase:(BOOL)ignoringCase inObject:(id)object;

+ (id _Nullable) invokeGetterForProperty:(NSString*)propertyName ignoringCase:(BOOL)ignoringCase inObject:(id)object;

+ (id _Nullable) invokeInstanceSelector:(SEL)selector withArguments:(NSArray*)arguments inObject:(id)object;

@end


NS_ASSUME_NONNULL_END
