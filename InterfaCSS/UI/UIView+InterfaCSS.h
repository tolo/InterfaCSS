//
//  UIView+InterfaCSS.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

@interface UIView (InterfaCSS)

@property (nonatomic, strong, getter=getStyleClassISS, setter=setStyleClassISS:) NSString* styleClassISS;
@property (nonatomic, strong, getter=getStyleClassesISS, setter=setStyleClassesISS:) NSSet* styleClassesISS;

- (void) setStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;
- (void) setStyleClassesISS:(NSSet*)classes animated:(BOOL)animated;

- (BOOL) hasStyleClassISS:(NSString*)styleClass;

- (void) addStyleClassISS:(NSString*)styleClass;
- (void) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;

- (void) removeStyleClassISS:(NSString*)styleClass;
- (void) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;

- (void) scheduleApplyStylingISS;
- (void) scheduleApplyStylingISS:(BOOL)animated;

- (void) applyStylingISS;
- (void) applyStylingISS:(BOOL)invalidateStyles;
- (void) applyStylingWithAnimationISS;


/*

@property (nonatomic, strong, getter=getStyleClassISS, setter=setStyleClassISS:) NSString* styleClassISS;
@property (nonatomic, strong, getter=getStyleClassesISS, setter=setStyleClassesISS:) NSSet* styleClassesISS;

- (void) setStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;
- (void) setStyleClassesISS:(NSSet*)classes animated:(BOOL)animated;

- (BOOL) hasStyleClassISS:(NSString*)styleClass;

- (void) addStyleClassISS:(NSString*)styleClass;
- (void) addStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;

- (void) removeStyleClassISS:(NSString*)styleClass;
- (void) removeStyleClassISS:(NSString*)styleClass animated:(BOOL)animated;

- (void) scheduleApplyStylingISS;
- (void) scheduleApplyStylingISS:(BOOL)animated;

- (void) applyStylingISS;
- (void) applyStylingISS:(BOOL)invalidateStyles;
- (void) applyStylingWithAnimationISS;

*/


@end
