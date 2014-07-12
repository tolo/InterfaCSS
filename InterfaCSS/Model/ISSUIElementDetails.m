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


@interface ISSUIElementDetails ()

@property (nonatomic, strong, readwrite) NSString* elementStyleIdentity;
@property (nonatomic, strong) NSString* canonicalTypeAndClasses;
@property (nonatomic, strong) NSMutableDictionary* additionalDetails;
@property (nonatomic) BOOL usingCustomElementStyleIdentity;

@end

@implementation ISSUIElementDetails

#pragma mark - Lifecycle

- (id) initWithUIElement:(id)uiElement {
    self = [super init];
    if (self) {
        _uiElement = uiElement;
        if( [uiElement isKindOfClass:[UIView class]] ) {
            UIView* view = (UIView*)uiElement;
            _parentView = view.superview;
        }

        _canonicalType = [ISSPropertyDefinition canonicalTypeClassForViewClass:[self.uiElement class]];
        if( !_canonicalType ) _canonicalType = [uiElement class];

        [self updateElementStyleIdentity];
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

    copy.canonicalTypeAndClasses = self.canonicalTypeAndClasses;
    //copy.elementStyleIdentity = self.elementStyleIdentity; // Computed, need not be copied
    copy.usingCustomElementStyleIdentity = self.usingCustomElementStyleIdentity;

    copy.stylingApplied = self.stylingApplied;
    copy.stylingDisabled = self.stylingDisabled;

    copy.willApplyStylingBlock = self.willApplyStylingBlock;
    copy.didApplyStylingBlock = self.didApplyStylingBlock;

    copy->_additionalDetails = self->_additionalDetails;

    return copy;
}


#pragma mark - Utils

- (id) findParent:(UIView*)parentView ofClass:(Class)class {
    if( !parentView ) return nil;
    else if( [parentView isKindOfClass:class] ) return parentView;
    else return [self findParent:parentView.superview ofClass:class];
}

- (void) updateElementStyleIdentity {
    if( self.styleClasses ) {
        NSArray* styleClasses = [[self.styleClasses allObjects] sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
            return [obj1 compare:obj2];
        }];
        NSMutableString* str = [NSMutableString stringWithString:NSStringFromClass(self.canonicalType)];
        [str appendString:@"["];
        [str appendString:[styleClasses componentsJoinedByString:@","]];
        [str appendString:@"]"];
        self.canonicalTypeAndClasses = [str copy];
    } else {
        self.canonicalTypeAndClasses = NSStringFromClass(self.canonicalType);
    }

    self.elementStyleIdentity = nil;
}

+ (void) buildElementStyleIdentityPath:(NSMutableString*)identityPath element:(ISSUIElementDetails*)element {
    if( element.parentView ) [self buildElementStyleIdentityPath:identityPath element:[[InterfaCSS interfaCSS] detailsForUIElement:element.parentView]];
    if( identityPath.length ) [identityPath appendString:@" "];
    [identityPath appendString:element.canonicalTypeAndClasses];
}


#pragma mark - Public interface

- (BOOL) addedToViewHierarchy {
    return self.parentView.window || (self.parentView.class == UIWindow.class) || (self.view.class == UIWindow.class);
}

- (void) resetCachedData {
    if( !self.usingCustomElementStyleIdentity ) self.elementStyleIdentity = nil;
    self.stylingApplied = NO;
}

- (UIView*) view {
    return [self.uiElement isKindOfClass:UIView.class] ? self.uiElement : nil;
}

- (void) setStyleClasses:(NSSet*)styleClasses {
    _styleClasses = styleClasses;
    [self updateElementStyleIdentity];
}

- (void) setCustomElementStyleIdentity:(NSString*)identityPath {
    self.usingCustomElementStyleIdentity = identityPath != nil;
    self.elementStyleIdentity = identityPath;
}

- (NSString*) elementStyleIdentity {
    NSString* path = _elementStyleIdentity;
    if( !path ) {
        NSMutableString* identityPath = [NSMutableString string];
        [self.class buildElementStyleIdentityPath:identityPath element:self];
        path = [identityPath copy];
        if( self.parentView && self.parentView.window ) {
            _elementStyleIdentity = path;
        }
    }
    return path;
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
