//
//  UITableView+InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-04.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@interface UITableView (InterfaCSS)

- (id) dequeueReusablePrototypeCellWithIdentifierISS:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath;

- (id) dequeueReusablePrototypeHeaderFooterViewWithIdentifierISS:(NSString*)prototypeName;

@end
