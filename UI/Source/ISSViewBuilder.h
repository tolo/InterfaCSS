//
//  ISSViewBuilder.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#import "ISSRootView.h" // Import this here to avoid users having to import this file as well when using methods like rootViewWithStyle...



NS_ASSUME_NONNULL_BEGIN


typedef NSArray* _Nonnull (^SubViewBlock)();

/**
 * Factory class that enables building of view hierarchies in a concise and convenient way. Note that all the methods of this class support setting multiple
 * style classes in the `styleClassName` parameter, by separating them with a space.
 *
 * To enable the use of a shorthand syntax, define the macro `ISS_VIEW_BUILDER_SHORTHAND_ENABLED`.
 */
@interface ISSViewBuilder : NSObject


/** Sets up the specified view by adding the specified style class(es) to it. */
+ (id) setupView:(UIView*)theView withStyleClass:(nullable NSString*)styleClassName;
/** Sets up the specified view by assigning it the specified element id and adding the specified style class(es) to it. */
+ (id) setupView:(UIView*)theView withId:(nullable NSString*)elementId andStyleClass:(nullable NSString*)styleClassName;

/** Sets up the specified view by adding the specified style class(es) and subviews, via a `SubViewBlock`. */
+ (id) setupView:(UIView*)theView withStyleClass:(nullable NSString*)styleClassName andSubViews:(nullable SubViewBlock)subViewBlock;
/** Sets up the specified view by assigning it the specified element id adding the specified view class(es) and subviews, via a `SubViewBlock`. */
+ (id) setupView:(UIView*)theView withId:(nullable NSString*)elementId andStyleClass:(nullable NSString*)styleClassName andSubViews:(nullable SubViewBlock)subViewBlock;


/** Creates a view of class ISSRootView, intended to serve as the root view of a view controller. */
+ (ISSRootView*) rootViewWithStyle:(nullable NSString*)styleClass;
/** Creates a view of class ISSRootView, intended to serve as the root view of a view controller. */
+ (ISSRootView*) rootViewWithId:(nullable NSString*)elementId;

/** Creates a view of class ISSRootView, intended to serve as the root view of a view controller. Adds the subviews from the specified `SubViewBlock`. */
+ (ISSRootView*) rootViewWithStyle:(nullable NSString*)styleClass andSubViews:(nullable SubViewBlock)subViewBlock;
/** Creates a view of class ISSRootView, intended to serve as the root view of a view controller. Adds the subviews from the specified `SubViewBlock`. */
+ (ISSRootView*) rootViewWithId:(nullable NSString*)elementId andSubViews:(nullable SubViewBlock)subViewBlock;

/**
 * Creates a view of class ISSRootView, intended to serve as the root view of a view controller. If `owner` is specified, this method will attempt to auto populate 
 * properties for any views with an element id, created via the `SubViewBlock`.
 */
+ (ISSRootView*) rootViewWithStyle:(nullable NSString*)styleClass withOwner:(nullable id)owner andSubViews:(nullable SubViewBlock)subViewBlock;
/**
 * Creates a view of class ISSRootView, intended to serve as the root view of a view controller. If `owner` is specified, this method will attempt to auto populate
 * properties for any views with an element id, created via the `SubViewBlock`.
 */
+ (ISSRootView*) rootViewWithId:(nullable NSString*)elementId withOwner:(nullable id)owner andSubViews:(nullable SubViewBlock)subViewBlock;

/**
 * Creates a view of class ISSRootView, intended to serve as the root view of a view controller. If `owner` is specified, this method will attempt to auto populate
 * properties for any views with an element id, created via the `SubViewBlock`.
 */
+ (ISSRootView*) rootViewWithId:(nullable NSString*)elementId andStyleClass:(nullable NSString*)styleClass withOwner:(nullable id)owner andSubViews:(nullable SubViewBlock)subViewBlock;


/**
 * Loads a view hierarchy from the specified view definition XML file in the main bundle. Specifying a value for the `fileOwner` will enable setting
 * properties identified in the file.
 */
+ (ISSRootView*) loadViewHierarchyFromMainBundleFile:(NSString*)fileName fileOwner:(id)fileOwner;
/**
 * Loads a view hierarchy from the specified view definition XML file in the main bundle. Specifying a value for the `fileOwner` will enable setting
 * properties identified in the file. If `wrapRoot` is YES, the root view in the file will be wrapped in an `ISSRootView`.
 */
+ (ISSRootView*) loadViewHierarchyFromMainBundleFile:(NSString*)fileName fileOwner:(id)fileOwner wrapRoot:(BOOL)wrapRoot;

/**
 * Loads a view hierarchy from the specified view definition XML file in the local file system. Specifying a value for the `fileOwner` will enable setting
 * properties identified in the file.
 */
+ (ISSRootView*) loadViewHierarchyFromFile:(NSString*)fileName fileOwner:(id)fileOwner;
/**
 * Loads a view hierarchy from the specified view definition XML file in the local file system. Specifying a value for the `fileOwner` will enable setting
 * properties identified in the file. If `wrapRoot` is YES, the root view in the file will be wrapped in an `ISSRootView`.
 */
+ (ISSRootView*) loadViewHierarchyFromFile:(NSString*)fileName fileOwner:(id)fileOwner wrapRoot:(BOOL)wrapRoot;


/** Builds a `UIView` with the specified style class. */
+ (UIView*) viewWithStyle:(NSString*)styleClass;
/** Builds a `UIView` with the specified element id. */
+ (UIView*) viewWithId:(NSString*)elementId;

/** Builds a `UIView` with the specified style class and adds the subviews from the specified `SubViewBlock`. */
+ (UIView*) viewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;
/** Builds a `UIView` with the element id and adds the subviews from the specified `SubViewBlock`. */
+ (UIView*) viewWithId:(NSString*)elementId andSubViews:(SubViewBlock)subViewBlock;

/** Builds a view of the specified implementation class and style class. */
+ (UIView*) viewOfClass:(Class)clazz withStyle:(nullable NSString*)styleClass;
/** Builds a view of the specified implementation class and element id. */
+ (UIView*) viewOfClass:(Class)clazz withId:(nullable NSString*)elementId;
/** Builds a view of the specified implementation class, element id and style class. */
+ (UIView*) viewOfClass:(Class)clazz withId:(nullable NSString*)elementId andStyle:(nullable NSString*)styleClass;

/** Builds a view of the specified implementation class and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UIView*) viewOfClass:(Class)clazz withStyle:(nullable NSString*)styleClass andSubViews:(nullable SubViewBlock)subViewBlock;
/** Builds a view of the specified implementation class, element id and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UIView*) viewOfClass:(Class)clazz withId:(nullable NSString*)elementId andStyle:(nullable NSString*)styleClass andSubViews:(nullable SubViewBlock)subViewBlock;


/** Builds a `UICollectionView` with the specified style class. */
+ (UICollectionView*) collectionViewWithStyle:(NSString*)styleClass;
/** Builds a `UICollectionView` with the specified element id. */
+ (UICollectionView*) collectionViewWithId:(NSString*)elementId;

/** Builds a `UICollectionView` with the specified style class and adds the subviews from the specified `SubViewBlock`. */
+ (UICollectionView*) collectionViewWithStyle:(NSString*)styleClass andSubViews:(nullable SubViewBlock)subViewBlock;

/** Builds a `UICollectionView` with the specified implementation class and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UICollectionView*) collectionViewOfClass:(nullable Class)clazz withStyle:(nullable NSString*)styleClass andSubViews:(nullable SubViewBlock)subViewBlock;

/** Builds a `UICollectionView` with the specified implementation class, collection view layout class and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UICollectionView*) collectionViewOfClass:(nullable Class)clazz collectionViewLayoutClass:(nullable Class)collectionViewLayoutClass withStyle:(nullable NSString*)styleClass andSubViews:(nullable SubViewBlock)subViewBlock;
/** Builds a `UICollectionView` with the specified implementation class, collection view layout class, element id and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UICollectionView*) collectionViewOfClass:(nullable Class)clazz collectionViewLayoutClass:(nullable Class)collectionViewLayoutClass withId:(nullable NSString*)elementId andStyle:(nullable NSString*)styleClass andSubViews:(nullable SubViewBlock)subViewBlock;


/** Builds a `UIImageView` with the specified style class. */
+ (UIImageView*) imageViewWithStyle:(NSString*)styleClass;
/** Builds a `UIImageView` with the specified element id. */
+ (UIImageView*) imageViewWithWithId:(NSString*)elementId;

/** Builds a `UIImageView` with the specified style class and adds the subviews from the specified `SubViewBlock`. */
+ (UIImageView*) imageViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;
/** Builds a `UIImageView` with the specified element id and adds the subviews from the specified `SubViewBlock`. */
+ (UIImageView*) imageViewWithId:(nullable NSString*)elementId andStyle:(nullable NSString*)styleClass andSubViews:(nullable SubViewBlock)subViewBlock;


/** Builds a `UIScrollView` with the specified style class. */
+ (UIScrollView*) scrollViewWithStyle:(NSString*)styleClass;
/** Builds a `UIScrollView` with the specified element id. */
+ (UIScrollView*) scrollViewWithId:(NSString*)elementId;

/** Builds a `UIScrollView` with the specified style class and adds the subviews from the specified `SubViewBlock`. */
+ (UIScrollView*) scrollViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;
/** Builds a `UIScrollView` with the specified element id and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UIScrollView*) scrollViewWithId:(nullable NSString*)elementId andStyle:(nullable NSString*)styleClass andSubViews:(nullable SubViewBlock)subViewBlock;


/** Builds a `UITableView` with the specified style class. */
+ (UITableView*) tableViewWithStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle;
/** Builds a `UITableView` with the specified element id. */
+ (UITableView*) tableViewWithId:(NSString*)elementId andTableViewStyle:(UITableViewStyle)tableViewStyle;

/** Builds a `UITableView` with the specified style class and adds the subviews from the specified `SubViewBlock`. */
+ (UITableView*) tableViewWithStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(SubViewBlock)subViewBlock;
/** Builds a `UITableView` with the specified element id and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UITableView*) tableViewWithId:(NSString*)elementId andStyle:(nullable NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(SubViewBlock)subViewBlock;

/** Builds a `UITableView` with the specified implementation class and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UITableView*) tableViewOfClass:(nullable Class)clazz withStyle:(nullable NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(nullable SubViewBlock)subViewBlock;
/** Builds a `UITableView` with the specified implementation class, element id and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UITableView*) tableViewOfClass:(nullable Class)clazz withId:(nullable NSString*)elementId andStyle:(nullable NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(nullable SubViewBlock)subViewBlock;

#if TARGET_OS_TV == 0
/** Builds a `UIWebView` with the specified style class. */
+ (UIWebView*) webViewWithStyle:(NSString*)styleClass;
/** Builds a `UIWebView` with the specified element id. */
+ (UIWebView*) webViewWithId:(NSString*)elementId;

/** Builds a `UIWebView` with the specified style class and adds the subviews from the specified `SubViewBlock`. */
+ (UIWebView*) webViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;
/** Builds a `UIWebView` with the specified element id and style class, and adds the subviews from the specified `SubViewBlock`. */
+ (UIWebView*) webViewWithId:(nullable NSString*)elementId andStyle:(nullable NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;
#endif

/** Builds a `UIActivityIndicatorView` with the specified style class. */
+ (UIActivityIndicatorView*) activityIndicatorViewWithStyle:(NSString*)styleClass;
/** Builds a `UIActivityIndicatorView` with the specified element id. */
+ (UIActivityIndicatorView*) activityIndicatorViewWithId:(NSString*)elementId;

/** Builds a `UIButton` with the specified style class. */
+ (UIButton*) buttonWithStyle:(NSString*)styleClass;
/** Builds a `UIButton` with the specified element id. */
+ (UIButton*) buttonWithId:(NSString*)elementId;

/** Builds a `UIButton` with the specified style class. */
+ (UIButton*) buttonWithStyle:(NSString*)styleClass andButtonType:(UIButtonType)buttonType;
/** Builds a `UIButton` with the specified element id. */
+ (UIButton*) buttonWithId:(NSString*)elementId andButtonType:(UIButtonType)buttonType;

/** Builds a `UILabel` with the specified style class. */
+ (UILabel*) labelWithStyle:(NSString*)styleClass;
/** Builds a `UILabel` with the specified element id. */
+ (UILabel*) labelWithId:(NSString*)elementId;

/** Builds a `UIProgressView` with the specified style class. */
+ (UIProgressView*) progressViewWithStyle:(NSString*)styleClass;
/** Builds a `UIProgressView` with the specified element id. */
+ (UIProgressView*) progressViewWithId:(NSString*)elementId;

#if TARGET_OS_TV == 0
/** Builds a `UISlider` with the specified style class. */
+ (UISlider*) sliderWithStyle:(NSString*)styleClass;
/** Builds a `UISlider` with the specified element id. */
+ (UISlider*) sliderWithId:(NSString*)elementId;

/** Builds a `UIStepper` with the specified style class. */
+ (UIStepper*) stepperWithStyle:(NSString*)styleClass;
/** Builds a `UIStepper` with the specified element id. */
+ (UIStepper*) stepperWithId:(NSString*)elementId;

/** Builds a `UISwitch` with the specified style class. */
+ (UISwitch*) switchWithStyle:(NSString*)styleClass;
/** Builds a `UISwitch` with the specified element id. */
+ (UISwitch*) switchWithId:(NSString*)elementId;
#endif

/** Builds a `UITextField` with the specified style class. */
+ (UITextField*) textFieldWithStyle:(NSString*)styleClass;
/** Builds a `UITextField` with the specified element id. */
+ (UITextField*) textFieldWithId:(NSString*)elementId;

/** Builds a `UITextView` with the specified style class. */
+ (UITextView*) textViewWithStyle:(NSString*)styleClass;
/** Builds a `UITextView` with the specified element id. */
+ (UITextView*) textViewWithId:(NSString*)elementId;

/** Builds a `UITableViewCell` with the specified style class. */
+ (UITableViewCell*) tableViewCellWithStyle:(NSString*)styleClass andReuseIdentifier:(NSString*)reuseIdentifier;

/** Builds a `UITableViewCell` with the specified style class. */
+ (UITableViewCell*) tableViewCellWithStyle:(NSString*)styleClass andCellStyle:(UITableViewCellStyle)cellStyle andReuseIdentifier:(NSString*)reuseIdentifier;

@end


NS_ASSUME_NONNULL_END
