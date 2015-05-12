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
    if( !class || class == NSObject.class ) return nil;

    NSMutableSet* propertyNames = [NSMutableSet set];
    unsigned int outCount = 0;
    objc_property_t* properties = class_copyPropertyList(class, &outCount);
    for (unsigned int i=0; i<outCount; i++) {
        objc_property_t property = properties[i];
        const char* name = property_getName(property);
        if( name ) {
            [propertyNames addObject:[NSString stringWithUTF8String:name]];
        }
    }
    free(properties);

    NSSet* superClassProperties = [self propertyNamesForClass:[class superclass]];
    if( superClassProperties ) {
        return [propertyNames setByAddingObjectsFromSet:superClassProperties];
    } else {
        return propertyNames;
    }
}

+ (BOOL) doesClass:(Class)class havePropertyWithName:(NSString*)propertyName {
    return [[self propertyNamesForClass:class] containsObject:propertyName];
}

@end
