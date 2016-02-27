//
//  ISSViewHierarchyParser.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSViewHierarchyParser.h"

#import "ISSViewBuilder.h"
#import "NSObject+ISSLogSupport.h"
#import "NSString+ISSStringAdditions.h"
#import "ISSViewPrototype.h"
#import "InterfaCSS.h"
#import "ISSUIElementDetails.h"
#import "ISSRuntimeIntrospectionUtils.h"
#import "ISSStyleSheetParser.h"


NSString* const ISSViewDefinitionFileAttributeId = @"id";
NSString* const ISSViewDefinitionFileAttributeClass = @"class";
NSString* const ISSViewDefinitionFileAttributeProperty = @"property";
NSString* const ISSViewDefinitionFileAttributeISSLayout = @"layout";
NSString* const ISSViewDefinitionFileAttributePrototype = @"prototype";
NSString* const ISSViewDefinitionFileAttributePrototypeScope = @"prototypeScope";
NSString* const ISSViewDefinitionFileAttributeAddAsSubview = @"addSubview";
NSString* const ISSViewDefinitionFileAttributeImplementationClass = @"implementation";
NSString* const ISSViewDefinitionFileAttributeCollectionViewLayoutClass = @"collectionViewLayout";


static NSDictionary* tagToClass;


@interface ISSViewHierarchyParser ()

@property (nonatomic, readwrite, weak) id fileOwner;
@property (nonatomic, readwrite, weak) id<ISSViewHierarchyParserDelegate> delegate;

@property (nonatomic, strong) ISSRootView* rootView;
@property (nonatomic) BOOL wrapRoot;
@property (nonatomic, strong) NSMutableArray* viewStack;
@property (nonatomic, strong) NSMutableSet* addViewAsSubView;

@end

@implementation ISSViewHierarchyParser

#pragma mark - Lifecycle

+ (void) initialize {
    tagToClass = @{
        // Containers:
        @"collectionview": UICollectionView.class,
        @"imageview": UIImageView.class,
        @"scrollview": UIScrollView.class,
        @"tableview": UITableView.class,
        @"view": UIView.class,
#if TARGET_OS_TV == 0
        @"webview": UIWebView.class,
#endif
        // Components:
        @"activityindicator": UIActivityIndicatorView.class,
        @"button": UIButton.class,
        @"collectionviewcell": UICollectionViewCell.class,
        @"label": UILabel.class,
        @"progressview": UIProgressView.class,
#if TARGET_OS_TV == 0
        @"slider": UISlider.class,
        @"stepper": UIStepper.class,
        @"switch": UISwitch.class,
#endif
        @"textfield": UITextField.class,
        @"textview": UITextView.class,
        @"tableviewcell": UITableViewCell.class
    };
}

+ (ISSRootView*) parseViewHierarchyFromData:(NSData*)fileData fileOwner:(id)fileOwner wrapRoot:(BOOL)wrapRoot {
    id<ISSViewHierarchyParserDelegate> delegate = nil;
    if( [fileOwner conformsToProtocol:@protocol(ISSViewHierarchyParserDelegate)] ) {
        delegate = fileOwner;
    }
    return [self parseViewHierarchyFromData:fileData fileOwner:fileOwner wrapRoot:wrapRoot delegate:delegate];
}

+ (ISSRootView*) parseViewHierarchyFromData:(NSData*)fileData fileOwner:(id)fileOwner wrapRoot:(BOOL)wrapRoot delegate:(id<ISSViewHierarchyParserDelegate>)delegate {
    ISSViewHierarchyParser* viewParser = [[self alloc] init];
    viewParser.viewStack = [[NSMutableArray alloc] init];
    viewParser.fileOwner = fileOwner;
    viewParser.delegate = delegate;
    viewParser.addViewAsSubView = [[NSMutableSet alloc] init];
    viewParser.wrapRoot = wrapRoot;

    @try {
        NSXMLParser* parser = [[NSXMLParser alloc] initWithData:fileData];
        [parser setDelegate:viewParser];
        if( ![parser parse] ) {
            ISSLogWarning(@"Error parsing view hierarchy file - %@", parser.parserError);
        }
    } @catch (NSException* exception) {
        ISSLogWarning(@"Error parsing view hierarchy file - %@", exception);
    }

    return viewParser.rootView;
}


#pragma mark - Support methods

+ (BOOL) setViewObjectPropertyValue:(id)value withName:(NSString*)propertyName inParent:(id)parent orFileOwner:(id)fileOwner silent:(BOOL)silent {
    if( [ISSRuntimeIntrospectionUtils doesClass:[fileOwner class] havePropertyWithName:propertyName] ) {
        [fileOwner setValue:value forKey:propertyName];
        return YES;
    } else if( [ISSRuntimeIntrospectionUtils doesClass:[parent class] havePropertyWithName:propertyName] ) {
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

- (Class) elementNameToViewClass:(NSString*)elementName {
    NSString* lcElementName = [elementName lowercaseString];
    if ( [lcElementName hasPrefix:@"ui"] ) lcElementName = [lcElementName substringFromIndex:2];
    Class viewClass = (Class)tagToClass[lcElementName];
    if( !viewClass )  {
        // Fallback - use element name as viewClass
        viewClass = [ISSRuntimeIntrospectionUtils classWithName:elementName];
    }
    return viewClass;
}


#pragma mark - View builder support methods

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

- (void) postProcessView:(UIView*)view issLayoutValue:(NSString*)issLayoutValue {
    if( [view isKindOfClass:UICollectionView.class] ) {
        UICollectionView* collectionView = (UICollectionView*)view;
        if( [self.fileOwner conformsToProtocol:@protocol(UICollectionViewDataSource)] ) collectionView.dataSource = self.fileOwner;
        if( [self.fileOwner conformsToProtocol:@protocol(UICollectionViewDelegate)] ) collectionView.delegate = self.fileOwner;
    }
    else if( [view isKindOfClass:UITableView.class] ) {
        UITableView* tableView = (UITableView*)view;
        if( [self.fileOwner conformsToProtocol:@protocol(UITableViewDataSource)] ) tableView.dataSource = self.fileOwner;
        if( [self.fileOwner conformsToProtocol:@protocol(UITableViewDelegate)] ) tableView.delegate = self.fileOwner;
    }
    
    if( issLayoutValue ) {
        ISSLayout* layout = [[InterfaCSS interfaCSS].parser transformValue:issLayoutValue asPropertyType:ISSPropertyTypeLayout];
        if( layout ) {
            ISSUIElementDetails* details = [[InterfaCSS sharedInstance] detailsForUIElement:view];
            details.layout = layout;
        }
    }
}


#pragma mark - NSXMLParserDelegate

- (void) parser:(NSXMLParser*)parser didStartElement:(NSString*)elementName namespaceURI:(NSString*)nameSpaceURI qualifiedName:(NSString*)qName attributes:(NSDictionary*)attributeDict {
    elementName = [elementName iss_trim];

    // Attributes
    NSString* elementId = nil;
    NSString* styleClass = nil;
    NSString* propertyName = nil;
    BOOL implicitPropertyName = YES;
    NSString* issLayoutValue = nil;
    NSString* prototypeName = nil;
    BOOL prototypeScopeParent = YES;
    BOOL addSubview = YES;
    Class viewClass = nil;
    Class collectionViewLayoutClass = nil;

    NSMutableDictionary* canonicalAttributes = nil;
    if( self.delegate ) {
        canonicalAttributes = [NSMutableDictionary dictionary];
    }

    for (NSString* key in attributeDict.allKeys) {
        NSString* value = attributeDict[key];

        // "id" or "elementId":
        if ( [key iss_isEqualIgnoreCase:ISSViewDefinitionFileAttributeId] || [key iss_isEqualIgnoreCase:@"elementid"] ) {
            elementId = value;
            if( !propertyName ) propertyName = elementId;
            canonicalAttributes[ISSViewDefinitionFileAttributeId] = value;
        }
        // "class":
        else if ( [key iss_isEqualIgnoreCase:ISSViewDefinitionFileAttributeClass] ) {
            styleClass = value;
            canonicalAttributes[ISSViewDefinitionFileAttributeClass] = value;
        }
        // "property":
        else if ( [key iss_isEqualIgnoreCase:ISSViewDefinitionFileAttributeProperty] ) {
            propertyName = value;
            implicitPropertyName = NO;
            canonicalAttributes[ISSViewDefinitionFileAttributeProperty] = value;
        }
        // "layout" or "ISSLayout":
        else if ( [key iss_isEqualIgnoreCase:ISSViewDefinitionFileAttributeISSLayout] || [key iss_isEqualIgnoreCase:@"isslayout"] ) {
            issLayoutValue = value;
            canonicalAttributes[ISSViewDefinitionFileAttributeISSLayout] = value;
        }
        // "prototype":
        else if ( [key iss_isEqualIgnoreCase:ISSViewDefinitionFileAttributePrototype] ) {
            prototypeName = value;
            canonicalAttributes[ISSViewDefinitionFileAttributePrototype] = value;
        }
        // "propertyScope" or "scope":
        else if ( [key iss_isEqualIgnoreCase:ISSViewDefinitionFileAttributePrototypeScope] || [key iss_isEqualIgnoreCase:@"scope"] ) {
            prototypeScopeParent = [[value iss_trim] iss_isEqualIgnoreCase:@"parent"]; // "parent" or "global"
            canonicalAttributes[ISSViewDefinitionFileAttributePrototypeScope] = value;
        }
        // "add" or "addSubview":
        else if ( [key iss_isEqualIgnoreCase:ISSViewDefinitionFileAttributeAddAsSubview] || [key iss_isEqualIgnoreCase:@"add"] ) {
            addSubview = [value boolValue];
            canonicalAttributes[ISSViewDefinitionFileAttributeAddAsSubview] = value;
        }
        // "impl" or "implementation":
        else if ( [key iss_isEqualIgnoreCase:ISSViewDefinitionFileAttributeImplementationClass] || [key iss_isEqualIgnoreCase:@"impl"] ) {
            viewClass =  [ISSRuntimeIntrospectionUtils classWithName:value];
            canonicalAttributes[ISSViewDefinitionFileAttributeImplementationClass] = value;
        }
        // "collectionViewLayout":
        else if ( [key iss_isEqualIgnoreCase:ISSViewDefinitionFileAttributeCollectionViewLayoutClass] || [key iss_isEqualIgnoreCase:@"layoutClass"] ) {
            collectionViewLayoutClass = [ISSRuntimeIntrospectionUtils classWithName:value];
            canonicalAttributes[ISSViewDefinitionFileAttributeCollectionViewLayoutClass] = value;
        }
        else {
            canonicalAttributes[key] = value;
        }
    }

    id parent = self.viewStack.lastObject;
    ISSViewPrototype* parentPrototype = [parent isKindOfClass:ISSViewPrototype.class] ? parent : nil;

    // Set viewClass if not specified by impl attribute
    viewClass = viewClass ?: [self elementNameToViewClass:elementName];
    viewClass = viewClass ?: UIView.class; // If class not found - fall back to UIView
    
    // If this is the root view, make it an ISSRootView instead of UIView (if not using a root wrapper view)
    if( !self.rootView && !self.wrapRoot && [viewClass isEqual:UIView.class] ) {
        viewClass = ISSRootView.class;
    }
    

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
            UIView* view;
            // Custom handling for UICollectionView: if collectionViewLayoutClass attribute is specified - used dedicated builder method to create a collection view using that layout class
            if( collectionViewLayoutClass && [viewClass isSubclassOfClass:UICollectionView.class] ) {
                view = [ISSViewBuilder collectionViewOfClass:viewClass collectionViewLayoutClass:collectionViewLayoutClass withStyle:styleClass andSubViews:nil];
            } else {
                view = [ISSViewBuilder viewOfClass:viewClass withId:elementId andStyle:styleClass];
            }

            [self postProcessView:view issLayoutValue:issLayoutValue];
            [self.delegate viewHierarchyParser:self didBuildView:view parent:superview elementName:elementName attributes:canonicalAttributes];
            return view;
        };
    }

    id currentViewObject;

    if ( parentPrototype || [prototypeName iss_hasData] ) {
        currentViewObject = [ISSViewPrototype prototypeWithName:prototypeName propertyName:propertyName addAsSubView:addSubview viewBuilderBlock:viewBuilderBlock];
        ((ISSViewPrototype*)currentViewObject).implicitPropertyName = implicitPropertyName;
        ((ISSViewPrototype*)currentViewObject).prototypeScopeParent = prototypeScopeParent;
    } else {
        currentViewObject = viewBuilderBlock(parent);
        if( [propertyName iss_hasData] ) {
            [self.class setViewObjectPropertyValue:currentViewObject withName:propertyName inParent:parent orFileOwner:self.fileOwner silent:implicitPropertyName];
        }
        if( addSubview ) [self.addViewAsSubView addObject:currentViewObject];
    }

    if( !self.rootView ) {
        // Wrap view in ISSRootView (if needed)
        if( self.wrapRoot || ![currentViewObject isKindOfClass:ISSRootView.class] ) {
            self.rootView = [[ISSRootView alloc] initWithView:currentViewObject];
        } else {
            self.rootView = currentViewObject;
        }
    }

    if( currentViewObject ) [self.viewStack addObject:currentViewObject];
}

- (void) parser:(NSXMLParser*)parser didEndElement:(NSString*)elementName namespaceURI:(NSString*)namespaceURI qualifiedName:(NSString*)qName {
    id viewObject = self.viewStack.lastObject;
    [self.viewStack removeLastObject];
    id superViewObject = self.viewStack.lastObject;

    ISSViewPrototype* currentPrototype = [viewObject isKindOfClass:ISSViewPrototype.class] ? viewObject : nil;
    ISSViewPrototype* parentPrototype = [superViewObject isKindOfClass:ISSViewPrototype.class] ? superViewObject : nil;

    // Prototype child view end tag
    if( currentPrototype && parentPrototype ) {
        parentPrototype.subviewPrototypes = [parentPrototype.subviewPrototypes arrayByAddingObject:currentPrototype];
    }
    // Topmost prototype end tag - register prototype
    else if( currentPrototype ) {
        if( currentPrototype.prototypeScopeParent ) {
            [[InterfaCSS interfaCSS] registerPrototype:currentPrototype inElement:superViewObject];
        } else {
            [[InterfaCSS interfaCSS] registerPrototype:currentPrototype];
        }
    }
    // Child view end tag
    else if ( viewObject && superViewObject && [self.addViewAsSubView containsObject:viewObject] ) {
        [superViewObject addSubview:viewObject];
    }
}

@end
