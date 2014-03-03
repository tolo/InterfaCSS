//
//  ISViewBuilderDSL.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2013-10-12.
//  Copyright (c) 2013 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#define container InterfaCSS_BuildView(@
#define rootContainer container
#define component InterfaCSS_BuildComponent(@

#define containerOfClass(clazz) InterfaCSS_SetupView([[clazz alloc] init], @
#define componentOfClass(clazz) InterfaCSS_SetupComponent([[clazz alloc] init], @
#define containerWith(obj) InterfaCSS_SetupView(obj, @
#define componentWith(obj) InterfaCSS_SetupComponent(obj, @
#define containerPreStyledWith(obj) InterfaCSS_SetupView(obj, nil
#define componentPreStyledWith(obj) InterfaCSS_SetupComponent(obj, nil

#define activityView InterfaCSS_SetupComponent([[UIActivityIndicatorView alloc] init], @
#define button InterfaCSS_SetupComponent([UIButton buttonWithType:UIButtonTypeCustom], @
#define buttonWithType(type) InterfaCSS_SetupComponent([UIButton buttonWithType:type], @
#define label InterfaCSS_SetupComponent([[UILabel alloc] init], @
#define progressView InterfaCSS_SetupComponent([[UIProgressView alloc] init], @
#define slider InterfaCSS_SetupComponent([[UISlider alloc] init], @
#define stepper InterfaCSS_SetupComponent([[UIStepper alloc] init], @
#define switch InterfaCSS_SetupComponent([[UISwitch alloc] init], @
#define textField InterfaCSS_SetupComponent([[UITextField alloc] init], @
#define textView InterfaCSS_SetupComponent([[UITextView alloc] init], @

#define collectionView InterfaCSS_SetupView([[UICollectionView alloc] init], @
#define imageView InterfaCSS_SetupView([[UIImageView alloc] init], @
#define scrollView InterfaCSS_SetupView([[UIScrollView alloc] init], @
#define tableView InterfaCSS_SetupView([[UITableView alloc] init], @
#define webView InterfaCSS_SetupView([[UIWebView alloc] init], @


#define noStyle ""

#define with ,
#define subviews ^{ return @[
#define and ),

#define endContainer ) ]; }
#define endRootContainer endContainer );
