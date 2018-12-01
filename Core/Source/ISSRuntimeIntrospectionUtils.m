//
//  ISSRuntimeIntrospectionUtils.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import <objc/runtime.h>
#import <UIKit/UIKit.h>

#import "ISSRuntimeIntrospectionUtils.h"

#import "ISSRuntimeProperty.h"

#import "NSString+ISSAdditions.h"



static NSCache* propertyNamesWithClassForClassCache;
static NSCache* lowercasePropertyNamesWithClassForClassCache;


@implementation ISSRuntimeIntrospectionUtils

+ (void) load {
    propertyNamesWithClassForClassCache = [[NSCache alloc] init];
    lowercasePropertyNamesWithClassForClassCache = [[NSCache alloc] init];
}

+ (void) clearCaches {
    [propertyNamesWithClassForClassCache removeAllObjects];
    [lowercasePropertyNamesWithClassForClassCache removeAllObjects];
}

+ (SEL) findSelectorWithCaseInsensitiveName:(NSString*)name inClass:(Class)clazz {
    // TODO: Consider caching
    unsigned int c = 0;
    Method* methods = class_copyMethodList(object_getClass(clazz), &c);
    SEL sel = nil;
    for(NSUInteger i=0; i<c; i++) {
        //NSString* selectorName = [[NSString alloc] initWithCString:sel_getName(method_getName(methods[i])) encoding:NSUTF8StringEncoding];
        NSString* selectorName = [NSString stringWithUTF8String:sel_getName(method_getName(methods[i]))];
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

+ (NSString*) propertyAttributeToString:(objc_property_t)property attribute:(char*)attribute {
    char* attributeValue = property_copyAttributeValue(property, attribute);
    if (attributeValue != nil) {
        //NSString* valueString = [[NSString alloc] initWithCString:attributeValue encoding:NSUTF8StringEncoding];
        NSString* valueString = [NSString stringWithUTF8String:attributeValue];
        free(attributeValue);
        return valueString;
    }
    return nil;
}

+ (NSSet*) propertyNamesForClass:(Class)clazz {
    return [self propertyNamesForClass:clazz lowercased:NO];
}

+ (NSSet*) propertyNamesForClass:(Class)clazz lowercased:(BOOL)lowercased {
    return [NSSet setWithArray:[self runtimePropertiesForClass:clazz lowercasedNames:lowercased].allKeys];
}

+ (ISSRuntimeProperty*) runtimePropertyWithName:(NSString*)name inClass:(Class)clazz lowercasedNames:(BOOL)lowercasedNames {
    NSString* effectiveName = lowercasedNames ? [name lowercaseString] : name;
    return [self runtimePropertiesForClass:clazz excludingRootClasses:[NSSet setWithArray:@[UIResponder.class, NSObject.class]] lowercasedNames:lowercasedNames][effectiveName];
}

+ (NSDictionary*) runtimePropertiesForClass:(Class)clazz lowercasedNames:(BOOL)lowercasedNames {
    return [self runtimePropertiesForClass:clazz excludingRootClasses:[NSSet setWithArray:@[UIResponder.class, NSObject.class]] lowercasedNames:lowercasedNames];
}

+ (NSDictionary*) runtimePropertiesForClass:(Class)clazz excludingRootClasses:(NSSet*)rootClasses lowercasedNames:(BOOL)lowercasedNames {
    if( !clazz || [rootClasses containsObject:clazz] || clazz == [NSNull null] ) return nil;
    
    NSDictionary* classPropertyNamesAndClasses = lowercasedNames ? [lowercasePropertyNamesWithClassForClassCache objectForKey:clazz] : [propertyNamesWithClassForClassCache objectForKey:clazz];
    
    if( !classPropertyNamesAndClasses ) {
        // Add the properties of this class
        NSMutableDictionary* propertyNamesAndClasses = [NSMutableDictionary dictionary];
        NSMutableDictionary* lowercasePropertyNamesAndClasses = [NSMutableDictionary dictionary];
        
        // Find declared properties
        unsigned int outCount = 0;
        objc_property_t* properties = class_copyPropertyList(clazz, &outCount);
        for (unsigned int i=0; i<outCount; i++) {
            objc_property_t property = properties[i];
            const char* name = property_getName(property);
            NSString* propertyName = name != nil ? [NSString stringWithUTF8String:name] : nil;
            if( propertyName && ![propertyName hasPrefix:@"_"] ) { // Ignore private properties (starting with _)
                NSString* propertyType = [self propertyAttributeToString:property attribute:"T"] ?: @"";
                NSString* getter = [self propertyAttributeToString:property attribute:"G"];
                NSString* setter = [self propertyAttributeToString:property attribute:"S"];
                ISSRuntimeProperty* runtimeProperty = [[ISSRuntimeProperty alloc] initWithPropertyName:propertyName type:propertyType getter:getter setter:setter inClass:clazz];
                
                propertyNamesAndClasses[propertyName] = runtimeProperty;
                lowercasePropertyNamesAndClasses[[propertyName lowercaseString]] = runtimeProperty;
            }
        }
        free(properties);
        
        
        // Find "faux" properties, i.e. getter/setter pairs with KVC compliance - first pass
        Method* methods = class_copyMethodList(clazz, &outCount);
        NSMutableDictionary* methodsAndTypes = [NSMutableDictionary dictionary];
        for (unsigned int i=0; i<outCount; i++) {
            Method method = methods[i];
            SEL selector = method_getName(method);
            char* returnType = method_copyReturnType(method);
            
            if ( selector && returnType ) {
                NSString* name = NSStringFromSelector(selector);
                NSString* returnTypeString = [NSString stringWithUTF8String:returnType];
                if ( propertyNamesAndClasses[name] == nil && ![name hasPrefix:@"_"] ) { // Ignore properties already discovered above and properties starting with _
                    methodsAndTypes[name] = returnTypeString;
                }
            }

            if( returnType ) {
                free(returnType);
            }
        }
        
        free(methods);
        
        // Second pass:
        for (__strong NSString* propertyName in methodsAndTypes.allKeys) {
            NSString* propertyType = methodsAndTypes[propertyName];
            // Ignore setter methods and methods with void return type here (i.e. check getters against setters)
            if ( [propertyName containsString:@":"] || [propertyType iss_isEmpty] || [propertyType isEqualToString:@"v"] ) {
                continue;
            }
            
            NSString* setterName = [ISSRuntimeProperty defaultSetterNameForProperty:propertyName];
            if( !methodsAndTypes[setterName] && [propertyName hasPrefix:@"is"] && propertyName.length > 2 ) {
                // Handle case with Bool faux properties (i.e. with format "isXxxx")
                propertyName = [propertyName substringFromIndex:2];
                propertyName = [NSString stringWithFormat:@"%@%@", [[propertyName substringToIndex:1] lowercaseString], [propertyName substringFromIndex:1]];
                setterName = [ISSRuntimeProperty defaultSetterNameForProperty:propertyName];
            }
            if ( methodsAndTypes[setterName] != nil ) {
                // Matching setter available - register as property:
                ISSRuntimeProperty* runtimeProperty = [[ISSRuntimeProperty alloc] initWithPropertyName:propertyName type:propertyType getter:nil setter:nil inClass:clazz];
                
                propertyNamesAndClasses[propertyName] = runtimeProperty;
                lowercasePropertyNamesAndClasses[[propertyName lowercaseString]] = runtimeProperty;
            }
        }
        
        
        // Add to cache
        [propertyNamesWithClassForClassCache setObject:[propertyNamesAndClasses copy] forKey:clazz];
        [lowercasePropertyNamesWithClassForClassCache setObject:[lowercasePropertyNamesAndClasses copy] forKey:clazz];
        
        classPropertyNamesAndClasses = lowercasedNames ? lowercasePropertyNamesAndClasses : propertyNamesAndClasses;
    }
    
    // Get superclass properties
    //NSDictionary* superClassPropertyNamesAndClasses = [self propertyNamesWithTypeForClass:[clazz superclass] lowercase:lowercase] ?: [NSMutableDictionary dictionary];
    NSDictionary* superClassPropertyNamesAndClasses = [self runtimePropertiesForClass:[clazz superclass] excludingRootClasses:rootClasses lowercasedNames:lowercasedNames];
    
    // Combine super class properties with the properties of this class and return
    NSMutableDictionary* combinedPropertyNamesAndClasses = superClassPropertyNamesAndClasses ? [NSMutableDictionary dictionaryWithDictionary:superClassPropertyNamesAndClasses] : [NSMutableDictionary dictionary];
    [combinedPropertyNamesAndClasses addEntriesFromDictionary:classPropertyNamesAndClasses];
    
    return combinedPropertyNamesAndClasses;
}

+ (Class) classFromTypeAttribute:(NSString*)typeAttribute {
    NSArray* splitPropertyAttributes = [typeAttribute componentsSeparatedByString:@"\""];
    if ( [typeAttribute hasPrefix:@"@"] ) {
        if ([splitPropertyAttributes count] > 1) {
            return [self classWithName:splitPropertyAttributes[1]];
        } else {
            return [NSObject superclass];
        }
    } else {
        return nil;
    }
}

+ (ISSRuntimeProperty*) actualPropertyNameAndDetailsForCaseInsensitiveName:(NSString*)caseInsensitivePropertyName inClass:(Class)class {
    NSDictionary* propertyNamesAndClasses = [self runtimePropertiesForClass:class lowercasedNames:YES];
    return propertyNamesAndClasses[[caseInsensitivePropertyName lowercaseString]];
}

+ (NSString*) actualPropertyNameForCaseInsensitiveName:(NSString*)caseInsensitivePropertyName inClass:(Class)class {
    return [self actualPropertyNameAndDetailsForCaseInsensitiveName:caseInsensitivePropertyName inClass:class].propertyName;
}

+ (NSString*) validKeyPathForCaseInsensitivePath:(NSString*)caseInsensitiveKeyPath inClass:(Class)class {
    if(!caseInsensitiveKeyPath) {
        return nil;
    }
    
    NSArray* keyPathComponents = [caseInsensitiveKeyPath componentsSeparatedByString:@"."];
    NSMutableArray* validatedComponents = [NSMutableArray array];
    
    Class currentClass = class;
    for(NSString* keyPathComponent in keyPathComponents) {
        ISSRuntimeProperty* runtimeProperty = [self actualPropertyNameAndDetailsForCaseInsensitiveName:keyPathComponent inClass:currentClass];
        Class clazz = runtimeProperty.propertyClass;
        if( !runtimeProperty || !clazz ) break;
        
        NSString* actualPropertyName = runtimeProperty.propertyName;
        currentClass = clazz;
        
        [validatedComponents addObject:actualPropertyName];
    }
    
    if( validatedComponents.count == keyPathComponents.count ) return [validatedComponents componentsJoinedByString:@"."];
    else return nil;
}

+ (NSInvocation*) invocationForProperty:(ISSRuntimeProperty*)propertyDetails setter:(BOOL)setter inObject:(id)object {
    if( !object || !propertyDetails ) return nil;
    
    NSMethodSignature* signature = setter ? propertyDetails.setterMethod : propertyDetails.getterMethod;
    SEL selector = setter ? propertyDetails.setterSelector : propertyDetails.getterSelector;
    
    return [self invocationForSelector:selector signature:signature inObject:object];
}

+ (NSInvocation*) invocationForInstanceSelector:(SEL)selector inObject:(id)object {
    return [self invocationForSelector:selector signature:[[object class] instanceMethodSignatureForSelector:selector] inObject:object];
}

+ (NSInvocation*) invocationForSelector:(SEL)selector signature:(NSMethodSignature*)signature inObject:(id)object {
    if( signature ) {
        NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:signature];
        [invocation setTarget:object];
        [invocation setSelector:selector];
        return invocation;
    }
    return nil;
}


+ (objc_property_t) findPropertyWithName:(NSString*)propertyName inObject:(id)object {
    if( !object ) return nil;
    
    return [self findPropertyWithName:propertyName inClass:[object class] excludingRootClass:NSObject.class];
}

+ (objc_property_t) findPropertyWithName:(NSString*)propertyName inClass:(Class)clazz excludingRootClass:(Class)rootClass {
    if( ![propertyName iss_hasData] ) return nil;
    
    objc_property_t property = nil;
    while( clazz && clazz != rootClass ) {
        property = class_getProperty(clazz, [propertyName cStringUsingEncoding:NSUTF8StringEncoding]);
        if( property ) break;
        clazz = [clazz superclass];
    }
    return property;
}


+ (BOOL) doesClass:(Class)clazz havePropertyWithName:(NSString*)propertyName {
    return [self doesClass:clazz havePropertyWithName:propertyName ignoringCase:NO];
}

+ (BOOL) doesClass:(Class)clazz havePropertyWithName:(NSString*)propertyName ignoringCase:(BOOL)ignoringCase {
    return [self runtimePropertiesForClass:clazz lowercasedNames:ignoringCase][ignoringCase ? [propertyName lowercaseString] : propertyName] != nil;
}

+ (BOOL) invokeSetterForKeyPath:(NSString*)keyPath ignoringCase:(BOOL)ignoringCase withValue:(id)value inObject:(id)object {
    NSString* propertyName = keyPath;
    id targetObject = object;
    
    NSRange lastDot = [keyPath rangeOfString:@"." options:NSBackwardsSearch];
    if ( lastDot.location != NSNotFound && lastDot.location < (keyPath.length-1) ) {
        NSString* prefixKeyPath = [keyPath substringToIndex:lastDot.location];
        propertyName = [keyPath substringFromIndex:lastDot.location + 1];
        targetObject = [self invokeGetterForKeyPath:prefixKeyPath ignoringCase:ignoringCase inObject:targetObject];
    }
    
    return [self invokeSetterForProperty:propertyName ignoringCase:ignoringCase withValue:value inObject:targetObject];
}

+ (BOOL) invokeSetterForProperty:(NSString*)propertyName ignoringCase:(BOOL)ignoringCase withValue:(id)value inObject:(id)object {
    if( !object || ![propertyName iss_hasData] ) return NO;
    
    ISSRuntimeProperty* propertyDetails = [self runtimePropertiesForClass:[object class] lowercasedNames:ignoringCase][ignoringCase ? [propertyName lowercaseString] : propertyName];
    
    return [self invokeSetterForRuntimeProperty:propertyDetails withValue:value inObject:object];
}

+ (BOOL) invokeSetterForRuntimeProperty:(ISSRuntimeProperty*)propertyDetails withValue:(id)value inObject:(id)object {
    NSInvocation* setterInvocation =  [self invocationForProperty:propertyDetails setter:YES inObject:object];
    
    if( !setterInvocation ) return NO;
    
    BOOL result = [self setInvocationArgumentValue:value atIndex:2 forInvocation:setterInvocation];
    if( result ) {
        [setterInvocation invoke];
    }
    
    return result;
}

+ (id) invokeGetterForKeyPath:(NSString*)keyPath ignoringCase:(BOOL)ignoringCase inObject:(id)object {
    NSArray* keyPathComponents = [keyPath componentsSeparatedByString:@"."];
    
    id currentObject = object;
    int i = 0;
    for(NSString* keyPathComponent in keyPathComponents) {
        currentObject = [self invokeGetterForProperty:keyPathComponent ignoringCase:ignoringCase inObject:currentObject];
        i++;
        if (i == keyPathComponents.count) {
            return currentObject;
        } else if ( currentObject == nil ) {
            return nil;
        }
    }
    
    return nil;
}

+ (id) invokeGetterForProperty:(NSString*)propertyName ignoringCase:(BOOL)ignoringCase inObject:(id)object {
    if( !object || ![propertyName iss_hasData] ) return nil;
    
    ISSRuntimeProperty* propertyDetails = [self runtimePropertiesForClass:[object class] lowercasedNames:ignoringCase][ignoringCase ? [propertyName lowercaseString] : propertyName];
    NSInvocation* invocation =  [self invocationForProperty:propertyDetails setter:NO inObject:object];
    
    if( !invocation ) return nil;
    
    [invocation invoke];
    
    return [self getInvocationReturnValue:invocation];
}

+ (id) invokeInstanceSelector:(SEL)selector withArguments:(NSArray*)arguments inObject:(id)object {
    NSInvocation* invocation =  [self invocationForInstanceSelector:selector inObject:object];
    
    if( !invocation ) return nil;
    NSInteger argumentCount = invocation.methodSignature.numberOfArguments - 2; // self and _cmd
    for(int i=0; i<argumentCount; i++) {
        BOOL result = [self setInvocationArgumentValue:i < arguments.count ? arguments[i] : nil atIndex:2+i forInvocation:invocation];
        if( !result ) {
            return nil;
        }
    }
    
    [invocation invoke];
    
    return [self getInvocationReturnValue:invocation];
}



+ (id) getInvocationReturnValue:(NSInvocation*)invocation {
    const char* returnType = [invocation.methodSignature methodReturnType];
    id returnValue = nil;
    
    if( *returnType != _C_VOID && *returnType != _C_UNDEF ) {
        NSUInteger length = [invocation.methodSignature methodReturnLength];
        void* buffer = (void*)malloc(length);
        [invocation getReturnValue:buffer];
        returnValue = [ISSRuntimeIntrospectionUtils getValueFromBuffer:buffer ofType:returnType];
        
        free(buffer);
    }
    
    return returnValue;
}

+ (id) getValueFromBuffer:(void*)buffer ofType:(const char*)type {
    switch( type[0] ) {
        case _C_CHR: return @(*((char*)buffer));
        case _C_INT: return @(*((int*)buffer));
        case _C_SHT: return @(*((short*)buffer));
        case _C_LNG: return @(*((long*)buffer));
        case _C_LNG_LNG: return @(*((long long*)buffer));
        case _C_UCHR: return @(*((unsigned char*)buffer));
        case _C_UINT: return @(*((unsigned int*)buffer));
        case _C_USHT: return @(*((unsigned short*)buffer));
        case _C_ULNG: return @(*((unsigned long*)buffer));
        case _C_ULNG_LNG: return @(*((unsigned long long*)buffer));
        case _C_FLT: return @(*((float*)buffer));
        case _C_DBL: return @(*((double*)buffer));
        case _C_BOOL: return @(*((bool*)buffer));
        case _C_ID: return *((__unsafe_unretained id*)buffer);
        case _C_SEL:
        case _C_ARY_B:
        case _C_UNION_B:
        case _C_STRUCT_B: return [NSValue valueWithBytes:buffer objCType:type];
        case _C_PTR: {
            if( strcmp(type, @encode(CGColorRef)) == 0 ) { // For now, only support CGColorRefs as pointer types
                return (__bridge id)(*(CGColorRef*)buffer);
            }
            //else return [NSValue valueWithPointer:buffer];
        }
    }
    
    return nil;
}

+ (BOOL) setInvocationArgumentValue:(id)value atIndex:(NSUInteger)index forInvocation:(NSInvocation*)invocation {
    const char* argType = [invocation.methodSignature getArgumentTypeAtIndex:index];
    
    void* valueBuffer = nil;
    
    if( *argType == _C_ID || *argType == _C_PTR ) {
        [invocation setArgument:&value atIndex:index];
    } else {
        NSUInteger bufferSize = 0;
        NSGetSizeAndAlignment(argType, &bufferSize, NULL);
        valueBuffer = malloc(bufferSize);
        if(!valueBuffer) return NO;
        memset(valueBuffer, 0, bufferSize);
        
        if( [value isKindOfClass:NSNumber.class] ) {
            [self writeNumberValue:value toBuffer:valueBuffer withType:argType];
        } else if( [value isKindOfClass:NSValue.class] ) {
            if (@available(iOS 11.0, tvOS 11.0, *)) {
                [value getValue:valueBuffer size:bufferSize];
            } else {
                [value getValue:valueBuffer];
            }
        } else if( value != nil ) {
            return NO;
        }
        
        [invocation setArgument:valueBuffer atIndex:index];

        free(valueBuffer);
    }
    
    return YES;
}

+ (void) writeNumberValue:(NSNumber*)numberValue toBuffer:(void*)buffer withType:(const char*)type {
    switch( type[0] ) {
        case _C_CHR: *((char*)buffer) = [numberValue charValue]; break;
        case _C_INT: *((int*)buffer) = [numberValue intValue]; break;
        case _C_SHT: *((short*)buffer) = [numberValue shortValue]; break;
        case _C_LNG: *((long*)buffer) = [numberValue longValue]; break;
        case _C_LNG_LNG: *((long long*)buffer) = [numberValue longLongValue]; break;
        case _C_UCHR: *((unsigned char*)buffer) = [numberValue unsignedCharValue]; break;
        case _C_UINT: *((unsigned int*)buffer) = [numberValue unsignedIntValue]; break;
        case _C_USHT: *((unsigned short*)buffer) = [numberValue unsignedShortValue]; break;
        case _C_ULNG: *((unsigned long*)buffer) = [numberValue unsignedLongValue]; break;
        case _C_ULNG_LNG: *((unsigned long long*)buffer) = [numberValue unsignedLongLongValue]; break;
        case _C_FLT: *((float*)buffer) = [numberValue floatValue]; break;
        case _C_DBL: *((double*)buffer) = [numberValue doubleValue]; break;
        case _C_BOOL: *((BOOL*)buffer) = [numberValue boolValue]; break;
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
