//
//  InterfaCSSTests.m
//  InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-03-31.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "InterfaCSS.h"
#import "ISSUIElementDetails.h"
#import "UIView+InterfaCSS.h"
#import "UIColor+ISSColorAdditions.h"
#import "ISSViewHierarchyParser.h"


@interface CustomView2 : UIView
@property (nonatomic, strong) UILabel* label3;
@property (nonatomic, strong) UILabel* label4;
@property (nonatomic, strong) UIView* customView3;
@end
@implementation CustomView2
@end

@interface CustomView1 : UIView
@property (nonatomic, strong) UILabel* label2;
@property (nonatomic, strong) UILabel* label5;
@property (nonatomic, strong) CustomView2* customView2;
@end
@implementation CustomView1
@end


@interface TestFileOwner : NSObject
@property (nonatomic, strong) UILabel* label1;
@property (nonatomic, strong) UIButton* button1;
@end
@implementation TestFileOwner
@end

@interface TestFileOwnerDelegate : TestFileOwner<ISSViewHierarchyParserDelegate>
@property NSDictionary* customView1Properties;
@end
@implementation TestFileOwnerDelegate

- (void) viewHierarchyParser:(ISSViewHierarchyParser*)viewHierarchyParser didBuildView:(UIView*)view parent:(UIView*)parentView
                 elementName:(NSString*)elementName attributes:(NSDictionary*)attributes {
    if( [view isKindOfClass:CustomView1.class] ) {
        self.customView1Properties = attributes;
    }
}

@end



@interface InterfaCSSTests : XCTestCase

@end

@implementation InterfaCSSTests

- (void) setUp {
    [super setUp];
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:@"interfaCSSTests" ofType:@"css"];
    [[InterfaCSS interfaCSS] loadStyleSheetFromFile:path];
}

- (void) tearDown {
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
    [label applyStylingISS]; // Styling should not be cached
    
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
    [label applyStylingISS]; // Styling should not be cached
    
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
    UILabel* label2 = [[UILabel alloc] init];
    UIButton* button = [[UIButton alloc] init];
    
    UIFont* cssFont = [UIFont fontWithName:@"HelveticaNeue-Bold" size:10];
    UIFont* font = [UIFont fontWithName:@"Helvetica-Light" size:42];
    UIColor* color = [UIColor iss_colorWithHexString:@"112233"];
    
    // String without attributes should be unaffected by preventOverwriteOfAttributedTextAttributes flag
    label2.attributedText = [[NSAttributedString alloc] initWithString:@"test2" attributes:@{}];
    
    label.attributedText = [[NSAttributedString alloc] initWithString:@"test" attributes:@{NSFontAttributeName: font,
            NSForegroundColorAttributeName: color}];

    [button setTitleColor:color forState:UIControlStateNormal];
    [button setAttributedTitle:label.attributedText forState:UIControlStateNormal];

    label.styleClassISS = @"attributedTextTest";
    [label applyStylingISS];
    label2.styleClassISS = @"attributedTextTest";
    [label2 applyStylingISS];
    button.styleClassISS = @"attributedTextTest";
    [button applyStylingISS];

    XCTAssertEqual(label.alpha, 0.5f, @"Unexpected property value"); // Just to test that styling actually has occurred
    XCTAssertEqualObjects(label.font, font, @"Unexpected property value");
    XCTAssertEqualObjects(label.textColor, color, @"Unexpected property value");
    XCTAssertEqualObjects(label2.font, cssFont, @"Unexpected property value");
    XCTAssertEqual(button.alpha, 0.5f, @"Unexpected property value"); // Just to test that styling actually has occurred
    XCTAssertEqualObjects(button.titleLabel.font, font, @"Unexpected property value");
    XCTAssertEqualObjects(button.currentTitleColor, color, @"Unexpected property value");
}

- (void) testUILabelAttributedTextSupport {
    UILabel* label = [[UILabel alloc] init];
    label.styleClassISS = @"labelAttributedTextTest";
    [label applyStylingISS];

    NSDictionary* attrs1 = [label.attributedText attributesAtIndex:0 effectiveRange:nil];
    NSDictionary* attrs2 = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:12], NSForegroundColorAttributeName: [UIColor blueColor]};

    XCTAssertEqualObjects(label.attributedText.string, @"text");
    XCTAssertEqualObjects(attrs1, attrs2);
}

- (void) testUIButtonAttributedTitleSupport {
    UIButton* button = [[UIButton alloc] init];
    button.styleClassISS = @"buttonAttributedTitleTest";
    [button applyStylingISS];

    NSAttributedString* attributedString = [button attributedTitleForState:UIControlStateNormal];
    NSDictionary* attrs1 = [attributedString attributesAtIndex:0 effectiveRange:nil];
    NSDictionary* attrs2 = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:12], NSForegroundColorAttributeName: [UIColor blueColor]};
    
    XCTAssertEqualObjects(attributedString.string, @"text");
    XCTAssertEqualObjects(attrs1, attrs2);

    attributedString = [button attributedTitleForState:UIControlStateHighlighted];
    attrs1 = [attributedString attributesAtIndex:0 effectiveRange:nil];
    attrs2 = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:12], NSForegroundColorAttributeName: [UIColor redColor]};

    XCTAssertEqualObjects(attributedString.string, @"text");
    XCTAssertEqualObjects(attrs1, attrs2);
}

- (void) testDisableStyling {
    UIView* root = [[UIView alloc] init];
    root.styleClassISS = @"disabledStylingTest";
    UILabel* label = [[UILabel alloc] init];
    [root addSubview:label];

    // Call applyStylingISS and verify that values have been read from CSS
    [root applyStylingISS];
    XCTAssertEqual(root.alpha, 0.5f, @"Unexpected property value");
    XCTAssertEqual(label.alpha, 0.5f, @"Unexpected property value");

    // Disable styling and change alpha values
    [root disableStylingISS];
    root.alpha = 0.666f;
    label.alpha = 0.666f;

    // Call applyStylingISS and verify that values didn't change
    [root applyStylingISS];
    XCTAssertEqual(root.alpha, 0.666f, @"Unexpected property value");
    XCTAssertEqual(label.alpha, 0.666f, @"Unexpected property value");

    // Re-enable styling and verify that values revert back to those in CSS
    [root enableStylingISS];
    [root applyStylingISS];
    XCTAssertEqual(root.alpha, 0.5f, @"Unexpected property value");
    XCTAssertEqual(label.alpha, 0.5f, @"Unexpected property value");
}

- (void) testCascadingStylePropertyOverrideWithDefault {
    UILabel* label = [[UILabel alloc] init];
    label.styleClassISS = @"cascadingStylePropertyOverrideWithDefault1";
    label.alpha = 1;

    [label applyStylingISS];

    XCTAssertEqual(label.alpha, 0.666f, @"Unexpected property value");

    label.alpha = 0.5;
    [label addStyleClassISS:@"cascadingStylePropertyOverrideWithDefault2"];

    [label applyStylingISS];

    XCTAssertEqual(label.alpha, 0.5f, @"Unexpected property value");
}

- (void) testDisableStylingOfProperty {
    UILabel* label = [[UILabel alloc] init];
    label.styleClassISS = @"testDisableProperty";
    label.alpha = 1;

    [label applyStylingISS];

    XCTAssertEqual(label.alpha, 0.5f, @"Unexpected property value");

    label.alpha = 1;
    [label disableStylingForPropertyISS:@"alpha"];

    [label applyStylingISS];

    XCTAssertEqual(label.alpha, 1.0f, @"Unexpected property value");
}

- (void) testElementStyleCaching {
    UIView* view = [[UIView alloc] init];
    UILabel* label = [[UILabel alloc] init];
    [view addSubview:label];
    
    ISSUIElementDetails* details = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    XCTAssertFalse(details.stylesCacheable, @"Expected styles to be NOT cacheable");
    XCTAssertFalse(details.elementStyleIdentityResolved, @"Expected style identity to be NOT resolved");
    
    UIWindow* window = [[UIWindow alloc] init];
    [window addSubview:view];
    
    details = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    XCTAssertTrue(details.stylesCacheable, @"Expected styles to be cacheable");
}

- (void) testElementStyleCachingUsingCustomStylingIdentity {
    UIView* view = [[UIView alloc] init];
    view.customStylingIdentityISS = @"custom";
    
    ISSUIElementDetails* details = [[InterfaCSS interfaCSS] detailsForUIElement:view];
    XCTAssertTrue(details.stylesCacheable, @"Expected styles to be cacheable");
    XCTAssertTrue(details.elementStyleIdentityResolved, @"Expected style identity to be resolved");
}

- (void) testElementStyleCachingUsingCustomStylingIdentityOnSuperView {
    UIView* view = [[UIView alloc] init];
    view.customStylingIdentityISS = @"custom";
    UILabel* label = [[UILabel alloc] init];
    [view addSubview:label];
    
    ISSUIElementDetails* details = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    [details elementStyleIdentity]; // Make sure styling identity is built
    XCTAssertTrue(details.stylesCacheable, @"Expected styles to be cacheable");
    XCTAssertTrue(details.elementStyleIdentityResolved, @"Expected style identity to be resolved");
}

- (void) testElementStyleCachingUsingCustomStylingIdentityOnSuperViewSetLater {
    UIView* view = [[UIView alloc] init];
    UILabel* label = [[UILabel alloc] init];
    [view addSubview:label];
    
    UIWindow* window = [[UIWindow alloc] init];
    [window addSubview:view];
    
    ISSUIElementDetails* details = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    [details elementStyleIdentity]; // Make sure styling identity is built
    XCTAssertTrue(details.stylesCacheable, @"Expected styles to be cacheable");
    XCTAssertTrue(details.elementStyleIdentityResolved, @"Expected style identity to be resolved");
    
    view.customStylingIdentityISS = @"custom";
    
    details = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([details.elementStyleIdentity hasPrefix:@"custom"], @"Expected styles identity to begin with custom style identity of parent");

    XCTAssertTrue(details.stylesCacheable, @"Expected styles to be cacheable");
    XCTAssertTrue(details.elementStyleIdentityResolved, @"Expected style identity to be resolved");
}

- (void) testLoadViewDefinitionFile {
    TestFileOwner* fileOwner = [[TestFileOwner alloc] init];
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:@"viewDefinitionTest" ofType:@"xml"];
    UIView* v = [ISSViewBuilder loadViewHierarchyFromFile:path fileOwner:fileOwner];
    
    XCTAssertNotNil(v);
    XCTAssertNotNil(fileOwner.label1);
    XCTAssertNotNil(fileOwner.button1);
}

- (void) testLoadViewDefinitionFileWithPrototypes {
    TestFileOwner* fileOwner = [[TestFileOwner alloc] init];
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:@"viewDefinitionTest" ofType:@"xml"];
    [ISSViewBuilder loadViewHierarchyFromFile:path fileOwner:fileOwner];
    
    id p = [[InterfaCSS interfaCSS] viewFromPrototypeWithName:@"prototype1"];
    
    XCTAssertNotNil(p);
    XCTAssertTrue([p isKindOfClass:CustomView1.class]);
    
    CustomView1* customView1 = p;
    // Test elements defined on topmost view
    XCTAssertNotNil(customView1.label2);
    XCTAssertNotNil(customView1.customView2);

    // Test elements defined on nested view and set in same view
    XCTAssertNotNil(customView1.customView2.label3);
    XCTAssertNotNil(customView1.customView2.customView3);

    // Test elements defined on nested view but set in topmost view
    XCTAssertNotNil(customView1.customView2.label4);
    XCTAssertNotNil(customView1.label5);
}

- (void) testLoadViewDefinitionFileWithDelegate {
    TestFileOwnerDelegate* fileOwner = [[TestFileOwnerDelegate alloc] init];
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:@"viewDefinitionTest" ofType:@"xml"];
    [ISSViewBuilder loadViewHierarchyFromFile:path fileOwner:fileOwner];
    
    // Load prototype to trigger execution of prototype view block, and call to delegate
    [[InterfaCSS interfaCSS] viewFromPrototypeWithName:@"prototype1"];
    
    XCTAssertEqualObjects(fileOwner.customView1Properties[ISSViewDefinitionFileAttributeId], @"CustomView1Id");
    XCTAssertEqualObjects(fileOwner.customView1Properties[ISSViewDefinitionFileAttributeClass], @"prototype1");
    XCTAssertEqualObjects(fileOwner.customView1Properties[ISSViewDefinitionFileAttributeProperty], @"CustomView1Property");
    XCTAssertEqualObjects(fileOwner.customView1Properties[ISSViewDefinitionFileAttributePrototype], @"prototype1");
    XCTAssertEqualObjects(fileOwner.customView1Properties[ISSViewDefinitionFileAttributePrototypeScope], @"global");
    XCTAssertEqualObjects(fileOwner.customView1Properties[ISSViewDefinitionFileAttributeImplementationClass], @"CustomView1");
    
    XCTAssertEqualObjects(fileOwner.customView1Properties[@"customAttr1"], @"customValue1");
}

- (void) testShadowProperties {
    UIView* v = [[UIView alloc] init];
    v.styleClassISS = @"shadowTest1";
    [v applyStylingISS];

    XCTAssertEqualObjects((id)v.layer.shadowColor, (id)[UIColor redColor].CGColor);
    XCTAssertTrue(CGSizeEqualToSize(v.layer.shadowOffset, CGSizeMake(1,2)));
    XCTAssertEqual(v.layer.shadowOpacity, 0.5);
    XCTAssertEqual(v.layer.shadowRadius, 10);
    
    UILabel* l = [[UILabel alloc] init];
    l.styleClassISS = @"shadowTest2";
    [l applyStylingISS];
    
    XCTAssertEqualObjects(l.shadowColor, [UIColor redColor]);
    XCTAssertTrue(CGSizeEqualToSize(l.shadowOffset, CGSizeMake(1,2)));
}

- (UILabel*) labelWithString:(NSString*)string parent:(UIView*)parent {
    UILabel* label = [[UILabel alloc] init];
    label.text = string;
    [parent addSubview:label];
    return label;
}

- (void) testSizeToFit {
    UIView* parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 500, 500)];
    NSString* string = @"þetta er ágætis byrjun.";
    UILabel* reference = [self labelWithString:string parent:parent];
    CGSize referenceSize = [reference sizeThatFits:parent.bounds.size];
    
    UILabel* l1 = [self labelWithString:string parent:parent];
    l1.styleClassISS = @"sizeToFitTest1";
    [l1 applyStylingISS];
    
    XCTAssertTrue(CGSizeEqualToSize(l1.frame.size, referenceSize));
    XCTAssertEqual(l1.frame.origin.x, 20);
    XCTAssertEqual(l1.frame.origin.y, 10);
    
    
    UILabel* l2 = [self labelWithString:string parent:parent];
    l2.styleClassISS = @"sizeToFitTest2";
    [l2 applyStylingISS];
    
    XCTAssertTrue(CGSizeEqualToSize(l2.frame.size, referenceSize));
    XCTAssertEqual(l2.frame.origin.x, parent.bounds.size.width - referenceSize.width - 20);
    XCTAssertEqual(l2.frame.origin.y, parent.bounds.size.height - referenceSize.height - 10);
    
    UILabel* l3 = [self labelWithString:string parent:parent];
    l3.styleClassISS = @"sizeToFitTest3";
    [l3 applyStylingISS];
    
    XCTAssertTrue(CGSizeEqualToSize(l3.frame.size, CGSizeMake(5, 5)));
}

- (void) testCollectionViewFlowLayoutProperties {
    UICollectionViewFlowLayout* flow = [[UICollectionViewFlowLayout alloc] init];
    UICollectionView* collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flow];
    
    collectionView.styleClassISS = @"collectionViewTest";
    [collectionView applyStylingISS];
    
    XCTAssertEqual(flow.minimumLineSpacing, 42);
}

@end
