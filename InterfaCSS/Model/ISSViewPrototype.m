//
//  ISSViewPrototype.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-07.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSViewPrototype.h"
#import "ISSViewHierarchyParser.h"
#import "NSString+ISSStringAdditions.h"
#import "NSObject+ISSLogSupport.h"


@implementation ISSViewPrototype

+ (ISSViewPrototype*) prototypeWithName:(NSString*)name propertyName:(NSString*)propertyName addAsSubView:(BOOL)addAsSubView viewBuilderBlock:(ViewBuilderBlock)viewBuilderBlock {
    ISSViewPrototype* prototypeDefinition = [[self alloc] init];
    prototypeDefinition->_name = name;
    prototypeDefinition->_propertyName = propertyName;
    prototypeDefinition->_addAsSubView = addAsSubView;
    prototypeDefinition->_viewBuilderBlock = viewBuilderBlock;
    prototypeDefinition.subviewPrototypes = @[];
    return prototypeDefinition;
}

- (UIView*) createViewObjectFromPrototype:(id)parentObject {
    if( parentObject ) return [self createViewObjectFromPrototypeWithViewStack:@[parentObject]];
    else return [self createViewObjectFromPrototypeWithViewStack:@[]];
}

- (UIView*) createViewObjectFromPrototypeWithViewStack:(NSArray*)viewStack {
    UIView* view = _viewBuilderBlock();
    if( !view ) {
        ISSLogWarning(@"View builder block returned nil view");
        return nil;
    }

    if( [_propertyName iss_hasData] ) {
        for(UIView* parentObject in viewStack.reverseObjectEnumerator) {
            if( [ISSViewHierarchyParser setViewObjectPropertyValue:view withName:_propertyName inParent:parentObject orFileOwner:nil] ) {
                break;
            }
        }
    }

    viewStack = [viewStack arrayByAddingObject:view];

    for (ISSViewPrototype* subviewPrototype in self.subviewPrototypes) {
        UIView* subview = [subviewPrototype createViewObjectFromPrototypeWithViewStack:viewStack];
        if( subview && subviewPrototype.addAsSubView ) [view addSubview:subview];
    }
    return view;
}

@end
