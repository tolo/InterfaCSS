//
//  UICollectionView+InterfaCSS.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "UICollectionView+InterfaCSS.h"

#import "ISSUIElementDetails.h"
#import "UIView+ISSPrototypeReusableView.h"

@implementation UICollectionView (InterfaCSS)

- (id) dequeueReusableCellWithReuseIdentifierISS:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath {
    id cell = [self dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    ISSUIElementDetails* elementDetails = [[InterfaCSS sharedInstance] detailsForUIElement:cell];
    elementDetails.additionalDetails[ISSIndexPathKey] = indexPath;
    return cell;
}

- (id) dequeueReusablePrototypeCellWithReuseIdentifierISS:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath {
    UIView* cell = [self dequeueReusableCellWithReuseIdentifierISS:prototypeName forIndexPath:indexPath];
    [cell setupViewFromPrototypeRegisteredInViewISS:self];
    return cell;
}

- (id) dequeueReusableSupplementaryViewOfKindISS:(NSString*)elementKind withReuseIdentifier:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath {
    id cell = [self dequeueReusableSupplementaryViewOfKind:elementKind withReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    ISSUIElementDetails* elementDetails = [[InterfaCSS sharedInstance] detailsForUIElement:cell];
    elementDetails.additionalDetails[ISSIndexPathKey] = indexPath;
    return cell;
}

- (id) dequeueReusableSupplementaryPrototypeViewOfKindISS:(NSString*)elementKind withReuseIdentifier:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath {
    UIView* cell = [self dequeueReusableSupplementaryViewOfKindISS:elementKind withReuseIdentifier:prototypeName forIndexPath:indexPath];
    [cell setupViewFromPrototypeRegisteredInViewISS:self];
    return cell;
}

@end
