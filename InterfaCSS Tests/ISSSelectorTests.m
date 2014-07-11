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
    ISSSelector* parentSelector = [ISSSelector selectorWithType:nil class:@"parentClass" pseudoClass:nil];
    ISSSelector* clildSelector = [ISSSelector selectorWithType:type class:@"childClass" pseudoClass:childPseudoClass];
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
    XCTAssertTrue([descendantChain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Descendant selector chain must match!");
    
    ISSSelectorChain* childChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorChild childPseudoClass:nil];
    XCTAssertFalse([childChain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Child selector chain must NOT match!");
    
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
    XCTAssertFalse([descendantChain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Descendant selector chain must NOT match label with other parent!");
}

- (void) testChildAndDescendant {
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:nil];
    XCTAssertTrue([descendantChain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Descendant selector chain must match!");
    
    ISSSelectorChain* childChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorChild childPseudoClass:nil];
    XCTAssertTrue([childChain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Child selector chain must match!");
    
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
    
    ISSSelector* buttonSelector = [ISSSelector selectorWithType:@"uibutton" class:@"buttonClass" pseudoClass:nil];
    ISSSelector* labelSelector = [ISSSelector selectorWithType:@"uilabel" class:@"labelClass" pseudoClass:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[buttonSelector, @(ISSSelectorCombinatorAdjacentSibling), labelSelector]];
    
    if( adjacent ) XCTAssertTrue([chain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Adjacent sibling selector chain must match!");
    else XCTAssertFalse([chain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Adjacent sibling selector chain must NOT match!");
    
    chain = [ISSSelectorChain selectorChainWithComponents:@[buttonSelector, @(ISSSelectorCombinatorGeneralSibling), labelSelector]];
    XCTAssertTrue([chain matchesElement:labelDetails ignoringPseudoClasses:NO], @"General sibling selector chain must match!");
    
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
    ISSPseudoClass* pseudo = [ISSPseudoClass pseudoClassWithA:a b:b type:pseudoClassType];

    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:pseudo];
    XCTAssertTrue([descendantChain matchesElement:labelDetails ignoringPseudoClasses:NO], @"%@", message);
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

- (void) testNthChild {
    [self doTestNthChild:NO];
}

- (void) testNthChildOfType {
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

- (void) testNthLastChild {
    [self doTestNthLastChild:NO];
}

- (void) testNthLastChildOfType {
    [self doTestNthLastChild:YES];
}

- (void) testEmpty {
    ISSUIElementDetails* viewDetails = [[InterfaCSS interfaCSS] detailsForUIElement:rootView];
    ISSPseudoClass* pseudo = [ISSPseudoClass pseudoClassWithA:0 b:1 type:ISSPseudoClassTypeEmpty];

    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiview" class:@"parentClass" pseudoClass:pseudo];

    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector]];

    XCTAssertTrue([chain matchesElement:viewDetails ignoringPseudoClasses:NO], @"Empty structural pseudo class selector must match empty root view!");

    [rootView addSubview:[[UIButton alloc] init]];
    XCTAssertTrue(![chain matchesElement:viewDetails ignoringPseudoClasses:NO], @"Empty structural pseudo class selector must NOT match root view that contains subviews!");
    
    XCTAssertTrue(chain.hasPseudoClassSelector, @"Expected selector chain to report having pseudo class");
}

- (void) testWildcardSelectorFirst {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" class:nil pseudoClass:nil];
    ISSSelector* clildSelector = [ISSSelector selectorWithType:@"uilabel" class:@"childClass" pseudoClass:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[wildcardSelector, @(ISSSelectorCombinatorDescendant), clildSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testWildcardSelectorMiddle {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" class:nil pseudoClass:nil];
    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiwindow" class:nil pseudoClass:nil];
    ISSSelector* clildSelector = [ISSSelector selectorWithType:@"uilabel" class:@"childClass" pseudoClass:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector, @(ISSSelectorCombinatorDescendant),
                                                                              wildcardSelector, @(ISSSelectorCombinatorDescendant), clildSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testWildcardSelectorLast {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" class:nil pseudoClass:nil];
    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiview" class:nil pseudoClass:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector, @(ISSSelectorCombinatorDescendant), wildcardSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

- (void) testWildcardSelectorFirstAndLast {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" class:nil pseudoClass:nil];
    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiview" class:nil pseudoClass:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[wildcardSelector, @(ISSSelectorCombinatorDescendant),
                                                                              parentSelector, @(ISSSelectorCombinatorDescendant), wildcardSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails ignoringPseudoClasses:NO], @"Wildcard selector chain must match!");
    
    XCTAssertFalse(chain.hasPseudoClassSelector, @"Expected selector chain to report not having pseudo class");
}

@end
