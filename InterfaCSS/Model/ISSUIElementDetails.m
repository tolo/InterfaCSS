//
//  ISSUIElementDetails.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-03-19.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSUIElementDetails.h"

const NSString* ISSTableViewCellIndexPathKey = @"ISSTableViewCellIndexPathKey";

@implementation ISSUIElementDetails {
    NSMutableDictionary* _additionalDetails;
}

#pragma mark - Lifecycle

- (id) initWithUIElement:(id)uiElement {
    self = [super init];
    if (self) {
        _uiElement = uiElement;
        if( [uiElement isKindOfClass:[UIView class]] ) {
            UIView* view = (UIView*)uiElement;
            self.parentView = view.superview;
        }
        self.canonicalType = [ISSPropertyDefinition canonicalTypeClassForViewClass:[self.uiElement class]];
        self.stylesCacheable = YES;
    }
    return self;
}

#pragma mark - NSCopying

- (id) copyWithZone:(NSZone*)zone {
    ISSUIElementDetails* copy = [[self.class allocWithZone:zone] init];
    copy->_uiElement = self->_uiElement;
    copy.parentView = self.parentView;
    copy.canonicalType = self.canonicalType;
    copy.styleClasses = self.styleClasses;
    copy.stylesCacheable = self.stylesCacheable;
    return copy;
}


#pragma mark - Utils

- (id) findParent:(UIView*)parentView ofClass:(Class)class {
    if( !parentView ) return nil;
    else if( [parentView isKindOfClass:class] ) return parentView;
    else return [self findParent:parentView.superview ofClass:class];
}

#pragma mark - Public interface

- (UIView*) view {
    return [self.uiElement isKindOfClass:UIView.class] ? self.uiElement : nil;
}

- (NSMutableDictionary*) additionalDetails {
    if( !_additionalDetails ) _additionalDetails = [[NSMutableDictionary alloc] init];
    return _additionalDetails;
}

- (void) typeQualifiedPositionInParent:(NSInteger*)position count:(NSInteger*)count {
    *position = NSNotFound;
    *count = 0;

    if( [self.uiElement isKindOfClass:UITableViewCell.class] ) {
        UITableView* tv = [self findParent:self.parentView ofClass:UITableView.class];
        NSIndexPath* indexPath = [tv indexPathForCell:(UITableViewCell*)self.uiElement];
        if( !indexPath ) indexPath = self.additionalDetails[ISSTableViewCellIndexPathKey];
        if( indexPath ) {
            *position = indexPath.row;
            *count = [tv numberOfRowsInSection:indexPath.section];
        }
    }
    else if( [self.uiElement isKindOfClass:UICollectionViewCell.class] ) {
        UICollectionView* cv = [self findParent:self.parentView ofClass:UICollectionView.class];
        NSIndexPath* indexPath = [cv indexPathForCell:(UICollectionViewCell*)self.uiElement];
        if( indexPath ) {
            *position = indexPath.row;
            *count = [cv numberOfItemsInSection:indexPath.section];
        }
    }
    else if( [self.uiElement isKindOfClass:UIBarButtonItem.class] && [self.parentView isKindOfClass:UINavigationBar.class] ) {
        UINavigationBar* navBar = (UINavigationBar*)self.parentView;
        if( navBar ) {
            *position = [navBar.items indexOfObject:self.uiElement];
            *count = navBar.items.count;
        }
    }
    else if( [self.uiElement isKindOfClass:UIBarButtonItem.class] && [self.parentView isKindOfClass:UIToolbar.class] ) {
        UIToolbar* toolbar = (UIToolbar*)self.parentView;
        if( toolbar ) {
            *position = [toolbar.items indexOfObject:self.uiElement];
            *count = toolbar.items.count;
        }
    }
    else if( self.parentView ) {
        Class uiKitClass = [ISSPropertyDefinition canonicalTypeClassForViewClass:[self.uiElement class]];
        for(UIView* v in self.parentView.subviews) {
            if( [v.class isSubclassOfClass:uiKitClass] ) {
                if( v == self.uiElement ) *position = *count;
                (*count)++;
            }
        }
    }
}

@end
