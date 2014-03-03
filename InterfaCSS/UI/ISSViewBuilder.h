//
//  ISSViewBuilder.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-12-07.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSRootView.h" // Import this here to avoid users having to import this file as well when using methods like rootViewWithStyle...

typedef NSArray* (^SubViewBlock)();

id InterfaCSS_BuildComponent(NSString* styleClassName);
id InterfaCSS_BuildView(NSString* styleClassName, SubViewBlock subViewBlock);

id InterfaCSS_SetupComponent(UIView* theView, NSString* styleClassName);
id InterfaCSS_SetupView(UIView* theView, NSString* styleClassName, SubViewBlock subViewBlock);


@interface ISSViewBuilder : NSObject


+ (id) setupView:(UIView*)theView withStyleClass:(NSString*)styleClassName;
+ (id) setupView:(UIView*)theView withStyleClass:(NSString*)styleClassName andSubViews:(SubViewBlock)subViewBlock;


/**
 * Creates a view of class ISSRootView, intended to serve as the root view of a view controller.
 */
+ (ISSRootView*) rootViewWithStyle:(NSString*)styleClass;
+ (ISSRootView*) rootViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;

+ (ISSRootView*) loadViewHierarchyFromMainBundleFile:(NSString*)fileName withFileOwner:(id)fileOwner;
+ (ISSRootView*) loadViewHierarchyFromFile:(NSString*)fileName fileOwner:(id)fileOwner;


+ (UIView*) viewWithStyle:(NSString*)styleClass;
+ (UIView*) viewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;

+ (UICollectionView*) collectionViewWithStyle:(NSString*)styleClass;
+ (UICollectionView*) collectionViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;

+ (UIImageView*) imageViewWithStyle:(NSString*)styleClass;
+ (UIImageView*) imageViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;

+ (UIScrollView*) scrollViewWithStyle:(NSString*)styleClass;
+ (UIScrollView*) scrollViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;

+ (UITableView*) tableViewWithStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle;
+ (UITableView*) tableViewWithStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(SubViewBlock)subViewBlock;

+ (UIWebView*) webViewWithStyle:(NSString*)styleClass;
+ (UIWebView*) webViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock;



+ (UIButton*) buttonWithStyle:(NSString*)styleClass;
+ (UIButton*) buttonWithStyle:(NSString*)styleClass andButtonType:(UIButtonType)buttonType;

+ (UILabel*) labelWithStyle:(NSString*)styleClass;

+ (UIProgressView*) progressViewWithStyle:(NSString*)styleClass;

+ (UISlider*) sliderWithStyle:(NSString*)styleClass;

+ (UIStepper*) stepperWithStyle:(NSString*)styleClass;

+ (UISwitch*) switchWithStyle:(NSString*)styleClass;

+ (UITextField*) textFieldWithStyle:(NSString*)styleClass;

+ (UITextView*) textViewWithStyle:(NSString*)styleClass;


+ (UITableViewCell*) tableViewCellWithStyle:(NSString*)styleClass andReuseIdentifier:(NSString*)reuseIdentifier;

+ (UITableViewCell*) tableViewCellWithStyle:(NSString*)styleClass andCellStyle:(UITableViewCellStyle)cellStyle andReuseIdentifier:(NSString*)reuseIdentifier;


@end
