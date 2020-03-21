//
//  ISSRuntimeProperty.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSRuntimeProperty.h"

#import <UIKit/UIKit.h>
#import <objc/runtime.h>

#import "ISSRuntimeIntrospectionUtils.h"


@interface ISSRuntimeProperty ()
@property (nonatomic, readonly) unichar typeFirstChar;
@end

@implementation ISSRuntimeProperty {
  Class _propertyClass;
}

- (instancetype) init {
  @throw([NSException exceptionWithName:NSInternalInconsistencyException reason:@"Hold on there professor, init not allowed!" userInfo:nil]);
}

- (instancetype) initWithPropertyName:(NSString*)propertyName type:(NSString*)type getter:(NSString*)customGetterName setter:(NSString*)customSetterName inClass:(Class)clazz {
  if (self = [super init]) {
    _propertyName = propertyName;
    _type = type;
    _typeFirstChar = type.length > 0 ? [type characterAtIndex:0] : 0;
    
    //        _propertyType = ISSPropertyTypeUnknown;
    
    _foundInClass = clazz;
    
    _customGetterName = customGetterName;
    _getterSelector = NSSelectorFromString(customGetterName ?: propertyName);
    _getterMethod = [clazz instanceMethodSignatureForSelector:_getterSelector];
    
    NSString* setter = customSetterName;
    if ( !setter ) {
      setter = [ISSRuntimeProperty defaultSetterNameForProperty:propertyName];
    }
    _customSetterName = customSetterName;
    _setterSelector = NSSelectorFromString(setter);
    _setterMethod = [clazz instanceMethodSignatureForSelector:_setterSelector];
  }
  return self;
}

- (Class) propertyClass {
  if( _typeFirstChar == '@' && _propertyClass == nil ) {
    _propertyClass = [ISSRuntimeIntrospectionUtils classFromTypeAttribute:_type];
  }
  return _propertyClass;
}

- (BOOL) isNumericType {
  switch (_typeFirstChar) {
    case _C_CHR:
    case _C_INT:
    case _C_SHT:
    case _C_LNG:
    case _C_LNG_LNG:
    case _C_UCHR:
    case _C_UINT:
    case _C_USHT:
    case _C_ULNG:
    case _C_ULNG_LNG:
    case _C_FLT:
    case _C_DBL:
    case _C_BOOL: return YES;
    default: return NO;
  }
}

- (BOOL) isType:(char*)typeName {
  return [self.type isEqualToString:[NSString stringWithUTF8String:typeName]];
}

- (BOOL) isBooleanType {
  return _typeFirstChar == _C_BOOL;
}

- (BOOL) isNestedObjectProperty {
  if( !self.propertyClass ) {
    return NO;
  }
  return [self.propertyClass isSubclassOfClass:UIResponder.class] || [NSStringFromClass(self.propertyClass) hasPrefix:@"UI"];
}

- (NSString*) description {
  NSMutableString* descr = [[NSMutableString alloc] initWithString:@"[T: "];
  [descr appendString:self.type];
  if (_customGetterName) {
    [descr appendString:@", G: "];
    [descr appendString:self.customGetterName];
  }
  if (_customSetterName) {
    [descr appendString:@", S: "];
    [descr appendString:self.customSetterName];
  }
  
  [descr appendString:@"]"];
  return descr;
}

+ (NSString*) defaultSetterNameForProperty:(NSString*)propertyName {
  if( propertyName.length > 1 ) {
    return [NSString stringWithFormat:@"set%@%@:", [[propertyName substringToIndex:1] uppercaseString], [propertyName substringFromIndex:1]];
  } else {
    return [NSString stringWithFormat:@"set%@:", [[propertyName substringToIndex:1] uppercaseString]];
  }
}

@end
