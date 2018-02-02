//
//  UITableView+InterfaCSS.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "UITableView+InterfaCSS.h"

#import "InterfaCSS.h"
#import "ISSElementStylingProxy.h"
#import "UIView+ISSPrototypeReusableView.h"

@implementation UITableView (InterfaCSS)

- (id) dequeueReusableCellWithIdentifierISS:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath {
    id cell = [self dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    ISSElementStylingProxy* elementDetails = [[InterfaCSS interfaCSS] stylingProxyFor:cell];
    elementDetails.additionalDetails[ISSIndexPathKey] = indexPath;
    return cell;
}

- (id) dequeueReusablePrototypeCellWithIdentifierISS:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath {
    UIView* cell = [self dequeueReusableCellWithIdentifierISS:prototypeName forIndexPath:indexPath];
    [cell setupViewFromPrototypeRegisteredInViewISS:self];
    return cell;
}

- (id) dequeueReusablePrototypeHeaderFooterViewWithIdentifierISS:(NSString*)prototypeName {
    UIView* view = [self dequeueReusableHeaderFooterViewWithIdentifier:prototypeName];
    [view setupViewFromPrototypeRegisteredInViewISS:self];
    return view;
}

@end
