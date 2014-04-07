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

- (void) testMultipleMatchingClassesWithSameProperty {
    UILabel* label = [[UILabel alloc] init];
    [label addStyleClassISS:@"class10"];
    [label applyStylingISS];
    XCTAssertEqual(label.alpha, 0.1f, @"Unexpected property value");
    
    [label addStyleClassISS:@"class11"];
    [label applyStylingISS];
    XCTAssertEqual(label.alpha, 0.2f, @"Unexpected property value");
    
    [label addStyleClassISS:@"class12"]; // class12 defines alpha as 0.3, but appears before class11, so value of class11 should still apply
    [label applyStylingISS];
    XCTAssertEqual(label.alpha, 0.2f, @"Unexpected property value");
    
    [label removeStyleClassISS:@"class11"]; // After class11 is removed, value of class12 should apply
    [label applyStylingISS];
    XCTAssertEqual(label.alpha, 0.3f, @"Unexpected property value");
}

@end
