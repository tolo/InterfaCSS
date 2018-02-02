//
//  ISSUIElementPropertyHandler.m
//  InterfaCSS
//
//  Created by Tobias Löfstrand on 2017-04-29.
//  Copyright © 2017 Leafnode AB. All rights reserved.
//

#import "ISSUIElementPropertyHandler.h"

#import "ISSPropertyDeclaration.h"
#import "ISSRuntimeIntrospectionUtils.h"


@implementation ISSUIElementPropertyHandlerDefault

- (void) setup {
    // TODO: Store properties here
    NSDictionary* properties = [ISSRuntimeIntrospectionUtils runtimePropertiesForClass:UIView.class lowercasedNames:YES];
    
    properties["autoResizingMask"]
}

- (void) setValue:(ISSPropertyDeclaration*)value forProperty:(NSString*)propertyKeyPath inObject:(id)targetObject {
    //[ISSRuntimeIntrospectionUtils invokeSetterForKeyPath:propertyKeyPath ignoringCase:YES withValue:<#(id)#> inObject:<#(id)#>]
    
    [ISSRuntimeIntrospectionUtils invokeSetterForKeyPath:propertyKeyPath ignoringCase:YES withValueBlock:^id (ISSRuntimePropertyDetails* propertyDetails) {
        // transform with propertyDetails.propertyType
        
        
    } inObject:targetObject];
}

@end
