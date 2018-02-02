//
//  UITableView+InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Category that adds InterfaCSS integration to `UITableView`.
 */
@interface UITableView (InterfaCSS)

/**
 * Dequeues a table view cell (using `-[UITableView dequeueReusableCellWithIdentifier:forIndexPath:]`) and associates it with the specified indexPath.
 * This is necessary when using structural pseudo class selectors for table view cell.
 */
- (id) dequeueReusableCellWithIdentifierISS:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath;

/**
 * Dequeues a table view cell (using `dequeueReusableCellWithIdentifierISS:forIndexPath:`), and initializes it from a registered prototype.
 */
- (id) dequeueReusablePrototypeCellWithIdentifierISS:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath;

/**
 * Dequeues a table view header/footer (using `-[UITableView dequeueReusableHeaderFooterViewWithIdentifier:]`), or creates one based on the prototype with the
 * specified name, using the method `-[InterfaCSS viewFromPrototypeWithName:]`.
 */
- (id) dequeueReusablePrototypeHeaderFooterViewWithIdentifierISS:(NSString*)prototypeName;

@end

NS_ASSUME_NONNULL_END
