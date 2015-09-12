//
//  InterfaCSS
//  ISSSelectorTest.m
//  
//  Created by Tobias Löfstrand on 2014-03-15.
//  Copyright (c) 2014 Leafnode AB. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "InterfaCSS.h"
#import "ISSStyleSheetParser.h"
#import "ISSPropertyDeclarations.h"
#import "ISSPropertyDeclaration.h"
#import "ISSPropertyDefinition.h"
#import "ISSSelectorChain.h"
#import "ISSSelector.h"
#import "ISSPseudoClass.h"
#import "ISSUIElementDetails.h"
#import "UIView+InterfaCSS.h"
#import "ISSPropertyRegistry.h"
#import "ISSStylingContext.h"


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
    id<ISSStyleSheetParser> parser;
    UIWindow* window;
    UIView* rootView;
}

- (void) setUp {
    [super setUp];

    parser = [InterfaCSS interfaCSS].parser;
    
    window = [[UIWindow alloc] init];
    
    rootView = [[UIView alloc] init];
    [window addSubview:rootView];
    [rootView addStyleClassISS:@"parentClass"];
}

- (void) tearDown {
    [super tearDown];
}


#pragma mark - Utils

- (ISSSelectorChain*) createSelectorChainWithChildType:(NSString*)type combinator:(ISSSelectorCombinator)combinator childPseudoClass:(ISSPseudoClass*)childPseudoClass {
    ISSSelector* parentSelector = [ISSSelector selectorWithType:nil styleClass:@"parentClass" pseudoClasses:nil];
    ISSSelector* clildSelector;
    if( childPseudoClass ) clildSelector = [ISSSelector selectorWithType:type styleClass:@"childClass" pseudoClasses:@[childPseudoClass]];
    else clildSelector = [ISSSelector selectorWithType:type styleClass:@"childClass" pseudoClasses:nil];
    return [ISSSelectorChain selectorChainWithComponents:@[parentSelector, @(combinator), clildSelector]];
}


#pragma mark - Tests


- (void) testDescendantButNotChild {
    UIView* inbetweenView = [[UIView alloc] init];
    [rootView addSubview:inbetweenView];
    
    UILabel* label = [[UILabel alloc] init];
    [inbetweenView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
 
    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:nil];
    XCTAssertTrue([descendantChain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Descendant selector chain must match!");
    
    ISSSelectorChain* childChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorChild childPseudoClass:nil];
    XCTAssertFalse([childChain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Child selector chain must NOT match!");
    
    XCTAssertFalse(childChain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testInvalidDescendant {
    UIView* otherRootView = [[UIView alloc] init];
    [window addSubview:otherRootView];
    [otherRootView addStyleClassISS:@"otherParentClass"];
    
    UILabel* label = [[UILabel alloc] init];
    [otherRootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:nil];
    XCTAssertFalse([descendantChain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Descendant selector chain must NOT match label with other parent!");
}

- (void) testChildAndDescendant {
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:nil];
    XCTAssertTrue([descendantChain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Descendant selector chain must match!");
    
    ISSSelectorChain* childChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorChild childPseudoClass:nil];
    XCTAssertTrue([childChain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Child selector chain must match!");
    
    XCTAssertFalse(childChain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) doTestSibling:(BOOL)adjacent {
    UIButton* button = [[UIButton alloc] init];
    [button addStyleClassISS:@"buttonClass"];
    [rootView addSubview:button];
    
    if( !adjacent ) {
        UILabel* anotherLabel = [[UILabel alloc] init];
        [rootView addSubview:anotherLabel];
        [anotherLabel addStyleClassISS:@"anotherLabelClass"];
    }
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"labelClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    ISSSelector* buttonSelector = [ISSSelector selectorWithType:@"uibutton" styleClass:@"buttonClass" pseudoClasses:nil];
    ISSSelector* labelSelector = [ISSSelector selectorWithType:@"uilabel" styleClass:@"labelClass" pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[buttonSelector, @(ISSSelectorCombinatorAdjacentSibling), labelSelector]];
    
    if( adjacent ) XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Adjacent sibling selector chain must match!");
    else XCTAssertFalse([chain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Adjacent sibling selector chain must NOT match!");
    
    chain = [ISSSelectorChain selectorChainWithComponents:@[buttonSelector, @(ISSSelectorCombinatorGeneralSibling), labelSelector]];
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"General sibling selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testAdjacentSibling {
    [self doTestSibling:YES];
}

- (void) testGeneralSibling {
    [self doTestSibling:NO];
}

- (void) assertDescendantPseudo:(UILabel*)label pseudoClassType:(ISSPseudoClassType)pseudoClassType a:(NSInteger)a b:(NSInteger)b message:(NSString*)message {
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    ISSPseudoClass* pseudo = [ISSPseudoClass structuralPseudoClassWithA:a b:b type:pseudoClassType];

    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:pseudo];
    XCTAssertTrue([descendantChain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"%@", message);
    XCTAssertTrue(descendantChain.hasPseudoClassSelector, @"Expected selector chain to report having pseudo class");
}

- (void) doTestNthChild:(BOOL)ofType {
    ISSPseudoClassType pseudoClassType = ofType ? ISSPseudoClassTypeNthOfType : ISSPseudoClassTypeNthChild;

    NSMutableArray* labels = [NSMutableArray array];
    for(NSUInteger i=0; i<5; i++) {
        labels[i] = [[UILabel alloc] init];
        [rootView addSubview:labels[i]];
        [labels[i] addStyleClassISS:@"childClass"];

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
        [labels[i] addStyleClassISS:@"childClass"];
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
    ISSUIElementDetails* viewDetails = [[InterfaCSS interfaCSS] detailsForUIElement:rootView];
    ISSPseudoClass* pseudo = [ISSPseudoClass structuralPseudoClassWithA:0 b:1 type:ISSPseudoClassTypeEmpty];

    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiview" styleClass:@"parentClass" pseudoClasses:@[pseudo]];

    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector]];

    XCTAssertTrue([chain matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]], @"Empty structural pseudo class selector must match empty root view!");

    [rootView addSubview:[[UIButton alloc] init]];
    XCTAssertTrue(![chain matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]], @"Empty structural pseudo class selector must NOT match root view that contains subviews!");
    
    XCTAssertTrue(chain.hasPseudoClassSelector, @"Expected selector chain to report having pseudo class");
}

- (void) testPseudoClassControlState {
    UIButton* button = [[UIButton alloc] init];
    ISSUIElementDetails* viewDetails = [[InterfaCSS interfaCSS] detailsForUIElement:button];
    
    ISSPseudoClass* enabledPseudo = [ISSPseudoClass pseudoClassWithTypeString:@"enabled"];
    ISSPseudoClass* disabledPseudo = [ISSPseudoClass pseudoClassWithTypeString:@"disabled"];
    ISSPseudoClass* selectedPseudo = [ISSPseudoClass pseudoClassWithTypeString:@"selected"];
    ISSPseudoClass* highlightedPseudo = [ISSPseudoClass pseudoClassWithTypeString:@"highlighted"];
    
    ISSSelectorChain* enabledSelector = [ISSSelectorChain selectorChainWithSelector:[ISSSelector selectorWithType:@"uibutton" styleClass:nil pseudoClasses:@[enabledPseudo]]];
    ISSSelectorChain* disabledSelector = [ISSSelectorChain selectorChainWithSelector:[ISSSelector selectorWithType:@"uibutton" styleClass:nil pseudoClasses:@[disabledPseudo]]];
    ISSSelectorChain* selectedSelector = [ISSSelectorChain selectorChainWithSelector:[ISSSelector selectorWithType:@"uibutton" styleClass:nil pseudoClasses:@[selectedPseudo]]];
    ISSSelectorChain* highlightedSelector = [ISSSelectorChain selectorChainWithSelector:[ISSSelector selectorWithType:@"uibutton" styleClass:nil pseudoClasses:@[highlightedPseudo]]];
    ISSSelectorChain* selectedHighlightedSelector = [ISSSelectorChain selectorChainWithSelector:[ISSSelector selectorWithType:@"uibutton" styleClass:nil pseudoClasses:@[selectedPseudo, highlightedPseudo]]];
    
    // Test disabled
    button.enabled = NO;
    XCTAssertTrue([disabledSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
    XCTAssertFalse([enabledSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
    
    // Test enabled
    button.enabled = YES;
    XCTAssertTrue([enabledSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
    XCTAssertFalse([disabledSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
    
    // Check negative result for selected and highlighted
    XCTAssertFalse([selectedSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
    XCTAssertFalse([highlightedSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
    XCTAssertFalse([selectedHighlightedSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
    
    // Test selected
    button.selected = YES;
    XCTAssertTrue([selectedSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
    
    // Test selected
    button.highlighted = YES;
    XCTAssertTrue([highlightedSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
    
    // Test selected & highlighted (chained)
    XCTAssertTrue([selectedHighlightedSelector matchesElement:viewDetails stylingContext:[[ISSStylingContext alloc] init]]);
}

- (void) testPseudoClassOSVersion {
    NSString* currentSystemVersion = [UIDevice currentDevice].systemVersion;
    NSString* majorVersion = [currentSystemVersion componentsSeparatedByString:@"."][0];
    NSString* previousVersion = [NSString stringWithFormat:@"%d", (int)[majorVersion integerValue] - 1];
    NSString* nextVersion = [NSString stringWithFormat:@"%d", (int)[majorVersion integerValue] + 1];
    
    UIView* randomView = [[UIView alloc] init];
    ISSUIElementDetails* randomViewDetails = [[InterfaCSS interfaCSS] detailsForUIElement:randomView];
    
    ISSPseudoClass* osVersionPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"minOSVersion" andParameter:currentSystemVersion];
    XCTAssertTrue([osVersionPseudoClass matchesElement:randomViewDetails]);
    osVersionPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"minOSVersion" andParameter:previousVersion];
    XCTAssertTrue([osVersionPseudoClass matchesElement:randomViewDetails]);
    osVersionPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"minOSVersion" andParameter:nextVersion];
    XCTAssertFalse([osVersionPseudoClass matchesElement:randomViewDetails]);
    
    osVersionPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"maxOSVersion" andParameter:currentSystemVersion];
    XCTAssertTrue([osVersionPseudoClass matchesElement:randomViewDetails]);
    osVersionPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"maxOSVersion" andParameter:previousVersion];
    XCTAssertFalse([osVersionPseudoClass matchesElement:randomViewDetails]);
    osVersionPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"maxOSVersion" andParameter:nextVersion];
    XCTAssertTrue([osVersionPseudoClass matchesElement:randomViewDetails]);
}

- (void) testPseudoClassScreenWidth {
    CGFloat width = [UIScreen mainScreen].bounds.size.width;
    NSString* narrower = [NSString stringWithFormat:@"%f", width - 1];
    NSString* wider = [NSString stringWithFormat:@"%f", width + 1];
    
    UIView* randomView = [[UIView alloc] init];
    ISSUIElementDetails* randomViewDetails = [[InterfaCSS interfaCSS] detailsForUIElement:randomView];
    
    ISSPseudoClass* widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenWidth" andParameter:[NSString stringWithFormat:@"%f", width]];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails]);
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenWidth" andParameter:narrower];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails]);
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenWidth" andParameter:wider];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails]);
    
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenWidthLessThan" andParameter:wider];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails]);
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenWidthLessThan" andParameter:narrower];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails]);
    
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenWidthGreaterThan" andParameter:narrower];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails]);
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenWidthGreaterThan" andParameter:wider];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails]);
}

- (void) testPseudoClassScreenHeight {
    CGFloat height = [UIScreen mainScreen].bounds.size.height;
    NSString* shorter = [NSString stringWithFormat:@"%f", height - 1];
    NSString* taller = [NSString stringWithFormat:@"%f", height + 1];
    
    UIView* randomView = [[UIView alloc] init];
    ISSUIElementDetails* randomViewDetails = [[InterfaCSS interfaCSS] detailsForUIElement:randomView];
    
    ISSPseudoClass* widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenHeight" andParameter:[NSString stringWithFormat:@"%f", height]];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails]);
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenHeight" andParameter:shorter];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails]);
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenHeight" andParameter:taller];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails]);
    
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenHeightLessThan" andParameter:taller];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails]);
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenHeightLessThan" andParameter:shorter];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails]);
    
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenHeightGreaterThan" andParameter:shorter];
    XCTAssertTrue([widthPseudoClass matchesElement:randomViewDetails]);
    widthPseudoClass = [ISSPseudoClass pseudoClassWithTypeString:@"screenHeightGreaterThan" andParameter:taller];
    XCTAssertFalse([widthPseudoClass matchesElement:randomViewDetails]);
}

- (void) testWildcardSelectorFirst {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" styleClass:nil pseudoClasses:nil];
    ISSSelector* clildSelector = [ISSSelector selectorWithType:@"uilabel" styleClass:@"childClass" pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[wildcardSelector, @(ISSSelectorCombinatorDescendant), clildSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testWildcardSelectorMiddle {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" styleClass:nil pseudoClasses:nil];
    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiwindow" styleClass:nil pseudoClasses:nil];
    ISSSelector* clildSelector = [ISSSelector selectorWithType:@"uilabel" styleClass:@"childClass" pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector, @(ISSSelectorCombinatorDescendant),
                                                                              wildcardSelector, @(ISSSelectorCombinatorDescendant), clildSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testWildcardSelectorLast {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" styleClass:nil pseudoClasses:nil];
    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiview" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector, @(ISSSelectorCombinatorDescendant), wildcardSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testWildcardSelectorFirstAndLast {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" styleClass:nil pseudoClasses:nil];
    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiview" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[wildcardSelector, @(ISSSelectorCombinatorDescendant),
                                                                              parentSelector, @(ISSSelectorCombinatorDescendant), wildcardSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails stylingContext:[[ISSStylingContext alloc] init]], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testUsingNonUIKitClassAsType {
    // Enable automatic registration of type classes whenever they are encountered in selectors
    [InterfaCSS sharedInstance].allowAutomaticRegistrationOfCustomTypeSelectorClasses = YES;
    
    ISSSelector* customClassTypeSelector = [ISSSelector selectorWithType:@"MyCustomView" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* customClassTypeSelectorChain = [ISSSelectorChain selectorChainWithComponents:@[customClassTypeSelector]];
    
    // Verify that custom type selector matches custom class
    MyCustomView* myCustomView = [[MyCustomView alloc] init];
    ISSUIElementDetails* elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:myCustomView];
    
    XCTAssertTrue([customClassTypeSelectorChain matchesElement:elementDetails stylingContext:[[ISSStylingContext alloc] init]], @"Custom type selector chain must match custom class!");
    
    // Verify that custom type selector does NOT match UIView
    UIView* randomView = [[UIView alloc] init];
    elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:randomView];
    
    XCTAssertFalse([customClassTypeSelectorChain matchesElement:elementDetails stylingContext:[[ISSStylingContext alloc] init]], @"Custom type selector chain must NOT match standard UIView!");
    
    // Verify that custom type selector does NOT match other custom class
    MyCustomView2* myCustomView2 = [[MyCustomView2 alloc] init];
    elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:myCustomView2];
    
    XCTAssertFalse([customClassTypeSelectorChain matchesElement:elementDetails stylingContext:[[ISSStylingContext alloc] init]], @"Custom type selector chain must NOT match other custom class!");
    
    // Verify that custom type selector does match other custom class that is subclass of first class (create the selector and selector chain again, to make sure multiple occurances of the same custom type selector works)
    customClassTypeSelector = [ISSSelector selectorWithType:@"MyCustomView" styleClass:nil pseudoClasses:nil];
    customClassTypeSelectorChain = [ISSSelectorChain selectorChainWithComponents:@[customClassTypeSelector]];
    
    MyCustomViewSubClass* myCustomViewSubClass = [[MyCustomViewSubClass alloc] init];
    elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:myCustomViewSubClass];
    
    XCTAssertTrue([customClassTypeSelectorChain matchesElement:elementDetails stylingContext:[[ISSStylingContext alloc] init]], @"Custom type selector chain must match other custom class that is sub class of type in custom type selector!");
}

- (void) testViewControllerAsTypeSelector {
    // For this test case, we will use manual registration of type classes instead of doing it automatically
    [InterfaCSS sharedInstance].allowAutomaticRegistrationOfCustomTypeSelectorClasses = NO;
    
    SomeViewController* vc = [[SomeViewController alloc] init];


    // Test selector "UIViewController UIView"
    ISSSelector* viewControllerSelector = [ISSSelector selectorWithType:@"UIViewController" styleClass:nil pseudoClasses:nil];
    ISSSelector* viewSelector = [ISSSelector selectorWithType:@"UIView" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* viewSelectorChain = [ISSSelectorChain selectorChainWithComponents:@[viewControllerSelector, @(ISSSelectorCombinatorDescendant), viewSelector]];
    
    ISSUIElementDetails* elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:vc.view];
    
    XCTAssertTrue([viewSelectorChain matchesElement:elementDetails stylingContext:[[ISSStylingContext alloc] init]]);

    [elementDetails resetCachedData];


    // Test selector "SomeViewController UIView"
    [[InterfaCSS sharedInstance].propertyRegistry registerCanonicalTypeClass:SomeViewController.class]; // Register SomeViewController as a valid type selector class

    ISSSelector* someViewControllerSelector = [ISSSelector selectorWithType:@"SomeViewController" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* someViewControllerSelectorChain = [ISSSelectorChain selectorChainWithComponents:@[someViewControllerSelector, @(ISSSelectorCombinatorDescendant), viewSelector]];
    
    // Check that the view controller matches the selector chain with the newly registered type class:
    XCTAssertTrue([someViewControllerSelectorChain matchesElement:elementDetails stylingContext:[[ISSStylingContext alloc] init]]);
    // Make sure that the "UIViewController" type selector no longer matches "SomeViewController"
    XCTAssertFalse([viewSelectorChain matchesElement:elementDetails stylingContext:[[ISSStylingContext alloc] init]]);


    // Test selector "UIView SomeViewController UIView"
    ISSSelectorChain* someViewControllerSelectorChain2 = [ISSSelectorChain selectorChainWithComponents:@[viewSelector, @(ISSSelectorCombinatorDescendant), someViewControllerSelector, @(ISSSelectorCombinatorDescendant), viewSelector]];

    // Selector chain shouldn't match view controller with no super view:
    XCTAssertFalse([someViewControllerSelectorChain2 matchesElement:elementDetails stylingContext:[[ISSStylingContext alloc] init]]);

    UIView* superView = [[UIView alloc] init];
    [superView addSubview:vc.view];

    // When added to super view, selector chanin should match:
    XCTAssertTrue([someViewControllerSelectorChain2 matchesElement:elementDetails stylingContext:[[ISSStylingContext alloc] init]]);
}

- (void) testSelectorChainPartialMatch {
    UILabel* label = [[UILabel alloc] init];
    
    ISSSelector* viewSelector = [ISSSelector selectorWithType:@"UIView" styleClass:nil pseudoClasses:nil];
    ISSSelector* labelSelector = [ISSSelector selectorWithType:@"UILabel" styleClass:nil pseudoClasses:nil];
    ISSSelectorChain* selectorChain = [ISSSelectorChain selectorChainWithComponents:@[viewSelector, @(ISSSelectorCombinatorDescendant), labelSelector]];
    
    ISSStylingContext* context = [[ISSStylingContext alloc] init];
    ISSUIElementDetails* elementDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    BOOL result = [selectorChain matchesElement:elementDetails stylingContext:context];
    
    XCTAssertEqual(result, NO);
    XCTAssertEqual(context.containsPartiallyMatchedDeclarations, YES);
}

@end
