//
//  InterfaCSS
//  UICollectionView+InterfaCSS.h
//  
//  Created by Tobias Löfstrand on 2014-10-24.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//


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
