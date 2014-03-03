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
#import "UIView+InterfaCSS.h"

@implementation UITableView (InterfaCSS)

- (id) dequeueReusablePrototypeCellWithIdentifier:(NSString*)prototypeName {
    id cell = [self dequeueReusableCellWithIdentifier:prototypeName];
    return cell ?: [[InterfaCSS interfaCSS] viewFromPrototypeWithName:prototypeName];
}

- (id) dequeueReusablePrototypeHeaderFooterViewWithIdentifier:(NSString*)prototypeName {
    id cell = [self dequeueReusableHeaderFooterViewWithIdentifier:prototypeName];
    return cell ?: [[InterfaCSS interfaCSS] viewFromPrototypeWithName:prototypeName];
}

@end
