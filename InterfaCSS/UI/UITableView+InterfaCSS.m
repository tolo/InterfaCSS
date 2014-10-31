//
//  UITableView+InterfaCSS.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-04.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "UITableView+InterfaCSS.h"

#import "InterfaCSS.h"
#import "ISSUIElementDetails.h"
#import "UIView+ISSPrototypeView.h"

@implementation UITableView (InterfaCSS)

- (id) dequeueReusableCellWithIdentifierISS:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath {
    id cell = [self dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    ISSUIElementDetails* elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:cell];
    elementDetails.additionalDetails[ISSIndexPathKey] = indexPath;
    return cell;
}

- (id) dequeueReusablePrototypeCellWithIdentifierISS:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath {
    UIView* cell = [self dequeueReusableCellWithIdentifierISS:prototypeName forIndexPath:indexPath];
    [cell setupViewFromPrototypeISS];
    return cell;
}

- (id) dequeueReusablePrototypeHeaderFooterViewWithIdentifierISS:(NSString*)prototypeName {
    UIView* view = [self dequeueReusableHeaderFooterViewWithIdentifier:prototypeName];
    [view setupViewFromPrototypeISS];
    return view;
}

@end
