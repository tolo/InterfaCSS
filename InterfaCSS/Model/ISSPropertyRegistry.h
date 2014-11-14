//
//  InterfaCSS
//  ISSPropertyRegistry.h
//  
//  Created by Tobias Löfstrand on 2014-10-03.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import "ISSPropertyDefinition.h"

/**
 * The property registry keeps track on all properties that can be set through stylesheets.
 */
@interface ISSPropertyRegistry : NSObject

@property (nonatomic, strong, readonly) NSSet* propertyDefinitions;
@property (nonatomic, strong, readonly) NSDictionary* validPrefixKeyPaths;

- (NSSet*) propertyDefinitionsForType:(ISSPropertyType)propertyType;
- (NSSet*) propertyDefinitionsForViewClass:(Class)viewClass;
- (ISSPropertyDefinition*) propertyDefinitionForProperty:(NSString*)propertyName inClass:(Class)viewClass;

- (NSSet*) typePropertyDefinitions:(ISSPropertyType)propertyType;

- (NSString*) canonicalTypeForViewClass:(Class)viewClass;
- (Class) canonicalTypeClassForViewClass:(Class)viewClass;
- (Class) canonicalTypeClassForType:(NSString*)type;

/**
 * Registers a custom property with the specified name and type, that can then be used in stylesheets.
 */
- (ISSPropertyDefinition*) registerCustomProperty:(NSString*)propertyName propertyType:(ISSPropertyType)propertyType;

/**
 * Registers a custom property definition.
 */
- (void) registerCustomProperty:(ISSPropertyDefinition*)propertyDefinition;

/**
 * Registers a valid property prefix (i.e. nested property name).
 */
- (void) registerValidPrefixKeyPath:(NSString*)prefix;

/**
 * Registers a set of valid property prefixes (i.e. nested property names).
 */
- (void) registerValidPrefixKeyPaths:(NSArray*)prefixes;

#if DEBUG == 1
- (NSString*) propertyDescriptionsForMarkdown;
#endif

@end
