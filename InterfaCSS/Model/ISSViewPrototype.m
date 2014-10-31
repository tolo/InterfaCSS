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
    UIView* view = _viewBuilderBlock([viewStack lastObject]);
    if( !view ) {
        ISSLogWarning(@"View builder block returned nil view");
        return nil;
    }

    if( [_propertyName iss_hasData] ) {
        BOOL propertyFound = NO;
        for(UIView* parentObject in viewStack.reverseObjectEnumerator) {
            if( [ISSViewHierarchyParser setViewObjectPropertyValue:view withName:_propertyName inParent:parentObject orFileOwner:nil silent:YES] ) {
                propertyFound = YES;
                break;
            }
        }
        if( !propertyFound ) {
            ISSLogWarning(@"Property '%@' not found in any ancestor of prototype!", _propertyName);
        }
    }

    viewStack = [viewStack arrayByAddingObject:view];

    for (ISSViewPrototype* subviewPrototype in self.subviewPrototypes) {
        UIView* subview = [subviewPrototype createViewObjectFromPrototypeWithViewStack:viewStack];
        if( subview && subviewPrototype.addAsSubView ) [view addSubview:subview];
    }
    return view;
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"ISSViewPrototype(%@)", _name ?: @"n/a"];
}

@end
