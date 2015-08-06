//
//  InterfaCSS
//  ISSRuntimeIntrospectionUtils.m
//  
//  Created by Tobias Löfstrand on 2014-10-22.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import "ISSRuntimeIntrospectionUtils.h"

#import "NSString+ISSStringAdditions.h"
#import <objc/runtime.h>


@implementation ISSRuntimeIntrospectionUtils

+ (SEL) findSelectorWithCaseInsensitiveName:(NSString*)name inClass:(Class)clazz {
    unsigned int c = 0;
    Method* methods = class_copyMethodList(object_getClass(clazz), &c);
    SEL sel = nil;
    for(NSUInteger i=0; i<c; i++) {
        NSString* selectorName = [[NSString alloc] initWithCString:sel_getName(method_getName(methods[i])) encoding:NSUTF8StringEncoding];
        if( [name iss_isEqualIgnoreCase:selectorName] ) {
            sel = NSSelectorFromString(selectorName);
            break;
        }
    }
    free(methods);
    return sel;
}

+ (void) invokeSingleObjectArgumentSelector:(SEL)selector inObject:(id)object parameter:(id)parameter {
    IMP imp = [object methodForSelector:selector];
    void (*func)(id, SEL, id) = (void*)imp;
    func(object, selector, parameter);
}

+ (NSSet*) propertyNamesForClass:(Class)class {
    return [NSSet setWithArray:[self propertyNamesWithClassForClass:class].allKeys];
}

+ (NSMutableDictionary*) propertyNamesWithClassForClass:(Class)class {
    if( !class || class == NSObject.class || class == [NSNull null] ) return nil;

    // Get superclass properties first
    NSMutableDictionary* propertyNamesAndClasses = [self propertyNamesWithClassForClass:[class superclass]] ?: [NSMutableDictionary dictionary];
    
    // Then add the properties of this class
    unsigned int outCount = 0;
    objc_property_t* properties = class_copyPropertyList(class, &outCount);
    for (unsigned int i=0; i<outCount; i++) {
        objc_property_t property = properties[i];
        const char* name = property_getName(property);
        if( name ) {
            NSString* propertyName = [NSString stringWithUTF8String:name];
            Class propertyClass = [self classOfProperty:property] ?: [NSNull null];
            propertyNamesAndClasses[propertyName] = propertyClass;
        }
    }
    free(properties);

    return propertyNamesAndClasses;
}

+ (Class) classOfProperty:(objc_property_t)property {
    NSString* propertyAttributesDescription = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
    NSArray* splitPropertyAttributes = [propertyAttributesDescription componentsSeparatedByString:@"\""];
    if ( [propertyAttributesDescription hasPrefix:@"T@"] && [splitPropertyAttributes count] > 1 ) {
        return NSClassFromString([splitPropertyAttributes objectAtIndex:1]);
    } else {
        return nil;
    }
}

+ (BOOL) doesClass:(Class)class havePropertyWithName:(NSString*)propertyName {
    return [[self propertyNamesForClass:class] containsObject:propertyName];
}

+ (NSArray*) actualPropertyNameAndClassForCaseInsensitiveName:(NSString*)caseInsensitivePropertyName inClass:(Class)class {
    NSMutableDictionary* propertyNamesAndClassses = [self propertyNamesWithClassForClass:class];
    for(NSString* name in propertyNamesAndClassses.allKeys) {
        if( [name iss_isEqualIgnoreCase:caseInsensitivePropertyName] ) return @[name, propertyNamesAndClassses[name]];
    }
    return nil;
}

+ (NSString*) actualPropertyNameForCaseInsensitiveName:(NSString*)caseInsensitivePropertyName inClass:(Class)class {
    return [self actualPropertyNameAndClassForCaseInsensitiveName:caseInsensitivePropertyName inClass:class][0];
}

+ (NSString*) validKeyPathForCaseInsensitivePath:(NSString*)caseInsensitiveKeyPath inClass:(Class)class {
    NSArray* keyPathComponents = [caseInsensitiveKeyPath componentsSeparatedByString:@"."];
    NSMutableArray* validatedComponents = [NSMutableArray array];
    
    for(NSString* keyPathComponent in keyPathComponents) {
        NSArray* actualPropertyNameAndClass = [self actualPropertyNameAndClassForCaseInsensitiveName:keyPathComponent inClass:class];
        if( !actualPropertyNameAndClass ) break;
        
        NSString* actualPropertyName = actualPropertyNameAndClass[0];
        class = actualPropertyNameAndClass[1];
        
        [validatedComponents addObject:actualPropertyName];
    }
    
    if( validatedComponents.count == keyPathComponents.count ) return [validatedComponents componentsJoinedByString:@"."];
    else return nil;
}

@end
