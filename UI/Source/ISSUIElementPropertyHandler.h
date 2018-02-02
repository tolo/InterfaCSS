//
//  ISSUIElementPropertyHandler.h
//  InterfaCSS
//
//  Created by Tobias Löfstrand on 2017-04-29.
//  Copyright © 2017 Leafnode AB. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ISSPropertyDeclaration;


@protocol ISSUIElementPropertyHandler

- (void) setValue:(ISSPropertyDeclaration*)value forProperty:(NSString*)propertyKeyPath inObject:(id)targetObject;

@end


@interface ISSUIElementPropertyHandlerDefault <ISSUIElementPropertyHandler> : NSObject

@end

@interface ISSUIElementPropertyHandlerSegmentedControl : ISSUIElementPropertyHandlerDefault

@end
