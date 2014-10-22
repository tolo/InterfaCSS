//
//  InterfaCSS
//  ISSRuntimeIntrospectionUtils.h
//  
//  Created by Tobias Löfstrand on 2014-10-22.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//


#import <Foundation/Foundation.h>


@interface ISSRuntimeIntrospectionUtils : NSObject

+ (SEL) findSelectorWithCaseInsensitiveName:(NSString*)name inClass:(Class)clazz;

+ (void) invokeSingleObjectArgumentSelector:(SEL)selector inObject:(id)object parameter:(id)parameter;

@end
