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

@implementation UITableView (InterfaCSS)

- (id) dequeueReusablePrototypeCellWithIdentifierISS:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath {
    id cell = [self dequeueReusableCellWithIdentifier:prototypeName];
    cell = cell ?: [[InterfaCSS interfaCSS] viewFromPrototypeWithName:prototypeName];
    ISSUIElementDetails* elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:cell];
    elementDetails.additionalDetails[ISSTableViewCellIndexPathKey] = indexPath;
    return cell;
}

- (id) dequeueReusablePrototypeHeaderFooterViewWithIdentifierISS:(NSString*)prototypeName {
    id cell = [self dequeueReusableHeaderFooterViewWithIdentifier:prototypeName];
    return cell ?: [[InterfaCSS interfaCSS] viewFromPrototypeWithName:prototypeName];
}

@end
