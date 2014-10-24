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


@implementation ISSViewHierarchyParser {
    id fileOwner;
    ISSRootView* rootView;
    NSMutableArray* viewStack;
    NSMutableSet* addViewAsSubView;
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

+ (BOOL) setViewObjectPropertyValue:(id)value withName:(NSString*)propertyName inParent:(id)parent orFileOwner:(id)fileOwner {
    
    if ([fileOwner respondsToSelector:@selector(viewHierarchyParserWillSetValue:forKey:)]) {
        [fileOwner viewHierarchyParserWillSetValue:value forKey:propertyName];
    }

    if ([parent respondsToSelector:@selector(viewHierarchyParserWillSetValue:forKey:)]) {
        [parent viewHierarchyParserWillSetValue:value forKey:propertyName];
    }

    SEL selector = NSSelectorFromString(propertyName);

    if( [fileOwner respondsToSelector:selector] ) {
        [fileOwner setValue:value forKey:propertyName];
        return YES;
    } else if( [parent respondsToSelector:selector] ) {
        [parent setValue:value forKey:propertyName];
        return YES;
    } else {
        if ( fileOwner && parent ) ISSLogWarning(@"Property '%@' not found in file owner or parent view!", propertyName);
        else if ( fileOwner ) ISSLogWarning(@"Property '%@' not found in file owner!", propertyName);
        else if ( parent ) ISSLogWarning(@"Property '%@' not found in parent view!", propertyName);
        else ISSLogWarning(@"Unable to set property '%@' - no file owner or parent view available!", propertyName);
    }
    return NO;
}

#pragma mark - NSXMLParserDelegate


- (void) parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)nameSpaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict {

    elementName = [elementName iss_trim];
    NSString* lcElementName = [elementName lowercaseString];
    if ( [lcElementName hasPrefix:@"ui"] ) lcElementName = [lcElementName substringFromIndex:2];

    NSString* styleClass = nil;
    NSString* propertyName = nil;
    NSString* prototypeName = nil;
    BOOL add = YES;
    for (NSString* key in attributeDict.allKeys) {
        if ( [[key lowercaseString] hasPrefix:@"class"] ) {
            styleClass = attributeDict[key];
        } else if ( [[key lowercaseString] hasPrefix:@"prototype"] ) {
            prototypeName = attributeDict[key];
        } else if ( [[key lowercaseString] hasPrefix:@"property"] ) {
            propertyName = attributeDict[key];
        } else if ( [[key lowercaseString] hasPrefix:@"add"] ) {
            add = [attributeDict[key] boolValue];
        }
    }

    id parent = viewStack.lastObject;
    ISSViewPrototype* parentPrototype = [parent isKindOfClass:ISSViewPrototype.class] ? parent : nil;

    ViewBuilderBlock viewBuilderBlock = nil;

    // Containers:
    if ( [@"view" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView* { return [ISSViewBuilder viewWithStyle:styleClass]; };
    } else if ( [@"collectionview" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView* {
            UICollectionView* collectionView = [ISSViewBuilder collectionViewWithStyle:styleClass];
            if( [fileOwner conformsToProtocol:@protocol(UICollectionViewDataSource)] ) collectionView.dataSource = fileOwner;
            if( [fileOwner conformsToProtocol:@protocol(UICollectionViewDelegate)] ) collectionView.delegate = fileOwner;
            return collectionView;
        };
    } else if ( [@"imageview" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView* { return [ISSViewBuilder imageViewWithStyle:styleClass]; };
    } else if ( [@"scrollview" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder scrollViewWithStyle:styleClass]; };
    } else if ( [@"tableview" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{
            UITableView* tableView = [ISSViewBuilder tableViewWithStyle:styleClass andTableViewStyle:UITableViewStylePlain];
            if( [fileOwner conformsToProtocol:@protocol(UITableViewDataSource)] ) tableView.dataSource = fileOwner;
            if( [fileOwner conformsToProtocol:@protocol(UITableViewDelegate)] ) tableView.delegate = fileOwner;
            return tableView;
        };
    } else if ( [@"webview" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder webViewWithStyle:styleClass]; };
    }
    // Controls:
    else if ( [lcElementName hasPrefix:@"activityindicator"] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder activityIndicatorViewWithStyle:styleClass]; };
    } else if ( [@"button" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder buttonWithStyle:styleClass]; };
    } else if ( [@"label" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder labelWithStyle:styleClass]; };
    } else if ( [@"progressview" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder progressViewWithStyle:styleClass]; };
    } else if ( [@"slider" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder sliderWithStyle:styleClass]; };
    } else if ( [@"stepper" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder stepperWithStyle:styleClass]; };
    } else if ( [@"switch" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder switchWithStyle:styleClass]; };
    } else if ( [@"textfield" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder textFieldWithStyle:styleClass]; };
    } else if ( [@"textview" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView*{ return [ISSViewBuilder textViewWithStyle:styleClass]; };
    } else if ( [@"tableviewcell" isEqualToString:lcElementName] ) {
        viewBuilderBlock = ^UIView* {
            return [ISSViewBuilder tableViewCellWithStyle:styleClass andReuseIdentifier:prototypeName];
        };
    } else {
        Class c = NSClassFromString(elementName);
        if ( c ) {
            viewBuilderBlock = ^UIView*{
                return [ISSViewBuilder setupView:[[c alloc] init] withStyleClass:styleClass];
            };
        }
    }

    id currentViewObject;

    if ( parentPrototype && viewBuilderBlock ) {
        currentViewObject = [ISSViewPrototype prototypeWithName:prototypeName propertyName:propertyName addAsSubView:add viewBuilderBlock:viewBuilderBlock];
    } else if ( [prototypeName iss_hasData] ) {
        currentViewObject = [ISSViewPrototype prototypeWithName:prototypeName propertyName:propertyName addAsSubView:add viewBuilderBlock:viewBuilderBlock];
    } else if( viewBuilderBlock ) {
        currentViewObject = viewBuilderBlock();
        if( [propertyName iss_hasData] ) {
            [self.class setViewObjectPropertyValue:currentViewObject withName:propertyName inParent:parent orFileOwner:fileOwner];
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
