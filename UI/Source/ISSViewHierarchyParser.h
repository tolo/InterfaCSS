//
//  ISSViewHierarchyParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN


@class ISSRootView;
@class ISSViewHierarchyParser;


extern NSString* const ISSViewDefinitionFileAttributeId;
extern NSString* const ISSViewDefinitionFileAttributeClass;
extern NSString* const ISSViewDefinitionFileAttributeProperty;
extern NSString* const ISSViewDefinitionFileAttributePrototype;
extern NSString* const ISSViewDefinitionFileAttributePrototypeScope;
extern NSString* const ISSViewDefinitionFileAttributeAddAsSubview;
extern NSString* const ISSViewDefinitionFileAttributeImplementationClass;
extern NSString* const ISSViewDefinitionFileAttributeCollectionViewLayoutClass;


/**
 * Protocol for view definition file parser delegates.
 */
@protocol ISSViewHierarchyParserDelegate <NSObject>

/**
 * Called after a view defined in the view definition file has been created. The `attributes` parameter will contain all the attributes specified on the XML tag
 * (canonical names will be used for standard InterfaCSS attributes, see `ISSViewDefinitionFileAttributeId` etc).
 *
 * Note: for prototype views, this callback will be invoked when a view is created from the prototype (i.e. using `-[InterfaCSS viewFromPrototypeWithName:]`),
 * and not during parsing of the view definition file.
 */
- (void) viewHierarchyParser:(ISSViewHierarchyParser*)viewHierarchyParser didBuildView:(UIView*)view parent:(nullable UIView*)parentView elementName:(NSString*)elementName attributes:(NSDictionary*)attributes;

@end


/**
 * Parser implementation for XML based view definition files.
 */
@interface ISSViewHierarchyParser : NSObject<NSXMLParserDelegate>

@property (nonatomic, readonly, weak, nullable) id fileOwner;
@property (nonatomic, readonly, weak, nullable) id<ISSViewHierarchyParserDelegate> delegate;


/**
 * Parses a view hierarchy from the specified file data. Specifying a value for the `fileOwner` will enable setting properties identified in the file.
 * If the fileOwner implements the `ISSViewHierarchyParserDelegate` protocol, it will also be used as the delegate.
 */
+ (nullable ISSRootView*) parseViewHierarchyFromData:(NSData*)fileData fileOwner:(nullable id)fileOwner wrapRoot:(BOOL)wrapRoot;

/**
 * Parses a view hierarchy from the specified file data. Specifying a value for the `fileOwner` will enable setting properties identified in the file.
 * Specifying a value for the `delegate` will enable post processing of views and XML attributes.
 */
+ (nullable ISSRootView*) parseViewHierarchyFromData:(NSData*)fileData fileOwner:(nullable id)fileOwner wrapRoot:(BOOL)wrapRoot delegate:(nullable id<ISSViewHierarchyParserDelegate>)delegate;

/**
 * Utility method for setting the value of a property in either a parent element or a file owner object.
 */
+ (BOOL) setViewObjectPropertyValue:(nullable id)value withName:(NSString*)propertyName inParent:(nullable id)parent orFileOwner:(nullable id)fileOwner silent:(BOOL)silent;

/**
 * Returns the view class that corresponds to the specified XML element name.
 */
- (nullable Class) elementNameToViewClass:(NSString*)elementName;

@end


NS_ASSUME_NONNULL_END
