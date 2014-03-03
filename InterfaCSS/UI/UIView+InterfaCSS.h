//
//  UIView+InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <UIKit/UIKit.h>

@interface UIView (InterfaCSS)

@property (nonatomic, weak) NSString* styleClass;
@property (nonatomic, weak) NSSet* styleClasses;

- (void) setStyleClasses:(NSSet*)classes;
- (void) setStyleClasses:(NSSet*)classes animated:(BOOL)animated;

- (void) setStyleClass:(NSString*)styleClass;
- (void) setStyleClass:(NSString*)styleClass animated:(BOOL)animated;

- (void) addStyleClass:(NSString*)styleClass;
- (void) addStyleClass:(NSString*)styleClass animated:(BOOL)animated;

- (void) removeStyleClass:(NSString*)styleClass;
- (void) removeStyleClass:(NSString*)styleClass animated:(BOOL)animated;

- (void) scheduleApplyStyling;
- (void) scheduleApplyStyling:(BOOL)animated;

- (void) applyStyling;
- (void) applyStyling:(BOOL)invalidateStyles;
- (void) applyStylingWithAnimation;

@end
