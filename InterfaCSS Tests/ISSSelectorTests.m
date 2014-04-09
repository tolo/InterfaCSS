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
    XCTAssertTrue([descendantChain matchesElement:labelDetails], @"Descendant selector chain must match!");
    
    ISSSelectorChain* childChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorChild childPseudoClass:nil];
    XCTAssertFalse([childChain matchesElement:labelDetails], @"Child selector chain must NOT match!");
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
    XCTAssertFalse([descendantChain matchesElement:labelDetails], @"Descendant selector chain must NOT match label with other parent!");
}

- (void) testChildAndDescendant {
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:nil];
    XCTAssertTrue([descendantChain matchesElement:labelDetails], @"Descendant selector chain must match!");
    
    ISSSelectorChain* childChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorChild childPseudoClass:nil];
    XCTAssertTrue([childChain matchesElement:labelDetails], @"Child selector chain must match!");
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
    
    if( adjacent ) XCTAssertTrue([chain matchesElement:labelDetails], @"Adjacent sibling selector chain must match!");
    else XCTAssertFalse([chain matchesElement:labelDetails], @"Adjacent sibling selector chain must NOT match!");
    
    chain = [ISSSelectorChain selectorChainWithComponents:@[buttonSelector, @(ISSSelectorCombinatorGeneralSibling), labelSelector]];
    XCTAssertTrue([chain matchesElement:labelDetails], @"General sibling selector chain must match!");
}

- (void) testAdjacentSibling {
    [self doTestSibling:YES];
}

- (void) testGeneralSibling {
    [self doTestSibling:NO];
}

- (void) testFirstChild {
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    ISSPseudoClass* pseudo = [ISSPseudoClass pseudoClassWithA:0 b:1 type:ISSPseudoClassTypeNthChild];
    
    ISSSelectorChain* descendantChain = [self createSelectorChainWithChildType:@"uilabel" combinator:ISSSelectorCombinatorDescendant childPseudoClass:pseudo];
    XCTAssertTrue([descendantChain matchesElement:labelDetails], @"Descendant first child selector chain must match!");
}

- (void) testWildcardSelectorFirst {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" class:nil pseudoClass:nil];
    ISSSelector* clildSelector = [ISSSelector selectorWithType:@"uilabel" class:@"childClass" pseudoClass:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[wildcardSelector, @(ISSSelectorCombinatorDescendant), clildSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    [label addStyleClassISS:@"childClass"];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails], @"Wildcard selector chain must match!");
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
    
    XCTAssertTrue([chain matchesElement:labelDetails], @"Wildcard selector chain must match!");
}

- (void) testWildcardSelectorLast {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" class:nil pseudoClass:nil];
    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiview" class:nil pseudoClass:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[parentSelector, @(ISSSelectorCombinatorDescendant), wildcardSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails], @"Wildcard selector chain must match!");
}

- (void) testWildcardSelectorFirstAndLast {
    ISSSelector* wildcardSelector = [ISSSelector selectorWithType:@"*" class:nil pseudoClass:nil];
    ISSSelector* parentSelector = [ISSSelector selectorWithType:@"uiview" class:nil pseudoClass:nil];
    ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[wildcardSelector, @(ISSSelectorCombinatorDescendant),
                                                                              parentSelector, @(ISSSelectorCombinatorDescendant), wildcardSelector]];
    
    UILabel* label = [[UILabel alloc] init];
    [rootView addSubview:label];
    ISSUIElementDetails* labelDetails = [[InterfaCSS interfaCSS] detailsForUIElement:label];
    
    XCTAssertTrue([chain matchesElement:labelDetails], @"Wildcard selector chain must match!");
}

@end
