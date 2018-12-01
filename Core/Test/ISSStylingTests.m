//
//  ISSStylingTests.m
//  InterfaCSS-Core Tests
//
//  Created by PMB on 2018-11-22.
//  Copyright © 2018 Leafnode AB. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "ISSStyler.h"
#import "ISSStylingManager.h"
#import "ISSStyleSheetManager.h"
#import "ISSElementStylingProxy.h"

#import "ISSTestMacros.h"


@interface ISSStylingTests : XCTestCase

@end

@implementation ISSStylingTests

- (id<ISSStyler>) initializeWithStyleSheet:(NSString*)name {
    id<ISSStyler> styler = [[ISSStylingManager alloc] init];
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:name ofType:@"css"];
    [styler.styleSheetManager loadStyleSheetFromFileURL:[NSURL fileURLWithPath:path]];
    return styler;
}

// Test Caching properties

- (void) testCaching {
    id<ISSStyler> styler = [self initializeWithStyleSheet:@"stylingTest-caching"];
    UIView* rootView = [[UIView alloc] init];
    [rootView.interfaCSS addStyleClass:@"class1"];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    
    label.enabled = YES;
    [styler applyStyling:label];
    
    ISSAssertEqualFloats(label.alpha, 0.25, @"Unexpected property value");
    
    label.enabled = NO;
    [styler applyStyling:label]; // Styling should not be cached
    
    ISSAssertEqualFloats(label.alpha, 0.75, @"Expected change in property value after state change");
}

- (void) testCachingWhenParentObjectStateAffectsSelectorMatching {
    id<ISSStyler> styler = [self initializeWithStyleSheet:@"stylingTest-caching"];
    UIView* rootView = [[UIView alloc] init];
    [rootView.interfaCSS addStyleClass:@"class1"];
    
    UIControl* control = [[UIControl alloc] init];
    [rootView addSubview:control];
    
    UILabel* label = [[UILabel alloc] init];
    [control addSubview:label];
    
    control.enabled = YES;
    [styler applyStyling:label];
    
    ISSAssertEqualFloats(label.alpha, 0.33, @"Unexpected property value");
    
    control.enabled = NO;
    [styler applyStyling:label]; // Styling should not be cached
    
    ISSAssertEqualFloats(label.alpha, 0.66, @"Expected change in property value after state change");
}

// Test common UIView properties

- (void) testUIViewProperties {
    id<ISSStyler> styler = [self initializeWithStyleSheet:@"stylingTest-properties"];
    
    UIView* rootView = [[UIView alloc] init];
    [rootView.interfaCSS addStyleClass:@"uiViewTest"];
    
    UILabel* label = [[UILabel alloc] init];
    [label.interfaCSS addStyleClass:@"uiViewTest"];
    [rootView addSubview:label];
    [styler applyStyling:rootView];
    
    XCTAssertEqual(rootView.autoresizingMask, (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight), @"Unexpected property value");
    XCTAssertEqual(rootView.backgroundColor, [UIColor redColor], @"Unexpected property value");
    XCTAssertEqual(rootView.clipsToBounds, true, @"Unexpected property value");
    XCTAssertEqual(rootView.hidden, true, @"Unexpected property value");
    XCTAssertTrue(CGRectEqualToRect(rootView.frame, CGRectMake(1, 2, 3, 4)), @"Unexpected property value");
    XCTAssertEqual(rootView.tag, 5, @"Unexpected property value");
    XCTAssertEqual(rootView.tintColor, [UIColor blueColor], @"Unexpected property value");
    
    // Test "inheritance" of properties fro UIView
    XCTAssertEqual(label.autoresizingMask, (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight), @"Unexpected property value");
    XCTAssertEqual(label.backgroundColor, [UIColor redColor], @"Unexpected property value");
    XCTAssertEqual(label.clipsToBounds, true, @"Unexpected property value");
    XCTAssertEqual(label.hidden, true, @"Unexpected property value");
    XCTAssertTrue(CGRectEqualToRect(label.frame, CGRectMake(1, 2, 3, 4)), @"Unexpected property value");
    XCTAssertEqual(label.tag, 5, @"Unexpected property value");
    XCTAssertEqual(label.tintColor, [UIColor blueColor], @"Unexpected property value");
}

- (void) testUILabelProperties {
    // TODO:
}

- (void) testUIButtonProperties {
    // TODO:
}

@end
