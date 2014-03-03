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


@implementation ISSViewPrototype

+ (ISSViewPrototype*) prototypeWithName:(NSString*)name propertyName:(NSString*)propertyName viewBuilderBlock:(ViewBuilderBlock)viewBuilderBlock {
    ISSViewPrototype* prototypeDefinition = [[self alloc] init];
    prototypeDefinition->_name = name;
    prototypeDefinition->_propertyName = propertyName;
    prototypeDefinition->_viewBuilderBlock = viewBuilderBlock;
    prototypeDefinition.subviewPrototypes = @[];
    return prototypeDefinition;
}

- (UIView*) createViewObjectFromPrototype:(id)parentObject {
    UIView* view = _viewBuilderBlock();
    if( [_propertyName hasData] ) [ISSViewHierarchyParser setViewObjectPropertyValue:view withName:_propertyName inParent:parentObject orFileOwner:nil];

    for (ISSViewPrototype* subviewPrototype in self.subviewPrototypes) {
        UIView* subview = [subviewPrototype createViewObjectFromPrototype:view];
        [view addSubview:subview];
    }
    return view;
}

@end
