//
//  UICollectionView+InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

NS_ASSUME_NONNULL_BEGIN

/**
 * Category that adds InterfaCSS integration to `UICollectionView`.
 */
@interface UICollectionView (InterfaCSS)

/**
 * Dequeues a collection view cell (using `-[UICollectionView dequeueReusableCellWithReuseIdentifier:forIndexPath:]`) and associates it with the specified indexPath.
 * This is necessary when using structural pseudo class selectors for table view cell.
 */
- (id) dequeueReusableCellWithReuseIdentifierISS:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath;

/**
 * Dequeues a collection view cell (using `dequeueReusableCellWithReuseIdentifierISS:forIndexPath:`), and initializes it from a registered prototype.
 */
- (id) dequeueReusablePrototypeCellWithReuseIdentifierISS:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath;

/**
 * Dequeues a collection view supplementary view (using `-[UICollectionView dequeueReusableSupplementaryViewOfKind:withReuseIdentifier:forIndexPath:]`) and associates it with the specified indexPath.
 * This is necessary when using structural pseudo class selectors for table view cell.
 */
- (id) dequeueReusableSupplementaryViewOfKindISS:(NSString*)elementKind withReuseIdentifier:(NSString*)reuseIdentifier forIndexPath:(NSIndexPath*)indexPath;

/**
 * Dequeues a collection view supplementary view (using `dequeueReusableSupplementaryViewOfKindISS:withReuseIdentifier:forIndexPath:`), and initializes it from a registered prototype.
 */
- (id) dequeueReusableSupplementaryPrototypeViewOfKindISS:(NSString*)elementKind withReuseIdentifier:(NSString*)prototypeName forIndexPath:(NSIndexPath*)indexPath;

@end

NS_ASSUME_NONNULL_END
