//
//  ISSPropertyManager.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

#import "ISSPropertyDefinition.h"
@class ISSPropertyDeclaration, ISSElementStylingProxy, ISSStylingManager;

// TODO: Rename to ISSPropertyManager


NS_ASSUME_NONNULL_BEGIN


/**
 * The property registry keeps track on all properties that can be set through stylesheets.
 */
@interface ISSPropertyManager : NSObject

@property (nonatomic, weak) ISSStylingManager* stylingManager;

- (ISSPropertyDefinition*) findPropertyWithName:(NSString*)name inClass:(Class)clazz;

/**
 * Returns the canonical type class for the given class, i.e. the closest super class that represents a valid type selector. For instance, for all `UIView`
 * subclasses, this would by default be `UIView`.
 */
- (nullable Class) canonicalTypeClassForClass:(Class)clazz;
- (nullable NSString*) canonicalTypeForClass:(Class)clazz;
- (nullable Class) canonicalTypeClassForType:(NSString*)type registerIfNotFound:(BOOL)registerIfNotFound;
- (nullable Class) canonicalTypeClassForType:(NSString*)type;

/**
 * Registers a class for use as a valid type selector in stylesheets. Note: this happens automatically whenever an unknown, but valid, class name is encountered
 * in a type selector in a stylesheet. This method exist to be able to register all custom canonical type classes before stylesheet parsing occurs, and to also
 * enable case-insensitive matching of type name -> class.
 *
 * @see canonicalTypeClassForClass:
 */
- (NSString*) registerCanonicalTypeClass:(Class)clazz;


/**
 * Registers a custom property definition.
 */
- (ISSPropertyDefinition*) registerProperty:(ISSPropertyDefinition*)property inClass:(Class)clazz;


- (BOOL) applyPropertyValue:(ISSPropertyDeclaration*)propertyValue onTarget:(ISSElementStylingProxy*)targetElement;


- (ISSPropertyType) runtimePropertyToPropertyType:(ISSRuntimeProperty*)runtimeProperty;

@end


NS_ASSUME_NONNULL_END
