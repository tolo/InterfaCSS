//
//  UITableView+InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-04.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

/**
 * `UITableView` category that adds support for dequeuing `UITableViewCells`, using a prototype defined in a view definition file.
 */
@interface UITableView (InterfaCSS)

/**
 * Dequeues a table view cell using `-[UITableView dequeueReusableCellWithIdentifier:]`, or creates one based on the prototype with the specified name,
 * using the method `-[InterfaCSS viewFromPrototypeWithName:]`.
 */
- (id) dequeueReusablePrototypeCellWithIdentifierISS:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath;

/**
 * Dequeues a table view header/footer using `-[UITableView dequeueReusableHeaderFooterViewWithIdentifier:]`, or creates one based on the prototype with the
 * specified name, using the method `-[InterfaCSS viewFromPrototypeWithName:]`.
 */
- (id) dequeueReusablePrototypeHeaderFooterViewWithIdentifierISS:(NSString*)prototypeName;

@end
