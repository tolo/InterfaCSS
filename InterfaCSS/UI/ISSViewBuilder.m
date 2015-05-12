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
#import "ISSRuntimeIntrospectionUtils.h"


@implementation ISSViewBuilder


#pragma mark - View setup

+ (id) setupView:(UIView*)theView withId:(NSString*)elementId andStyleClass:(NSString*)styleClassName andSubViews:(SubViewBlock)subViewBlock {
    if( elementId ) {
        theView.elementIdISS = elementId;
    }
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

+ (id) setupView:(UIView*)theView withId:(NSString*)elementId andStyleClass:(NSString*)styleClassName {
    return [self setupView:theView withId:elementId andStyleClass:styleClassName andSubViews:nil];
}

+ (id) setupView:(UIView*)theView withStyleClass:(NSString*)styleClassName andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:theView withId:nil andStyleClass:styleClassName andSubViews:subViewBlock];
}

+ (id) setupView:(UIView*)theView withStyleClass:(NSString*)styleClassName {
    return [self setupView:theView withId:nil andStyleClass:styleClassName andSubViews:nil];
}


#pragma mark - Root views

+ (ISSRootView*) rootViewWithStyle:(NSString*)styleClass {
    return [self rootViewWithId:nil andStyleClass:styleClass withOwner:nil andSubViews:nil];
}

+ (ISSRootView*) rootViewWithId:(NSString*)elementId {
    return [self rootViewWithId:elementId andStyleClass:nil withOwner:nil andSubViews:nil];
}

+ (ISSRootView*) rootViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self rootViewWithId:nil andStyleClass:styleClass withOwner:nil andSubViews:subViewBlock];
}

+ (ISSRootView*) rootViewWithId:(NSString*)elementId andSubViews:(SubViewBlock)subViewBlock {
    return [self rootViewWithId:elementId andStyleClass:nil withOwner:nil andSubViews:subViewBlock];
}

+ (ISSRootView*) rootViewWithStyle:(NSString*)styleClass withOwner:(id)owner andSubViews:(SubViewBlock)subViewBlock {
    return [self rootViewWithId:nil andStyleClass:styleClass withOwner:owner andSubViews:subViewBlock];
}

+ (ISSRootView*) rootViewWithId:(NSString*)elementId withOwner:(id)owner andSubViews:(SubViewBlock)subViewBlock {
    return [self rootViewWithId:elementId andStyleClass:nil withOwner:owner andSubViews:subViewBlock];
}

+ (ISSRootView*) rootViewWithId:(NSString*)elementId andStyleClass:(NSString*)styleClass withOwner:(id)owner andSubViews:(SubViewBlock)subViewBlock {
    ISSRootView* rootView = [self setupView:[[ISSRootView alloc] init] withId:elementId andStyleClass:styleClass andSubViews:subViewBlock];
    if( owner ) [[InterfaCSS interfaCSS] autoPopulatePropertiesInViewHierarchyFromView:rootView inOwner:owner];
    return rootView;
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


#pragma mark - Containers

+ (UIView*) viewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIView alloc] init] withStyleClass:styleClass];
}

+ (UIView*) viewWithId:(NSString*)elementId {
    return [self setupView:[[UIView alloc] init] withId:elementId andStyleClass:nil];
}

+ (UIView*) viewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UIView alloc] init] withStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UIView*) viewWithId:(NSString*)elementId andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UIView alloc] init] withId:elementId andStyleClass:nil andSubViews:subViewBlock];
}

+ (UIView*) viewOfClass:(Class)clazz withStyle:(NSString*)styleClass {
    return [self viewOfClass:clazz withStyle:styleClass andSubViews:nil];
}

+ (UIView*) viewOfClass:(Class)clazz withId:(NSString*)elementId {
    return [self viewOfClass:clazz withId:elementId andStyle:nil andSubViews:nil];
}

+ (UIView*) viewOfClass:(Class)clazz withStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self viewOfClass:clazz withId:nil andStyle:styleClass andSubViews:subViewBlock];
}

+ (UIView*) viewOfClass:(Class)clazz withId:(NSString*)elementId andStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    clazz = clazz ?: UIView.class;
    if( [clazz isSubclassOfClass:UICollectionView.class] ) {
        return [self collectionViewOfClass:clazz withStyle:styleClass andSubViews:subViewBlock];
    } else {
        return [self setupView:(UIView*)[[clazz alloc] init] withId:elementId andStyleClass:styleClass andSubViews:subViewBlock];
    }
}

+ (UICollectionView*) collectionViewWithStyle:(NSString*)styleClass {
    return [self collectionViewOfClass:nil withStyle:styleClass andSubViews:nil];
}

+ (UICollectionView*) collectionViewWithId:(NSString *)elementId {
    return [self collectionViewOfClass:nil collectionViewLayoutClass:UICollectionViewFlowLayout.class withId:elementId andStyle:nil andSubViews:nil];
}

+ (UICollectionView*) collectionViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self collectionViewOfClass:nil withStyle:styleClass andSubViews:subViewBlock];
}

+ (UICollectionView*) collectionViewOfClass:(Class)clazz withStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self collectionViewOfClass:nil collectionViewLayoutClass:UICollectionViewFlowLayout.class withStyle:styleClass andSubViews:subViewBlock];
}

+ (UICollectionView*) collectionViewOfClass:(Class)clazz collectionViewLayoutClass:(Class)collectionViewLayoutClass withStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self collectionViewOfClass:clazz collectionViewLayoutClass:collectionViewLayoutClass withId:nil andStyle:styleClass andSubViews:subViewBlock];
}

+ (UICollectionView*) collectionViewOfClass:(Class)clazz collectionViewLayoutClass:(Class)collectionViewLayoutClass withId:(NSString*)elementId andStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    clazz = clazz ?: UICollectionView.class;
    return [self setupView:[(UICollectionView*)[clazz alloc] initWithFrame:CGRectZero collectionViewLayout:(UICollectionViewLayout*)[[collectionViewLayoutClass alloc] init]] withId:elementId andStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UIImageView*) imageViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIImageView alloc] init] withStyleClass:styleClass];
}

+ (UIImageView*) imageViewWithWithId:(NSString*)elementId {
    return [self setupView:[[UIImageView alloc] init] withId:elementId andStyleClass:nil];
}

+ (UIImageView*) imageViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self imageViewWithId:nil andStyle:styleClass andSubViews:subViewBlock];
}

+ (UIImageView*) imageViewWithId:(NSString*)elementId andStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UIImageView alloc] init] withId:elementId andStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UIScrollView*) scrollViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIScrollView alloc] init] withStyleClass:styleClass];
}

+ (UIScrollView*) scrollViewWithId:(NSString*)elementId {
    return [self setupView:[[UIScrollView alloc] init] withId:elementId andStyleClass:nil];
}

+ (UIScrollView*) scrollViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self scrollViewWithId:nil andStyle:styleClass andSubViews:subViewBlock];
}

+ (UIScrollView*) scrollViewWithId:(NSString*)elementId andStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UIScrollView alloc] init] withId:elementId andStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UITableView*) tableViewWithStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle {
    return [self tableViewOfClass:nil withStyle:styleClass andTableViewStyle:tableViewStyle andSubViews:nil];
}

+ (UITableView*) tableViewWithId:(NSString*)elementId andTableViewStyle:(UITableViewStyle)tableViewStyle {
    return [self tableViewOfClass:nil withId:elementId andStyle:nil andTableViewStyle:tableViewStyle andSubViews:nil];
}

+ (UITableView*) tableViewWithStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(SubViewBlock)subViewBlock {
    return [self tableViewOfClass:nil withStyle:styleClass andTableViewStyle:tableViewStyle andSubViews:subViewBlock];
}

+ (UITableView*) tableViewOfClass:(Class)clazz withStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(SubViewBlock)subViewBlock {
    return [self tableViewOfClass:clazz withId:nil andStyle:styleClass andTableViewStyle:tableViewStyle andSubViews:subViewBlock];
}

+ (UITableView*) tableViewOfClass:(Class)clazz withId:(NSString*)elementId andStyle:(NSString*)styleClass andTableViewStyle:(UITableViewStyle)tableViewStyle andSubViews:(SubViewBlock)subViewBlock {
    clazz = clazz ?: UITableView.class;
    return [self setupView:[(UITableView*)[clazz alloc] initWithFrame:CGRectZero style:tableViewStyle] withStyleClass:styleClass andSubViews:subViewBlock];
}

+ (UIWebView*) webViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIWebView alloc] init] withStyleClass:styleClass];
}

+ (UIWebView*) webViewWithId:(NSString*)elementId {
    return [self setupView:[[UIWebView alloc] init] withId:elementId andStyleClass:nil];
}

+ (UIWebView*) webViewWithStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self webViewWithId:nil andStyle:styleClass andSubViews:subViewBlock];
}

+ (UIWebView*) webViewWithId:(NSString*)elementId andStyle:(NSString*)styleClass andSubViews:(SubViewBlock)subViewBlock {
    return [self setupView:[[UIWebView alloc] init] withId:elementId andStyleClass:styleClass andSubViews:subViewBlock];
}


#pragma mark - Components

+ (UIActivityIndicatorView*) activityIndicatorViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIActivityIndicatorView alloc] init] withStyleClass:styleClass];
}

+ (UIActivityIndicatorView*) activityIndicatorViewWithId:(NSString*)elementId {
    return [self setupView:[[UIActivityIndicatorView alloc] init] withId:elementId andStyleClass:nil];
}

+ (UIButton*) buttonWithStyle:(NSString*)styleClass {
    return [self setupView:[UIButton buttonWithType:UIButtonTypeCustom] withStyleClass:styleClass];
}

+ (UIButton*) buttonWithId:(NSString*)elementId {
    return [self setupView:[UIButton buttonWithType:UIButtonTypeCustom] withId:elementId andStyleClass:nil];
}

+ (UIButton*) buttonWithStyle:(NSString*)styleClass andButtonType:(UIButtonType)buttonType {
    return [self setupView:[UIButton buttonWithType:buttonType] withStyleClass:styleClass];
}

+ (UILabel*) labelWithStyle:(NSString*)styleClass {
    return [self setupView:[[UILabel alloc] init] withStyleClass:styleClass];
}

+ (UILabel*) labelWithId:(NSString*)elementId {
    return [self setupView:[[UILabel alloc] init] withId:elementId andStyleClass:nil];
}

+ (UIProgressView*) progressViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIProgressView alloc] init] withStyleClass:styleClass];
}

+ (UIProgressView*) progressViewWithId:(NSString*)elementId {
    return [self setupView:[[UIProgressView alloc] init] withId:elementId andStyleClass:nil];
}

+ (UISlider*) sliderWithStyle:(NSString*)styleClass {
    return [self setupView:[[UISlider alloc] init] withStyleClass:styleClass];
}

+ (UISlider*) sliderWithId:(NSString*)elementId {
    return [self setupView:[[UISlider alloc] init] withId:elementId andStyleClass:nil];
}

+ (UIStepper*) stepperWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIStepper alloc] init] withStyleClass:styleClass];
}

+ (UIStepper*) stepperWithId:(NSString*)elementId {
    return [self setupView:[[UIStepper alloc] init] withId:elementId andStyleClass:nil];
}

+ (UISwitch*) switchWithStyle:(NSString*)styleClass {
    return [self setupView:[[UIStepper alloc] init] withStyleClass:styleClass];
}

+ (UISwitch*) switchWithId:(NSString*)elementId {
    return [self setupView:[[UIStepper alloc] init] withId:elementId andStyleClass:nil];
}

+ (UITextField*) textFieldWithStyle:(NSString*)styleClass {
    return [self setupView:[[UITextField alloc] init] withStyleClass:styleClass];
}

+ (UITextField*) textFieldWithId:(NSString*)elementId {
    return [self setupView:[[UITextField alloc] init] withId:elementId andStyleClass:nil];
}

+ (UITextView*) textViewWithStyle:(NSString*)styleClass {
    return [self setupView:[[UITextView alloc] init] withStyleClass:styleClass];
}

+ (UITextView*) textViewWithId:(NSString*)elementId {
    return [self setupView:[[UITextView alloc] init] withId:elementId andStyleClass:nil];
}


+ (UITableViewCell*) tableViewCellWithStyle:(NSString*)styleClass andReuseIdentifier:(NSString*)reuseIdentifier {
    return [self setupView:[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] withStyleClass:styleClass];
}

+ (UITableViewCell*) tableViewCellWithStyle:(NSString*)styleClass andCellStyle:(UITableViewCellStyle)cellStyle andReuseIdentifier:(NSString*)reuseIdentifier {
    return [self setupView:[[UITableViewCell alloc] initWithStyle:cellStyle reuseIdentifier:reuseIdentifier] withStyleClass:styleClass];
}

@end
