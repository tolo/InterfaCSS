//
//  ISSViewHierarchyParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-01-31.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

@class ISSRootView;

@interface ISSViewHierarchyParser : NSObject<NSXMLParserDelegate>

+ (ISSRootView*) parseViewHierarchyFromData:(NSData*)fileData withFileOwner:(id)fileOwner;

+ (void) setViewObjectPropertyValue:(id)value withName:(NSString*)propertyName inParent:(id)parent orFileOwner:(id)fileOwner;

@end
