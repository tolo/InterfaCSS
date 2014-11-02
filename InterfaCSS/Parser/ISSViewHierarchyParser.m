//
//  ISSViewHierarchyParser.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-01-31.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSViewHierarchyParser.h"

#import "ISSViewBuilder.h"
#import "NSObject+ISSLogSupport.h"
#import "NSString+ISSStringAdditions.h"
#import "ISSViewPrototype.h"
#import "InterfaCSS.h"
#import "ISSUIElementDetails.h"


static NSDictionary* tagToClass;

@implementation ISSViewHierarchyParser {
    id fileOwner;
    ISSRootView* rootView;
    NSMutableArray* viewStack;
    NSMutableSet* addViewAsSubView;
}

+ (void) initialize {
    tagToClass = @{
        // Containers:
        @"collectionview": UICollectionView.class,
        @"imageview": UIImageView.class,
        @"scrollview": UIScrollView.class,
        @"tableview": UITableView.class,
        @"view": UIView.class,
        @"webview": UIWebView.class,
        // Components:
        @"activityindicator": UIActivityIndicatorView.class,
        @"button": UIButton.class,
        @"collectionviewcell": UICollectionViewCell.class,
        @"label": UILabel.class,
        @"progressview": UIProgressView.class,
        @"slider": UISlider.class,
        @"stepper": UIStepper.class,
        @"switch": UISwitch.class,
        @"textfield": UITextField.class,
        @"textview": UITextView.class,
        @"tableviewcell": UITableViewCell.class
    };
}

+ (ISSRootView*) parseViewHierarchyFromData:(NSData*)fileData withFileOwner:(id)fileOwner {
    ISSViewHierarchyParser* viewParser = [[ISSViewHierarchyParser alloc] init];
    viewParser->viewStack = [[NSMutableArray alloc] init];
    viewParser->fileOwner = fileOwner;
    viewParser->addViewAsSubView = [[NSMutableSet alloc] init];

    @try {
        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:fileData];
        [parser setDelegate:viewParser];
        [parser parse];
    } @catch (NSException* exception) {
        ISSLogDebug(@"Error view hierarchy file - %@", exception);
    }

    return viewParser->rootView;
}

+ (BOOL) setViewObjectPropertyValue:(id)value withName:(NSString*)propertyName inParent:(id)parent orFileOwner:(id)fileOwner silent:(BOOL)silent {
    SEL selector = NSSelectorFromString(propertyName);

    if( [fileOwner respondsToSelector:selector] ) {
        [fileOwner setValue:value forKey:propertyName];
        return YES;
    } else if( [parent respondsToSelector:selector] ) {
        [parent setValue:value forKey:propertyName];
        return YES;
    } else if( !silent ) {
        if ( fileOwner && parent ) ISSLogWarning(@"Property '%@' not found in file owner or parent view!", propertyName);
        else if ( fileOwner ) ISSLogWarning(@"Property '%@' not found in file owner!", propertyName);
        else if ( parent ) ISSLogWarning(@"Property '%@' not found in parent view!", propertyName);
        else ISSLogWarning(@"Unable to set property '%@' - no file owner or parent view available!", propertyName);
    }
    return NO;
}


#pragma mark - View builder support methods

- (void) setElementId:(NSString*)elementId forView:(UIView*)view overwrite:(BOOL)overwrite {
    if( elementId ) {
        ISSUIElementDetails* details = [[InterfaCSS sharedInstance] detailsForUIElement:view];
        if( overwrite || !details.elementId) details.elementId = elementId;
    }
}

- (ViewBuilderBlock) viewBuilderBlockForPrototypeTableViewCellWithClass:(Class)clazz superview:(id)superview styleClass:(NSString*)styleClass prototypeName:(NSString*)prototypeName {
    [(UITableView*)superview registerClass:clazz forCellReuseIdentifier:prototypeName];
    return ^UIView* (UIView* cell) {
        // The input of this block will be a newly instantiated table view cell
        UITableViewCell* tableViewCell = [ISSViewBuilder setupView:cell withStyleClass:styleClass];
        return tableViewCell.contentView; // We want subviews to be added to the content view of the cell, so let's return that
    };
}

- (ViewBuilderBlock) viewBuilderBlockForPrototypeCollectionViewCellWithClass:(Class)clazz superview:(id)superview styleClass:(NSString*)styleClass prototypeName:(NSString*)prototypeName {
    [(UICollectionView*)superview registerClass:clazz forCellWithReuseIdentifier:prototypeName];
    return ^UIView* (UIView* cell) {
        // The input of this block will be a newly instantiated collection view cell
        UICollectionViewCell* collectionViewCell = [ISSViewBuilder setupView:cell withStyleClass:styleClass];
        return collectionViewCell.contentView; // We want subviews to be added to the content view of the cell, so let's return that
    };
}

- (void) postProcessView:(UIView*)view elementId:(NSString*)elementId {
    if( [view isKindOfClass:UICollectionView.class] ) {
        UICollectionView* collectionView = (UICollectionView*)view;
        if( [fileOwner conformsToProtocol:@protocol(UICollectionViewDataSource)] ) collectionView.dataSource = fileOwner;
        if( [fileOwner conformsToProtocol:@protocol(UICollectionViewDelegate)] ) collectionView.delegate = fileOwner;
    }
    else if( [view isKindOfClass:UITableView.class] ) {
        UITableView* tableView = (UITableView*)view;
        if( [fileOwner conformsToProtocol:@protocol(UITableViewDataSource)] ) tableView.dataSource = fileOwner;
        if( [fileOwner conformsToProtocol:@protocol(UITableViewDelegate)] ) tableView.delegate = fileOwner;
    }

    [self setElementId:elementId forView:view overwrite:YES];
}

#pragma mark - NSXMLParserDelegate


- (void) parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)nameSpaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict {

    elementName = [elementName iss_trim];
    NSString* lcElementName = [elementName lowercaseString];
    if ( [lcElementName hasPrefix:@"ui"] ) lcElementName = [lcElementName substringFromIndex:2];

    // Attributes
    NSString* styleClass = nil;
    NSString* propertyName = nil;
    NSString* prototypeName = nil;
    NSString* elementId = nil;
    BOOL add = YES;
    Class viewClass = nil;

    for (NSString* key in attributeDict.allKeys) {
        if ( [[key lowercaseString] hasPrefix:@"class"] ) {
            styleClass = attributeDict[key];
        } else if ( [[key lowercaseString] hasPrefix:@"prototype"] ) {
            prototypeName = attributeDict[key];
        } else if ( [[key lowercaseString] hasPrefix:@"property"] ) {
            propertyName = attributeDict[key];
        } else if ( [[key lowercaseString] hasSuffix:@"id"] || [[key lowercaseString] hasPrefix:@"alias"] ) {
            elementId = attributeDict[key];
        } else if ( [[key lowercaseString] hasPrefix:@"add"] ) {
            add = [attributeDict[key] boolValue];
        } else if ( [[key lowercaseString] hasPrefix:@"impl"] ) {
            viewClass =  NSClassFromString(attributeDict[key]);
        }
    }

    id parent = viewStack.lastObject;
    ISSViewPrototype* parentPrototype = [parent isKindOfClass:ISSViewPrototype.class] ? parent : nil;

    // Set viewClass if not specified by impl attribute
    viewClass = viewClass ?: (Class)tagToClass[lcElementName];
    if( !viewClass )  {
        // Fallback - may be removed in favor of '<view impl="MyViewClass">'
        viewClass = NSClassFromString(elementName);
    }
    viewClass = viewClass ?: UIView.class;


    // Setup ViewBuilderBlock
    ViewBuilderBlock viewBuilderBlock;

    // Special cases (cell prototypes):
    if ( [viewClass isSubclassOfClass:UITableViewCell.class] && [prototypeName iss_hasData] ) {
        viewBuilderBlock = [self viewBuilderBlockForPrototypeTableViewCellWithClass:viewClass superview:parent styleClass:styleClass prototypeName:prototypeName];
    }
    else if ( [viewClass isSubclassOfClass:UICollectionViewCell.class] && [prototypeName iss_hasData] ) {
        viewBuilderBlock = [self viewBuilderBlockForPrototypeCollectionViewCellWithClass:viewClass superview:parent styleClass:styleClass prototypeName:prototypeName];
    }
    // Default case:
    else {
        viewBuilderBlock = ^UIView* (UIView* superview) {
            UIView* view = [ISSViewBuilder viewOfClass:viewClass withStyle:styleClass];
            [self postProcessView:view elementId:elementId];
            return view;
        };
    }

    id currentViewObject;

    if ( parentPrototype ) {
        currentViewObject = [ISSViewPrototype prototypeWithName:prototypeName propertyName:propertyName addAsSubView:add viewBuilderBlock:viewBuilderBlock];
    } else if ( [prototypeName iss_hasData] ) {
        currentViewObject = [ISSViewPrototype prototypeWithName:prototypeName propertyName:propertyName addAsSubView:add viewBuilderBlock:viewBuilderBlock];
    } else {
        currentViewObject = viewBuilderBlock(parent);
        if( [propertyName iss_hasData] ) {
            [self.class setViewObjectPropertyValue:currentViewObject withName:propertyName inParent:parent orFileOwner:fileOwner silent:NO];
        }
        if( add ) [addViewAsSubView addObject:currentViewObject];
    }

    if( !rootView ) {
        rootView = [[ISSRootView alloc] initWithView:currentViewObject];
    }

    if( currentViewObject ) [viewStack addObject:currentViewObject];
}

- (void) parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName {
    id viewObject = viewStack.lastObject;
    [viewStack removeLastObject];
    id superViewObject = viewStack.lastObject;

    ISSViewPrototype* currentPrototype = [viewObject isKindOfClass:ISSViewPrototype.class] ? viewObject : nil;
    ISSViewPrototype* parentPrototype = [superViewObject isKindOfClass:ISSViewPrototype.class] ? superViewObject : nil;

    // Prototype child view end tag
    if( currentPrototype && parentPrototype ) {
        parentPrototype.subviewPrototypes = [parentPrototype.subviewPrototypes arrayByAddingObject:currentPrototype];
    }
    // Topmost prototype end tag - register prototype
    else if( currentPrototype ) {
        [[InterfaCSS interfaCSS] registerPrototype:currentPrototype];
    }
    // Child view end tag
    else if ( viewObject && superViewObject && [addViewAsSubView containsObject:viewObject] ) {
        [superViewObject addSubview:viewObject];
    }
}

@end
