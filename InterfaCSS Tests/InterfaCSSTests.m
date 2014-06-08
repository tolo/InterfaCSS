//
//  InterfaCSSTests.m
//  InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-03-31.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "InterfaCSS.h"
#import "UIView+InterfaCSS.h"
#import "UIColor+ISSColorAdditions.h"

@interface InterfaCSSTests : XCTestCase

@end

@implementation InterfaCSSTests

- (void)setUp {
    [super setUp];
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:@"interfaCSSTests" ofType:@"css"];
    [[InterfaCSS interfaCSS] loadStyleSheetFromFile:path];
}

- (void)tearDown {
    [super tearDown];
    [InterfaCSS clearResetAndUnload];
}

- (void) testCaching {
    UIView* rootView = [[UIView alloc] init];
    [rootView addStyleClassISS:@"class1"];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    
    label.enabled = YES;
    [label applyStylingISS];
    
    XCTAssertEqual(label.alpha, 0.25f, @"Unexpected property value");
    
    label.enabled = NO;
    [label applyStylingISS];
    
    XCTAssertEqual(label.alpha, 0.75f, @"Expected change in property value after state change");
}

- (void) testCachingWhenParentObjectStateAffectsSelectorMatching {
    UIView* rootView = [[UIView alloc] init];
    [rootView addStyleClassISS:@"class1"];
    
    UIControl* control = [[UIControl alloc] init];
    [rootView addSubview:control];
    
    UILabel* label = [[UILabel alloc] init];
    [control addSubview:label];
    
    control.enabled = YES;
    [label applyStylingISS];
    
    XCTAssertEqual(label.alpha, 0.33f, @"Unexpected property value");
    
    control.enabled = NO;
    [label applyStylingISS];
    
    XCTAssertEqual(label.alpha, 0.66f, @"Expected change in property value after state change");
}

- (void) testVariableReuse {
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:@"interfaCSSTests-variables" ofType:@"css"];
    [[InterfaCSS interfaCSS] loadStyleSheetFromFile:path];
    
    UIView* rootView = [[UIView alloc] init];
    [rootView addStyleClassISS:@"reuseTest"];
    [rootView applyStylingISS];
    
    XCTAssertEqual(rootView.alpha, 0.33f, @"Unexpected property value");
}

- (void) testSetPropertyThatDoesntExistInTarget {
    UILabel* label = [[UILabel alloc] init];
    [label addStyleClassISS:@"class2"];
    [label applyStylingISS];
    
    XCTAssertEqual(label.alpha, 0.99f, @"Unexpected property value");
}

- (void) applyStyle:(NSString*)style onView:(UIView*)view andExpectAlpha:(CGFloat)alpha {
    [view addStyleClassISS:style];
    [view applyStylingISS];
    [[InterfaCSS interfaCSS] logMatchingStyleDeclarationsForUIElement:view];
    XCTAssertEqual(view.alpha, alpha, @"Unexpected property value");
}

- (void) testMultipleMatchingClassesWithSameProperty {
    UIView* rootView = [[UIView alloc] init];
    [rootView addStyleClassISS:@"classTop"];

    UIView* intermediateView = [[UIView alloc] init];
    [rootView addSubview:intermediateView];
    [intermediateView addStyleClassISS:@"classMiddle"];

    UILabel* label = [[UILabel alloc] init];
    [intermediateView addSubview:label];

    [self applyStyle:@"class10" onView:label andExpectAlpha:0.1f];
    
    [self applyStyle:@"class11" onView:label andExpectAlpha:0.2f];
    
    [self applyStyle:@"class12" onView:label andExpectAlpha:0.2f]; // class12 defines alpha as 0.3, but appears before class11, so value of class11 should still apply
    
    [label removeStyleClassISS:@"class11"]; // After class11 is removed, value of class12 should apply
    [label applyStylingISS];
    XCTAssertEqual(label.alpha, 0.3f, @"Unexpected property value");

    // Test ordering - attempt to make sure that class name doesn't affect ordering
    [self applyStyle:@"abc123" onView:label andExpectAlpha:0.31f];
    [self applyStyle:@"123abc" onView:label andExpectAlpha:0.32f];
    [self applyStyle:@"zyxvyt" onView:label andExpectAlpha:0.33f];
    [self applyStyle:@"abc123abc" onView:label andExpectAlpha:0.34f];
    [self applyStyle:@"123abc123" onView:label andExpectAlpha:0.35f];
    
    
    [self applyStyle:@"class13" onView:label andExpectAlpha:0.4f];
}

- (void) testThatPrefixedPropertyDoesntOverwrite {
    UIButton* btn = [[UIButton alloc] init];
    [self applyStyle:@"overwriteTest" onView:btn andExpectAlpha:0.5f];
}

- (void) testAttributedTextIntegrity {
    [InterfaCSS interfaCSS].preventOverwriteOfAttributedTextAttributes = YES;

    UILabel* label = [[UILabel alloc] init];
    UIButton* button = [[UIButton alloc] init];
    UIFont* font = [UIFont fontWithName:@"Helvetica-Light" size:42];
    UIColor* color = [UIColor iss_colorWithHexString:@"112233"];
    [button setTitleColor:color forState:UIControlStateNormal];
    label.attributedText = [[NSAttributedString alloc] initWithString:@"test" attributes:@{NSFontAttributeName: font,
            NSForegroundColorAttributeName: color}];
    [button setAttributedTitle:label.attributedText forState:UIControlStateNormal];

    label.styleClassISS = @"attributedTextTest";
    [label applyStylingISS];
    button.styleClassISS = @"attributedTextTest";
    [button applyStylingISS];

    XCTAssertEqual(label.alpha, 0.5f, @"Unexpected property value");
    XCTAssertEqualObjects(label.font, font, @"Unexpected property value");
    XCTAssertEqualObjects(label.textColor, color, @"Unexpected property value");
    XCTAssertEqual(button.alpha, 0.5f, @"Unexpected property value");
    XCTAssertEqualObjects(button.titleLabel.font, font, @"Unexpected property value");
    XCTAssertEqualObjects(button.currentTitleColor, color, @"Unexpected property value");
}

@end
