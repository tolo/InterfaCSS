//
//  InterfaCSS
//  ISSPropertyDefinition+Private.h
//  
//  Created by Tobias Löfstrand on 2014-10-03.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import "ISSPropertyDefinition.h"


typedef void (^PropertySetterBlock)(ISSPropertyDefinition* property, id viewObject, id value, NSArray* parameters);


@interface ISSPropertyDefinition ()

@property (nonatomic, strong) NSDictionary* enumValues;
@property (nonatomic, copy) PropertySetterBlock propertySetterBlock;

- (id) initWithName:(NSString *)name type:(ISSPropertyType)type;
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type;
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumBlock:(NSDictionary*)enumValues enumBitMaskType:(BOOL)enumBitMaskType;
- (id) initWithName:(NSString *)name aliases:(NSArray*)aliases type:(ISSPropertyType)type enumValues:(NSDictionary*)enumValues
          enumBitMaskType:(BOOL)enumBitMaskType setterBlock:(void (^)(ISSPropertyDefinition*, id, id, NSArray*))setterBlock parameterEnumValues:(NSDictionary*)parameterEnumValues;

- (NSComparisonResult) compareByName:(ISSPropertyDefinition*)other;

@end
