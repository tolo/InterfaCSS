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


@protocol ISSViewHierarchyFileOwner
@optional
/**
 *  Optional callback from ISSViewHierarchyParser, passing a UIView and it's associated property name
 *  Allows File's Owner to receive a record of all views with properties associated without requiring a direct
 *  relationship with file's owner   Implemenation can forward to a supporting helper instance
 *
 *  @param view         created view
 *  @param propertyName name to associate with view
 *
 */
- (void)viewHierarchyParserWillSetValue:(UIView *)view forKey:(NSString *)propertyName;
@end

@interface ISSViewHierarchyParser : NSObject<NSXMLParserDelegate>

+ (ISSRootView*) parseViewHierarchyFromData:(NSData*)fileData withFileOwner:(id<ISSViewHierarchyFileOwner>)fileOwner;

+ (BOOL) setViewObjectPropertyValue:(id)value withName:(NSString*)propertyName inParent:(id)parent orFileOwner:(id<ISSViewHierarchyFileOwner>)fileOwner;

@end
