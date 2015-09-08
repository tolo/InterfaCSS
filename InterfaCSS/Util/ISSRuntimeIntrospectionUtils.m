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


static NSCache* propertyNamesWithClassForClassCache;

@implementation ISSRuntimeIntrospectionUtils

+ (void) load {
    propertyNamesWithClassForClassCache = [[NSCache alloc] init];
}

+ (void) clearCaches {
    [propertyNamesWithClassForClassCache removeAllObjects];
}

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

+ (NSDictionary*) propertyNamesWithClassForClass:(Class)class {
    if( !class || class == NSObject.class || class == [NSNull null] ) return nil;
    
    NSMutableDictionary* propertyNamesAndClasses = [propertyNamesWithClassForClassCache objectForKey:class];
    if( !propertyNamesAndClasses ) {
        // Add the properties of this class
        propertyNamesAndClasses = [NSMutableDictionary dictionary];
        unsigned int outCount = 0;
        objc_property_t* properties = class_copyPropertyList(class, &outCount);
        for (unsigned int i=0; i<outCount; i++) {
            objc_property_t property = properties[i];
            const char* name = property_getName(property);
            if( name ) {
                NSString* propertyName = [NSString stringWithUTF8String:name];
                id propertyClass = (id)[self classOfProperty:property] ?: [NSNull null];
                propertyNamesAndClasses[propertyName] = propertyClass;
            }
        }
        free(properties);

        // Add to cache
        [propertyNamesWithClassForClassCache setObject:propertyNamesAndClasses forKey:class];
    }

    // Get superclass properties
    NSDictionary* superClassPropertyNamesAndClasses = [self propertyNamesWithClassForClass:[class superclass]] ?: [NSMutableDictionary dictionary];

    // Combine super class properties with the properties of this class and return
    NSMutableDictionary* combinedPropertyNamesAndClasses = superClassPropertyNamesAndClasses ? [NSMutableDictionary dictionaryWithDictionary:superClassPropertyNamesAndClasses] : [NSMutableDictionary dictionary];
    [combinedPropertyNamesAndClasses addEntriesFromDictionary:propertyNamesAndClasses];

    return combinedPropertyNamesAndClasses;
}

+ (Class) classOfProperty:(objc_property_t)property {
    NSString* propertyAttributesDescription = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
    NSArray* splitPropertyAttributes = [propertyAttributesDescription componentsSeparatedByString:@"\""];
    if ( [propertyAttributesDescription hasPrefix:@"T@"] && [splitPropertyAttributes count] > 1 ) {
        return [self classWithName:splitPropertyAttributes[1]];
    } else {
        return nil;
    }
}

+ (NSString*) customSetterMethodForProperty:(objc_property_t)property {
    NSString* propertyAttributesDescription = [NSString stringWithCString:property_getAttributes(property) encoding:NSUTF8StringEncoding];
    NSRange range = [propertyAttributesDescription rangeOfString:@",S"];
    if( range.location != NSNotFound ) {
        NSInteger setterBeginIndex = range.location + range.length;
        NSRange searchRange = NSMakeRange(setterBeginIndex, propertyAttributesDescription.length - setterBeginIndex);
        NSRange nextCommaRange = [propertyAttributesDescription rangeOfString:@"," options:0 range:searchRange];
        if ( nextCommaRange.location != NSNotFound ) return [propertyAttributesDescription substringWithRange:NSMakeRange(setterBeginIndex, nextCommaRange.location - setterBeginIndex)];
        else return [propertyAttributesDescription substringWithRange:searchRange];
    }
    return nil;
}

+ (BOOL) doesClass:(Class)class havePropertyWithName:(NSString*)propertyName {
    return [[self propertyNamesForClass:class] containsObject:propertyName];
}

+ (NSArray*) actualPropertyNameAndClassForCaseInsensitiveName:(NSString*)caseInsensitivePropertyName inClass:(Class)class {
    NSDictionary* propertyNamesAndClasses = [self propertyNamesWithClassForClass:class];
    for(NSString* name in propertyNamesAndClasses.allKeys) {
        if( [name iss_isEqualIgnoreCase:caseInsensitivePropertyName] ) return @[name, propertyNamesAndClasses[name]];
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

+ (NSInvocation*) findSetterForProperty:(NSString*)propertyName inObject:(id)object {
    if( !object || ![propertyName iss_hasData] ) return nil;
    
    objc_property_t property = class_getProperty([object class], [propertyName cStringUsingEncoding:NSUTF8StringEncoding]);
    NSString* setter = nil;
    if( property ) {
        setter = [self customSetterMethodForProperty:property];
    }
    if( !setter ) {
        if( propertyName.length > 1 ) {
            setter = [NSString stringWithFormat:@"set%@%@:", [[propertyName substringToIndex:1] uppercaseString], [propertyName substringFromIndex:1]];
        } else {
            setter = [NSString stringWithFormat:@"set%@:", [[propertyName substringToIndex:1] uppercaseString]];
        }
    }
    
    if ( setter ) {
        // TODO: Consider adding some caching...
        SEL selector = NSSelectorFromString(setter);
        NSMethodSignature* signature = [[object class] instanceMethodSignatureForSelector:selector];
        if( signature ) {
            NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setTarget:object];
            [invocation setSelector:selector];
            return invocation;
        }
    }
    return nil;
}

+ (BOOL) invokeSetterForProperty:(NSString*)propertyName withValue:(id)value inObject:(id)object {
    NSInvocation* invocation = [self findSetterForProperty:propertyName inObject:object];
    const char* argType = [invocation.methodSignature getArgumentTypeAtIndex:2];
    
    void* argValue = nil;
    
    if( *argType == *@encode(id) ) {
        argValue = (__bridge void *)(value);
    }
    else if( *argType == *@encode(char) ) {
        char v = [value charValue];
        argValue = &v;
    }
    else if( *argType == *@encode(short) ) {
        short v = [value shortValue];
        argValue = &v;
    }
    else if( *argType == *@encode(int) ) {
        int v = [value intValue];
        argValue = &v;
    }
    else if( *argType == *@encode(long) ) {
        long v = [value longValue];
        argValue = &v;
    }
    else if( *argType == *@encode(long long) ) {
        long long v = [value longLongValue];
        argValue = &v;
    }
    else if( *argType == *@encode(unsigned char) ) {
        unsigned char v = [value unsignedCharValue];
        argValue = &v;
    }
    else if( *argType == *@encode(unsigned short) ) {
        unsigned short v = [value unsignedShortValue];
        argValue = &v;
    }
    else if( *argType == *@encode(unsigned int) ) {
        unsigned int v = [value unsignedIntValue];
        argValue = &v;
    }
    else if( *argType == *@encode(unsigned long) ) {
        unsigned long v = [value unsignedLongValue];
        argValue = &v;
    }
    else if( *argType == *@encode(unsigned long long) ) {
        unsigned long long v = [value unsignedLongLongValue];
        argValue = &v;
    }
    else if( *argType == *@encode(float) ) {
        float v = [value floatValue];
        argValue = &v;
    }
    else if( *argType == *@encode(double) ) {
        double v = [value doubleValue];
        argValue = &v;
    }
    else if( *argType == *@encode(BOOL) ) {
        BOOL v = [value boolValue];
        argValue = &v;
    }
    
    if( argValue ) {
        [invocation setArgument:argValue atIndex:2];
        
        [invocation invoke];
        
        return YES;
    } else {
        return NO;
    }
}

+ (Class) classWithName:(NSString*)className {
    Class clazz = NSClassFromString(className);
    if( !clazz ) { // If direct match not found, check if it's a Swift class name
        NSString* appName = [[[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleNameKey] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
        clazz = NSClassFromString([NSString stringWithFormat:@"%@.%@", appName, className]);
    }
    return clazz;
}

+ (BOOL) klaatuVerataNikto:(Class)clazz selector:(SEL)originalSelector replacement:(IMP)replacement originalPointer:(IMP*)originalPointer {
    if( !originalPointer || !replacement ) return NO;
    
    Method originalMethod = class_getInstanceMethod(clazz, originalSelector);
    IMP originalMethodImpl = nil;
    if( originalMethod ) {
        const char* methodTypes = method_getTypeEncoding(originalMethod);
        originalMethodImpl = class_replaceMethod(clazz, originalSelector, replacement, methodTypes);
        if( !originalMethodImpl ) {
            originalMethodImpl = method_getImplementation(originalMethod);
        }
    }
    
    if( originalMethodImpl ) *originalPointer = originalMethodImpl;
    
    return originalMethodImpl != nil;
}

@end
