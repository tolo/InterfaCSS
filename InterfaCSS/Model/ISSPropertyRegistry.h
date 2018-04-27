//
//  ISSPropertyRegistry.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSPropertyDefinition.h"

NS_ASSUME_NONNULL_BEGIN


/**
 * The property registry keeps track on all properties that can be set through stylesheets.
 */
@interface ISSPropertyRegistry : NSObject

@property (nonatomic, strong, readonly) NSSet* propertyDefinitions;
@property (nonatomic, strong, readonly) NSDictionary* propertyDefinitionsForClass;

@property (nonatomic, strong, readonly) NSDictionary* validPrefixKeyPaths;

- (NSSet*) propertyDefinitionsForType:(ISSPropertyType)propertyType;
- (NSSet*) propertyDefinitionsForViewClass:(Class)viewClass;
- (nullable ISSPropertyDefinition*) propertyDefinitionForProperty:(NSString*)propertyName inClass:(Class)viewClass;

- (NSSet*) typePropertyDefinitions:(ISSPropertyType)propertyType;

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
- (void) registerCanonicalTypeClass:(Class)clazz;

/**
 * Registers a custom property with the specified name and type, that can then be used in stylesheets.
 */
- (ISSPropertyDefinition*) registerCustomProperty:(NSString*)propertyName propertyType:(ISSPropertyType)propertyType;

/**
 * Registers a custom property definition.
 */
- (void) registerCustomProperty:(ISSPropertyDefinition*)propertyDefinition;

/**
 * Registers a valid property prefix key path (i.e. nested element key path), which can be used in stylesheets to set properties on child elements of a particular element.
 */
- (void) registerValidPrefixKeyPath:(NSString*)prefix;

/**
 * Registers a set of valid property prefixes (i.e. nested element key paths), which can be used in stylesheets to set properties on child elements of a particular element.
 */
- (void) registerValidPrefixKeyPaths:(NSArray*)prefixes;

/**
 * Finds the subset of valid property prefix key paths that are supported by the specified class.
 */
- (NSSet*) validPrefixKeyPathsForClass:(Class)clazz;

#if DEBUG == 1
- (NSString*) propertyDescriptionsForMarkdown;
#endif

@end


NS_ASSUME_NONNULL_END
