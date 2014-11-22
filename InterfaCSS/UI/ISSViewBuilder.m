//
//  ISSViewBuilder.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-12-07.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//


#import "ISSViewBuilder.h"

#import "UIView+InterfaCSS.h"
#import "NSString+ISSStringAdditions.h"
#import "ISSViewHierarchyParser.h"


@implementation ISSViewBuilder


#pragma mark - View setup

// + (id) setupView:(UIView*)theView withStyleClass:(NSString*)styleClassName andSubViews:(SubViewBlock)subViewBlock andPropertyOwner:(id)propertyOwner {

+ (id) setupView:(UIView*)theView withStyleClass:(NSString*)styleClassName andSubViews:(SubViewBlock)subViewBlock {
    if( styleClassName ) {
        NSArray* styles = [styleClassName iss_splitOnSpaceOrComma];
        for(NSString* style in styles) [theView addStyleClassISS:style];
    }
    
    if( subViewBlock ) {
        NSArray* subViews = subViewBlock();
        for(UIView* subView in subViews) [theView addSubview:subView];
    }
    return theView;
}

+ (id) setupView:(UIView*)theView withStyleClass:(NSString*)styleClassName {
    return [self setupView:theView withStyleClass:styleClassName andSubViews:nil];
}


#pragma mark - Containers

+ (ISSRootView*) rootViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[ISSRootView alloc] init] withStyleClass:styleClass];
}

+ (ISSRootView*) rootViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[ISSRootView alloc] init] withStyleClass:styleClass andSubViews:subViewBlock];
}

+ (ISSRootView*) loadViewHierarchyFromMainBundleFile:(NSString*)fileName withFileOwner:(id)fileOwner {
    NSURL* url = [[NSBundle mainBundle] URLForResource:fileName withExtension:nil];
    NSData* fileData = [NSData dataWithContentsOfURL:url];
    return [ISSViewHierarchyParser parseViewHierarchyFromData:fileData withFileOwner:fileOwner];
}

+ (ISSRootView*) loadViewHierarchyFromFile:(NSString*)fileName fileOwner:(id)fileOwner {
    NSData* fileData = [NSData dataWithContentsOfFile:fileName];
    return [ISSViewHierarchyParser parseViewHierarchyFromData:fileData withFileOwner:fileOwner];
}

+ (UIView*) viewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIView alloc] init] withStyleClass:styleClass];
}

+ (UIView*) viewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UIView alloc] init] withStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UIView*) viewOfClass:(Class)clazz withStyle:(NSString*)styleClass {
    return [self viewOfClass:clazz withStyle:styleClass andSubViews:nil];
}

+ (UIView*) viewOfClass:(Class)clazz withStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    clazz = clazz ?: UIView.class;
    if( [clazz isSubclassOfClass:UICollectionView.class] ) {
        return [self collectionViewOfClass:clazz withStyle:styleClass andSubViews:subViewBlock];
    } else {
        return [self setupView:(UIView*)[[clazz alloc] init] withStyleClass:styleClass andSubViews:subViewBlock];
    }
}

+ (UICollectionView*) collectionViewWithStyle:(NSString*)styleClass {
    return [self collectionViewOfClass:nil withStyle:styleClass andSubViews:nil];
}

+ (UICollectionView*) collectionViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self collectionViewOfClass:nil withStyle:styleClass andSubViews:subViewBlock];
}

+ (UICollectionView*) collectionViewOfClass:(Class)clazz withStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self collectionViewOfClass:nil collectionViewLayoutClass:UICollectionViewFlowLayout.class withStyle:styleClass andSubViews:subViewBlock];
}

+ (UICollectionView*) collectionViewOfClass:(Class)clazz collectionViewLayoutClass:(Class)collectionViewLayoutClass withStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    clazz = clazz ?: UICollectionView.class;
    return [self setupView:[(UICollectionView*)[clazz alloc] initWithFrame:CGRectZero collectionViewLayout:(UICollectionViewLayout*)[[collectionViewLayoutClass alloc] init]] withStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UIImageView*) imageViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIImageView alloc] init] withStyleClass:styleClass];
}

+ (UIImageView*) imageViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UIImageView alloc] init] withStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UIScrollView*) scrollViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIScrollView alloc] init] withStyleClass:styleClass];
}

+ (UIScrollView*) scrollViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UIScrollView alloc] init] withStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UITableView*) tableViewWithStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle {
    return [self tableViewOfClass:nil withStyle:styleClass andTableViewStyle:tableViewStyle andSubViews:nil];
}

+ (UITableView*) tableViewWithStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(SubViewBlock)subViewBlock {
    return [self tableViewOfClass:nil withStyle:styleClass andTableViewStyle:tableViewStyle andSubViews:subViewBlock];
}

+ (UITableView*) tableViewOfClass:(Class)clazz withStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(SubViewBlock)subViewBlock {
    clazz = clazz ?: UITableView.class;
    return [self setupView:[(UITableView*)[clazz alloc] initWithFrame:CGRectZero style:tableViewStyle] withStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UIWebView*) webViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIWebView alloc] init] withStyleClass:styleClass];
}

+ (UIWebView*) webViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UIWebView alloc] init] withStyleClass:styleClass andSubViews:subViewBlock];
}


#pragma mark - Components

+ (UIActivityIndicatorView*) activityIndicatorViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIActivityIndicatorView alloc] init] withStyleClass:styleClass];
}

+ (UIButton*) buttonWithStyle:(NSString*)styleClass {
    return [self setupView:[UIButton buttonWithType:UIButtonTypeCustom] withStyleClass:styleClass];
}

+ (UIButton*) buttonWithStyle:(NSString*)styleClass andButtonType:(UIButtonType)buttonType {
    return [self setupView:[UIButton buttonWithType:buttonType] withStyleClass:styleClass];
}

+ (UILabel*) labelWithStyle:(NSString*)styleClass {
    return [self setupView:[[UILabel alloc] init] withStyleClass:styleClass];
}

+ (UIProgressView*) progressViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIProgressView alloc] init] withStyleClass:styleClass];
}

+ (UISlider*) sliderWithStyle:(NSString*)styleClass {
    return [self setupView:[[UISlider alloc] init] withStyleClass:styleClass];
}

+ (UIStepper*) stepperWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIStepper alloc] init] withStyleClass:styleClass];
}

+ (UISwitch*) switchWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIStepper alloc] init] withStyleClass:styleClass];
}

+ (UITextField*) textFieldWithStyle:(NSString*)styleClass {
    return [self setupView:[[UITextField alloc] init] withStyleClass:styleClass];
}

+ (UITextView*) textViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UITextView alloc] init] withStyleClass:styleClass];
}

+ (UITextField*) textFieldWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UITextField alloc] init] withStyleClass:styleClass andSubViews:subViewBlock];
}


+ (UITableViewCell*) tableViewCellWithStyle:(NSString*)styleClass andReuseIdentifier:(NSString*)reuseIdentifier {
    return [self setupView:[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] withStyleClass:styleClass];
}

+ (UITableViewCell*) tableViewCellWithStyle:(NSString*)styleClass andCellStyle:(UITableViewCellStyle)cellStyle andReuseIdentifier:(NSString*)reuseIdentifier {
    return [self setupView:[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:reuseIdentifier] withStyleClass:styleClass];
}

@end
