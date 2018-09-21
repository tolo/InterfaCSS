//
//  ISSSelectorTests.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>

#import "ISSStylingManager.h"
#import "ISSStyleSheetManager.h"
#import "ISSStyleSheetParser.h"
#import "ISSPropertyManager.h"

#import "ISSElementStylingProxy.h"
#import "ISSRuleset.h"
#import "ISSPropertyValue.h"
#import "ISSProperty.h"
#import "ISSSelectorChain.h"
#import "ISSSelector.h"
#import "ISSPseudoClass.h"
#import "ISSElementStylingProxy.h"
#import "ISSStylingContext.h"
#import "ISSNestedElementSelector.h"


@interface MyCustomView : UIView
@end

@implementation MyCustomView
@end

@interface MyCustomViewSubClass : MyCustomView
@end

@implementation MyCustomViewSubClass
@end

@interface MyCustomView2 : UIView
@end

@implementation MyCustomView2
@end

@interface SomeViewController : UIViewController
@end

@implementation SomeViewController
@end


@interface ISSSelectorTests : XCTestCase
@end

@implementation ISSSelectorTests {
    ISSStylingManager* styler;
    ISSStyleSheetParser* parser;
    UIWindow* window;
    UIView* rootView;
}

- (void) setUp {
    [super setUp];

    styler = [[ISSStylingManager alloc] init];
    parser = styler.styleSheetManager.styleSheetParser;
    
    window = [[UIWindow alloc] init];
    
    rootView = [[UIView alloc] init];
    [window addSubview:rootView];
    
    [styler[rootView] addStyleClass:@"parentClass"];
}

- (void) tearDown {
    [super tearDown];
}


#pragma mark - Utils

- (ISSSelector*) selectorWithType:(nullable NSString*)type styleClass:(nullable NSString*)styleClass pseudoClasses:(nullable NSArray*)pseudoClasses {
    return [self selectorWithType:type elementId:nil styleClass:styleClass pseudoClasses:pseudoClasses];
}

- (ISSSelector*) selectorWithType:(nullable NSString*)type elementId:(nullable NSString*)elementId styleClass:(nullable NSString*)styleClass pseudoClasses:(nullable NSArray*)pseudoClasses {
    return [styler.styleSheetManager createSelectorWithType:type elementId:nil styleClasses:styleClass ? @[styleClass] : nil pseudoClasses:pseudoClasses];
}

- (ISSSelectorChain*) createSelectorChainWithChildType:(NSString*)type combinator:(ISSSelectorCombinator)combinator childPseudoClass:(ISSPseudoClass*)childPseudoClass {
    ISSSelector* parentSelector = [[ISSSelector alloc] initWithType:nil elementId:nil styleClasses:@[@"parentClass"] pseudoClasses:nil];
    ISSSelector* childSelector;
    Class typeClass = NSClassFromString(type);
    if( childPseudoClass ) childSelector =  [[ISSSelector alloc] initWithType:typeClass elementId:nil styleClasses:@[@"childClass"] pseudoClasses:@[childPseudoClass]];
    else childSelector = [[ISSSelector alloc] initWithType:typeClass elementId:nil styleClasses:@[@"childClass"] pseudoClasses:nil];
    return [ISSSelectorChain selectorChainWithComponents:@[parentSelector, @(combinator), childSelector]];
}

- (ISSPseudoClass*) pseudoClassWithTypeString:(NSString*)string {
    return [styler.styleSheetManager createPseudoClassWithParameter:nil type:[styler.styleSheetManager pseudoClassTypeFromString:string]];
}

- (ISSPseudoClass*) pseudoClassWithTypeString:(NSString*)string andParameter:(NSString*)param {
    return [styler.styleSheetManager createPseudoClassWithParameter:param type:[styler.styleSheetManager pseudoClassTypeFromString:string]];
}

- (ISSStylingContext*) createStylingContext {
    return [[ISSStylingContext alloc] initWithStylingManager:styler styleSheetScope:nil];
}

#pragma mark - Tests

- (void) testMultiClassSelector {
    ISSSelector* singleClassSelector = [[ISSSelector alloc] initWithType:nil elementId:nil styleClasses:@[@"class1"] pseudoClasses:nil];
    ISSSelector* multiClassSelector = [[ISSSelector alloc] initWithType:nil elementId:nil styleClasses:@[@"class1", @"class2"] pseudoClasses:nil];
    
    UIView* view = [[UIView alloc] init];
    ISSElementStylingProxy* element = styler[view];
    [element addStyleClass:@"class1"];
    
    XCTAssertTrue([singleClassSelector matchesElement:element stylingContext:[self createStylingContext]], @"Single class selector must match element with style class!");
    XCTAssertFalse([multiClassSelector matchesElement:element stylingContext:[self createStylingContext]], @"Multi class selector must NOT match element with single class!");
    
    [element addStyleClass:@"anotherClass"];
    
    XCTAssertTrue([singleClassSelector matchesElement:element stylingContext:[self createStylingContext]], @"Single class selector must match element with style class!");
    XCTAssertFalse([multiClassSelector matchesElement:element stylingContext:[self createStylingContext]], @"Multi class selector must NOT match element with only partial match!");
    
    [element addStyleClass:@"class2"];
    
    XCTAssertTrue([singleClassSelector matchesElement:element stylingContext:[self createStylingContext]], @"Single class selector must match element with style class!");
    XCTAssertTrue([multiClassSelector matchesElement:element stylingContext:[self createStylingContext]], @"Multi class selector must match element with multiple classes!");
}


- (void) testDescendantButNotChild {
    UIView* inbetweenView = [[UIView alloc] init];
    [rootView addSubview:inbetweenView];
    
    UILabel* label = [[UILabel alloc] init];
    [inbetweenView addSubview:label];
    ISSElementStylingProxy* labelDetails = styler[label];
    [labelDetails addStyleClass:@"childClass"];
 
    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"UILabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:nil];
    XCTAssertTrue([descendantChain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Descendant selector chain must match!");
    
    ISSSelectorChain* childChain = [self createSelectorChainWithChildType:@"UILabel" combinator:ISSSelectorCombinatorChild childPseudoClass:nil];
    XCTAssertFalse([childChain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Child selector chain must NOT match!");
    
    XCTAssertFalse(childChain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testInvalidDescendant {
    UIView* otherRootView = [[UIView alloc] init];
    [window addSubview:otherRootView];
    [styler[otherRootView] addStyleClass:@"otherParentClass"];
    
    UILabel* label = [[UILabel alloc] init];
    [otherRootView addSubview:label];
    ISSElementStylingProxy* labelDetails = styler[label];
    [labelDetails addStyleClass:@"childClass"];
    
    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"UILabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:nil];
    XCTAssertFalse([descendantChain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Descendant selector chain must NOT match label with other parent!");
}

- (void) testChildAndDescendant {
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSElementStylingProxy* labelDetails = styler[label];
    [labelDetails addStyleClass:@"childClass"];
    
    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"UILabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:nil];
    XCTAssertTrue([descendantChain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Descendant selector chain must match!");
    
    ISSSelectorChain* childChain = [self createSelectorChainWithChildType:@"UILabel" combinator:ISSSelectorCombinatorChild childPseudoClass:nil];
    XCTAssertTrue([childChain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Child selector chain must match!");
    
    XCTAssertFalse(childChain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testDeepChildAndDescendant {
    UIView* view1 = [[UIView alloc] init];
    [rootView addSubview:view1];
    [styler[view1] addStyleClass:@"view1"];
    
    UIScrollView* view2 = [[UIScrollView alloc] init];
    [view1 addSubview:view2];
    [styler[view2] addStyleClass:@"view2"];
    
    UIButton* button = [[UIButton alloc] init];
    [view2 addSubview:button];
    
    [styler[button] addValidNestedElementKeyPath:@"titleLabel"];
    
    ISSSelector* viewSelector = [self selectorWithType:@"UIView" styleClass:nil pseudoClasses:nil];
    ISSSelector* view1Selector = [self selectorWithType:@"UIView" styleClass:@"view1" pseudoClasses:nil];
    ISSSelector* view2Selector = [self selectorWithType:@"UIScrollView" styleClass:@"view2" pseudoClasses:nil];
    ISSSelector* buttonSelector = [self selectorWithType:@"UIButton" styleClass:nil pseudoClasses:nil];
    ISSSelector* titleLabelSelector = [ISSNestedElementSelector selectorWithNestedElementKeyPath:@"titleLabel"];
    
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[viewSelector, @(ISSSelectorCombinatorChild), view1Selector, @(ISSSelectorCombinatorDescendant), view2Selector,
                                                                              @(ISSSelectorCombinatorChild), buttonSelector, @(ISSSelectorCombinatorDescendant), titleLabelSelector]];
    
    ISSElementStylingProxy* labelDetails = styler[button.titleLabel];
    
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Deep descendant/child selector chain must match!");
}

- (void) doTestSibling:(BOOL)adjacent {
    UIButton* button = [[UIButton alloc] init];
    [styler[button] addStyleClass:@"buttonClass"];
    [rootView addSubview:button];
    
    if( !adjacent ) {
        UILabel* anotherLabel = [[UILabel alloc] init];
        [rootView addSubview:anotherLabel];
        [styler[anotherLabel] addStyleClass:@"anotherLabelClass"];
    }
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSElementStylingProxy* labelDetails = styler[label];
    [labelDetails addStyleClass:@"labelClass"];
    
    ISSSelector* buttonSelector = [self selectorWithType:@"UIButton" styleClass:@"buttonClass" pseudoClasses:nil];
    ISSSelector* labelSelector = [self selectorWithType:@"UILabel" styleClass:@"labelClass" pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[buttonSelector, @(ISSSelectorCombinatorAdjacentSibling), labelSelector]];
    
    if( adjacent ) XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Adjacent sibling selector chain must match!");
    else XCTAssertFalse([chain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Adjacent sibling selector chain must NOT match!");
    
    chain = [ISSSelectorChain selectorChainWithComponents:@[buttonSelector, @(ISSSelectorCombinatorGeneralSibling), labelSelector]];
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"General sibling selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testAdjacentSibling {
    [self doTestSibling:YES];
}

- (void) testGeneralSibling {
    [self doTestSibling:NO];
}

- (void) assertDescendantPseudo:(UILabel*)label pseudoClassType:(ISSPseudoClassType)pseudoClassType a:(NSInteger)a b:(NSInteger)b message:(NSString*)message {
    ISSElementStylingProxy* labelDetails = styler[label];
    ISSPseudoClass* pseudo = [[ISSPseudoClass alloc] initStructuralPseudoClassWithA:a b:b type:pseudoClassType];

    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"UILabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:pseudo];
    XCTAssertTrue([descendantChain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"%@", message);
    XCTAssertTrue(descendantChain.hasPseudoClassSelector, @"Expected selector chain to report having pseudo class");
}

- (void) doTestNthChild:(BOOL)ofType {
    ISSPseudoClassType pseudoClassType = ofType ? ISSPseudoClassTypeNthOfType : ISSPseudoClassTypeNthChild;

    NSMutableArray* labels = [NSMutableArray array];
    for(NSUInteger i=0; i<5; i++) {
        labels[i] = [[UILabel alloc] init];
        [rootView addSubview:labels[i]];
        [styler[labels[i]] addStyleClass:@"childClass"];

        if( ofType ) {
            [rootView addSubview:[[UIButton alloc] init]];
            if( i == 0 ) {
                // Test only of type
                [self assertDescendantPseudo:labels[0] pseudoClassType:ISSPseudoClassTypeOnlyOfType a:0 b:1 message:@"Descendant only of type pseudo selector chain must match!"];
            }
        }
        else if( i == 0 ) {
            // Test only child
            [self assertDescendantPseudo:labels[0] pseudoClassType:ISSPseudoClassTypeOnlyChild a:0 b:1 message:@"Descendant only child pseudo selector chain must match!"];
        }
    }

    // First child - same logic applies for ISSPseudoClassTypeNthChild/ISSPseudoClassTypeFirstChild and ISSPseudoClassTypeFirstOfType/ISSPseudoClassTypeNthOfType
    [self assertDescendantPseudo:labels[0] pseudoClassType:pseudoClassType a:0 b:1 message:@"Descendant first child pseudo selector chain must match!"];

    // 5th child
    [self assertDescendantPseudo:labels[4] pseudoClassType:pseudoClassType a:0 b:5 message:@"Descendant nth child (5) pseudo selector chain must match!"];

    // Odd child
    [self assertDescendantPseudo:labels[0] pseudoClassType:pseudoClassType a:2 b:1 message:@"Descendant odd child (first) pseudo selector chain must match!"];
    [self assertDescendantPseudo:labels[2] pseudoClassType:pseudoClassType a:2 b:1 message:@"Descendant odd child (third) pseudo selector chain must match!"];

    // Even child
    [self assertDescendantPseudo:labels[1] pseudoClassType:pseudoClassType a:2 b:0 message:@"Descendant even child (second) pseudo selector chain must match!"];
    [self assertDescendantPseudo:labels[3] pseudoClassType:pseudoClassType a:2 b:0 message:@"Descendant even child (fourth) pseudo selector chain must match!"];
}

- (void) testPseudoClassNthChild {
    [self doTestNthChild:NO];
}

- (void) testPseudoClassNthChildOfType {
    [self doTestNthChild:YES];
}

- (void) doTestNthLastChild:(BOOL)ofType {
    ISSPseudoClassType pseudoClassType = ofType ? ISSPseudoClassTypeNthLastOfType : ISSPseudoClassTypeNthLastChild;

    NSMutableArray* labels = [NSMutableArray array];
    for(NSUInteger i=0; i<5; i++) {
        labels[i] = [[UILabel alloc] init];
        [rootView addSubview:labels[i]];
        [styler[labels[i]] addStyleClass:@"childClass"];
        if( ofType ) [rootView addSubview:[[UIButton alloc] init]];
    }

    // Last child
    [self assertDescendantPseudo:labels[4] pseudoClassType:pseudoClassType a:0 b:1 message:@"Descendant last child pseudo selector chain must match!"];

    // 5th last child
    [self assertDescendantPseudo:labels[0] pseudoClassType:pseudoClassType a:0 b:5 message:@"Descendant nth last child (5) pseudo selector chain must match!"];
}

- (void) testPseudoClassNthLastChild {
    [self doTestNthLastChild:NO];
}

- (void) testPseudoClassNthLastChildOfType {
    [self doTestNthLastChild:YES];
}

- (void) testPseudoClassEmpty {
    ISSElementStylingProxy* viewDetails = styler[rootView];
    ISSPseudoClass* pseudo = [[ISSPseudoClass alloc] initStructuralPseudoClassWithA:0 b:1 type:ISSPseudoClassTypeEmpty];

    ISSSelector* parentSelector = [self selectorWithType:@"uiview" styleClass:@"parentClass" pseudoClasses:@[pseudo]];

    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector]];

    XCTAssertTrue([chain matchesElement:viewDetails stylingContext:[self createStylingContext]], @"Empty structural pseudo class selector must match empty root view!");

    [rootView addSubview:[[UIButton alloc] init]];
    XCTAssertTrue(![chain matchesElement:viewDetails stylingContext:[self createStylingContext]], @"Empty structural pseudo class selector must NOT match root view that contains subviews!");
    
    XCTAssertTrue(chain.hasPseudoClassSelector, @"Expected selector chain to report having pseudo class");
}

- (void) testPseudoClassControlState {
    UIButton* button = [[UIButton alloc] init];
    ISSElementStylingProxy* viewDetails = styler[button];
    
    ISSPseudoClass* enabledPseudo = [self pseudoClassWithTypeString:@"enabled"];
    ISSPseudoClass* disabledPseudo = [self pseudoClassWithTypeString:@"disabled"];
    ISSPseudoClass* selectedPseudo = [self pseudoClassWithTypeString:@"selected"];
    ISSPseudoClass* highlightedPseudo = [self pseudoClassWithTypeString:@"highlighted"];
    
    ISSSelectorChain* enabledSelector = [ISSSelectorChain selectorChainWithSelector:[self selectorWithType:@"UIButton" styleClass:nil pseudoClasses:@[enabledPseudo]]];
    ISSSelectorChain* disabledSelector = [ISSSelectorChain selectorChainWithSelector:[self selectorWithType:@"UIButton" styleClass:nil pseudoClasses:@[disabledPseudo]]];
    ISSSelectorChain* selectedSelector = [ISSSelectorChain selectorChainWithSelector:[self selectorWithType:@"UIButton" styleClass:nil pseudoClasses:@[selectedPseudo]]];
    ISSSelectorChain* highlightedSelector = [ISSSelectorChain selectorChainWithSelector:[self selectorWithType:@"UIButton" styleClass:nil pseudoClasses:@[highlightedPseudo]]];
    ISSSelectorChain* selectedHighlightedSelector = [ISSSelectorChain selectorChainWithSelector:[self selectorWithType:@"UIButton" styleClass:nil pseudoClasses:@[selectedPseudo, highlightedPseudo]]];
    
    // Test disabled
    button.enabled = NO;
    XCTAssertTrue([disabledSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
    XCTAssertFalse([enabledSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
    
    // Test enabled
    button.enabled = YES;
    XCTAssertTrue([enabledSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
    XCTAssertFalse([disabledSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
    
    // Check negative result for selected and highlighted
    XCTAssertFalse([selectedSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
    XCTAssertFalse([highlightedSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
    XCTAssertFalse([selectedHighlightedSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
    
    // Test selected
    button.selected = YES;
    XCTAssertTrue([selectedSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
    
    // Test selected
    button.highlighted = YES;
    XCTAssertTrue([highlightedSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
    
    // Test selected & highlighted (chained)
    XCTAssertTrue([selectedHighlightedSelector matchesElement:viewDetails stylingContext:[self createStylingContext]]);
}

- (void) testPseudoClassOSVersion {
    NSString* currentSystemVersion = [UIDevice currentDevice].systemVersion;
    NSString* majorVersion = [currentSystemVersion componentsSeparatedByString:@"."][0];
    NSString* previousVersion = [NSString stringWithFormat:@"%d", (int)[majorVersion integerValue] - 1];
    NSString* nextVersion = [NSString stringWithFormat:@"%d", (int)[majorVersion integerValue] + 1];
    
    UIView* randomView = [[UIView alloc] init];
    ISSElementStylingProxy* randomViewDetails = styler[randomView];
    
    ISSStylingContext* context = [self createStylingContext];
    
    ISSPseudoClass* osVersionPseudoClass = [self pseudoClassWithTypeString:@"minOSVersion" andParameter:currentSystemVersion];
    XCTAssertTrue([osVersionPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    osVersionPseudoClass = [self pseudoClassWithTypeString:@"minOSVersion" andParameter:previousVersion];
    XCTAssertTrue([osVersionPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    osVersionPseudoClass = [self pseudoClassWithTypeString:@"minOSVersion" andParameter:nextVersion];
    XCTAssertFalse([osVersionPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    
    osVersionPseudoClass = [self pseudoClassWithTypeString:@"maxOSVersion" andParameter:currentSystemVersion];
    XCTAssertTrue([osVersionPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    osVersionPseudoClass = [self pseudoClassWithTypeString:@"maxOSVersion" andParameter:previousVersion];
    XCTAssertFalse([osVersionPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    osVersionPseudoClass = [self pseudoClassWithTypeString:@"maxOSVersion" andParameter:nextVersion];
    XCTAssertTrue([osVersionPseudoClass matchesElement:randomViewDetails stylingContext:context]);
}

- (void) testPseudoClassScreenWidth {
    CGFloat width = MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    NSString* narrower = [NSString stringWithFormat:@"%f", width - 1];
    NSString* wider = [NSString stringWithFormat:@"%f", width + 1];
    
    UIView* randomView = [[UIView alloc] init];
    ISSElementStylingProxy* randomViewDetails = styler[randomView];
    
    ISSStylingContext* context = [self createStylingContext];
    
    ISSPseudoClass* widthPseudoClass = [self pseudoClassWithTypeString:@"screenWidth" andParameter:[NSString stringWithFormat:@"%f", width]];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenWidth" andParameter:narrower];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenWidth" andParameter:wider];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenWidthLessThan" andParameter:wider];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenWidthLessThan" andParameter:narrower];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenWidthGreaterThan" andParameter:narrower];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenWidthGreaterThan" andParameter:wider];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
}

- (void) testPseudoClassScreenHeight {
    CGFloat height = MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    NSString* shorter = [NSString stringWithFormat:@"%f", height - 1];
    NSString* taller = [NSString stringWithFormat:@"%f", height + 1];
    
    UIView* randomView = [[UIView alloc] init];
    ISSElementStylingProxy* randomViewDetails = styler[randomView];
    
    ISSStylingContext* context = [self createStylingContext];
    
    ISSPseudoClass* widthPseudoClass = [self pseudoClassWithTypeString:@"screenHeight" andParameter:[NSString stringWithFormat:@"%f", height]];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenHeight" andParameter:shorter];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenHeight" andParameter:taller];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenHeightLessThan" andParameter:taller];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenHeightLessThan" andParameter:shorter];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenHeightGreaterThan" andParameter:shorter];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
    widthPseudoClass = [self pseudoClassWithTypeString:@"screenHeightGreaterThan" andParameter:taller];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails stylingContext:context]);
}

- (void) testWildcardSelectorFirst {
    ISSSelector* wildcardSelector = [self selectorWithType:@"*" styleClass:nil pseudoClasses:nil];
    ISSSelector* clildSelector = [self selectorWithType:@"UILabel" styleClass:@"childClass" pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[wildcardSelector, @(ISSSelectorCombinatorDescendant), clildSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSElementStylingProxy* labelDetails = styler[label];
    [labelDetails addStyleClass:@"childClass"];
    
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testWildcardSelectorMiddle {
    ISSSelector* wildcardSelector = [self selectorWithType:@"*" styleClass:nil pseudoClasses:nil];
    ISSSelector* parentSelector = [self selectorWithType:@"uiwindow" styleClass:nil pseudoClasses:nil];
    ISSSelector* clildSelector = [self selectorWithType:@"UILabel" styleClass:@"childClass" pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector, @(ISSSelectorCombinatorDescendant),
                                                                              wildcardSelector, @(ISSSelectorCombinatorDescendant), clildSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSElementStylingProxy* labelDetails = styler[label];
    [labelDetails addStyleClass:@"childClass"];
    
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testWildcardSelectorLast {
    ISSSelector* wildcardSelector = [self selectorWithType:@"*" styleClass:nil pseudoClasses:nil];
    ISSSelector* parentSelector = [self selectorWithType:@"uiview" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector, @(ISSSelectorCombinatorDescendant), wildcardSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSElementStylingProxy* labelDetails = styler[label];
    
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testWildcardSelectorFirstAndLast {
    ISSSelector* wildcardSelector = [self selectorWithType:@"*" styleClass:nil pseudoClasses:nil];
    ISSSelector* parentSelector = [self selectorWithType:@"uiview" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[wildcardSelector, @(ISSSelectorCombinatorDescendant),
                                                                              parentSelector, @(ISSSelectorCombinatorDescendant), wildcardSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSElementStylingProxy* labelDetails = styler[label];
    
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[self createStylingContext]], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testUsingNonUIKitClassAsType {
    ISSSelector* customClassTypeSelector = [self selectorWithType:@"MyCustomView" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* customClassTypeSelectorChain = [ISSSelectorChain selectorChainWithComponents:@[customClassTypeSelector]];
    
    // Verify that custom type selector matches custom class
    MyCustomView* myCustomView = [[MyCustomView alloc] init];
    ISSElementStylingProxy* elementDetails = styler[myCustomView];
    
    XCTAssertTrue([customClassTypeSelectorChain matchesElement:elementDetails stylingContext:[self createStylingContext]], @"Custom type selector chain must match custom class!");
    
    // Verify that custom type selector does NOT match UIView
    UIView* randomView = [[UIView alloc] init];
    elementDetails = styler[randomView];
    
    XCTAssertFalse([customClassTypeSelectorChain matchesElement:elementDetails stylingContext:[self createStylingContext]], @"Custom type selector chain must NOT match standard UIView!");
    
    // Verify that custom type selector does NOT match other custom class
    MyCustomView2* myCustomView2 = [[MyCustomView2 alloc] init];
    elementDetails = styler[myCustomView2];
    
    XCTAssertFalse([customClassTypeSelectorChain matchesElement:elementDetails stylingContext:[self createStylingContext]], @"Custom type selector chain must NOT match other custom class!");
    
    // Verify that custom type selector does match other custom class that is subclass of first class (create the selector and selector chain again, to make sure multiple occurances of the same custom type selector works)
    customClassTypeSelector = [self selectorWithType:@"MyCustomView" styleClass:nil pseudoClasses:nil];
    customClassTypeSelectorChain = [ISSSelectorChain selectorChainWithComponents:@[customClassTypeSelector]];
    
    MyCustomViewSubClass* myCustomViewSubClass = [[MyCustomViewSubClass alloc] init];
    elementDetails = styler[myCustomViewSubClass];
    
    XCTAssertTrue([customClassTypeSelectorChain matchesElement:elementDetails stylingContext:[self createStylingContext]], @"Custom type selector chain must match other custom class that is sub class of type in custom type selector!");
}

- (void) testViewControllerAsTypeSelector {
    SomeViewController* vc = [[SomeViewController alloc] init];


    // Test selector "UIViewController UIView"
    ISSSelector* viewControllerSelector = [self selectorWithType:@"UIViewController" styleClass:nil pseudoClasses:nil];
    ISSSelector* viewSelector = [self selectorWithType:@"UIView" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* viewSelectorChain = [ISSSelectorChain selectorChainWithComponents:@[viewControllerSelector, @(ISSSelectorCombinatorDescendant), viewSelector]];
    
    ISSElementStylingProxy* viewProxy = styler[vc.view];
    ISSElementStylingProxy* vcProxy = styler[vc];
    
    XCTAssertTrue([viewSelectorChain matchesElement:viewProxy stylingContext:[self createStylingContext]]);

    // Test selector "SomeViewController UIView"
    //[[InterfaCSS sharedInstance].propertyManager registerCanonicalTypeClass:SomeViewController.class]; // Register SomeViewController as a valid type selector class
    [styler.propertyManager registerCanonicalTypeClass:SomeViewController.class]; // Register SomeViewController as a valid type selector class
    
    [viewProxy resetWith:styler];
    [vcProxy resetWith:styler];

    ISSSelector* someViewControllerSelector = [self selectorWithType:@"SomeViewController" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* someViewControllerSelectorChain = [ISSSelectorChain selectorChainWithComponents:@[someViewControllerSelector, @(ISSSelectorCombinatorDescendant), viewSelector]];
    
    // Check that the view controller matches the selector chain with the newly registered type class:
    XCTAssertTrue([someViewControllerSelectorChain matchesElement:viewProxy stylingContext:[self createStylingContext]]);
    // Make sure that the "UIViewController" type selector no longer matches "SomeViewController"
    XCTAssertFalse([viewSelectorChain matchesElement:viewProxy stylingContext:[self createStylingContext]]);


    // Test selector "UIView SomeViewController UIView"
    ISSSelectorChain* someViewControllerSelectorChain2 = [ISSSelectorChain selectorChainWithComponents:@[viewSelector, @(ISSSelectorCombinatorDescendant), someViewControllerSelector, @(ISSSelectorCombinatorDescendant), viewSelector]];

    // Selector chain shouldn't match view controller with no super view:
    XCTAssertFalse([someViewControllerSelectorChain2 matchesElement:viewProxy stylingContext:[self createStylingContext]]);

    UIView* superView = [[UIView alloc] init];
    [superView addSubview:vc.view];

    // When added to super view, selector chanin should match:
    XCTAssertTrue([someViewControllerSelectorChain2 matchesElement:viewProxy stylingContext:[self createStylingContext]]);
}

- (void) testSelectorChainPartialMatch {
    UILabel* label = [[UILabel alloc] init];
    
    ISSSelector* viewSelector = [self selectorWithType:@"UIView" styleClass:nil pseudoClasses:nil];
    ISSSelector* labelSelector = [self selectorWithType:@"UILabel" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* selectorChain = [ISSSelectorChain selectorChainWithComponents:@[viewSelector, @(ISSSelectorCombinatorDescendant), labelSelector]];
    
    ISSStylingContext* context = [self createStylingContext];
    ISSElementStylingProxy* elementDetails = styler[label];
    BOOL result = [selectorChain matchesElement:elementDetails stylingContext:context];
    
    XCTAssertEqual(result, NO);
    XCTAssertEqual(context.containsPartiallyMatchedDeclarations, YES);
}

@end
