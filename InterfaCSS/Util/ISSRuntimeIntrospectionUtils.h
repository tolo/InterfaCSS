//
//  ISSRuntimeIntrospectionUtils.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>


@interface ISSRuntimeIntrospectionUtils : NSObject

+ (void) clearCaches;

+ (SEL) findSelectorWithCaseInsensitiveName:(NSString*)name inClass:(Class)clazz;

+ (void) invokeSingleObjectArgumentSelector:(SEL)selector inObject:(id)object parameter:(id)parameter;

+ (NSSet*) propertyNamesForClass:(Class)class;

+ (BOOL) doesClass:(Class)clazz havePropertyWithName:(NSString*)propertyName;

+ (BOOL) doesClassOrSuperClass:(Class)clazz havePropertyWithName:(NSString*)propertyName excludingRootClass:(Class)rootClass;

+ (NSString*) actualPropertyNameForCaseInsensitiveName:(NSString*)caseInsensitivePropertyName inClass:(Class)class;

+ (NSString*) validKeyPathForCaseInsensitivePath:(NSString*)caseInsensitiveKeyPath inClass:(Class)class;

+ (NSInvocation*) findSetterForProperty:(NSString*)propertyName inObject:(id)object;

+ (BOOL) invokeSetterForProperty:(NSString*)propertyName withValue:(id)value inObject:(id)object;

+ (id) invokeGetterForKeyPath:(NSString*)keyPath inObject:(id)object;

+ (id) invokeGetterForProperty:(NSString*)propertyName inObject:(id)object;

+ (Class) classWithName:(NSString*)className;

+ (BOOL) klaatuVerataNikto:(Class)clazz selector:(SEL)originalSelector replacement:(IMP)replacement originalPointer:(IMP*)originalPointer;

@end
