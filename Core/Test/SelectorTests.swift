//
//  SelectorTests.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import XCTest
@testable import Core

class SelectorTests: XCTestCase {
  
  var styler: StylingManager!
  var styleSheetManager: StyleSheetManager!
  var window: UIWindow!
  var rootView: UIView!
  
  override func setUp() {
    styler = StylingManager()
    styleSheetManager = styler.styleSheetManager
    
    window = UIWindow()
    window.makeKeyAndVisible()
    rootView = UIView()
    window.addSubview(rootView)
    rootView.interfaCSS.addStyleClass("parentClass")
  }
  
  override func tearDown() {
  }
  
  
  // MARK: - Utils
  
  private func createSelector(withType type: String? = nil, elementId: String? = nil, styleClasses: [String]? = nil, pseudoClasses: [PseudoClass]? = nil) -> Core.Selector {
    return styleSheetManager.createSelector(withType: type, elementId: elementId, styleClasses: styleClasses, pseudoClasses: pseudoClasses)!
  }
  
  private func createSelector(withType type: String? = nil, elementId: String? = nil, styleClass: String, pseudoClasses: [PseudoClass]? = nil) -> Core.Selector {
    return createSelector(withType: type, elementId: elementId, styleClasses: [styleClass], pseudoClasses: pseudoClasses)
  }
  
  private func createSelectorChain(withChildType type: String, combinator: SelectorCombinator, childPseudoClasses: [PseudoClass]? = nil) -> SelectorChain {
    let parentSelector = createSelector(styleClasses: ["parentClass"])
    let childSelector = createSelector(withType: type, styleClasses: ["childClass"], pseudoClasses: childPseudoClasses)
    return SelectorChain(components: [.selector(parentSelector), .combinator(combinator), .selector(childSelector)])!
  }
  
  private func pseudoClassWithTypeString(_ type: String, andParameter param: String? = nil) -> PseudoClass {
    if let param = param {
      return styleSheetManager.pseudoClassFactory.createPseudoClass(ofType: type, withParameter: param)!
    } else {
      return styleSheetManager.pseudoClassFactory.createSimplePseudoClass(ofType: type)!
    }
  }
  
  private func createStylingContext() -> StylingContext {
    StylingContext(styler: styler)
  }
  
  private func createChildLabel(andAddTo parentView: UIView? = nil) -> ElementStyle {
    let label = UILabel()
    if let parentView = parentView {
      parentView.addSubview(label)
    }
    let labelStyle = label.interfaCSS
    labelStyle.addStyleClass("childClass")
    return labelStyle
  }
  
  private func setup<T: UIView>(_ view: T, withClass clazz: String = "childClass", andAddTo parentView: UIView? = nil) -> T {
    if let parentView = parentView {
      parentView.addSubview(view)
    }
    view.interfaCSS.addStyleClass(clazz);
    return view
  }
  
  // MARK: - Tests
  
  func testMultiClassSelector() {
    let singleClassSelector = createSelector(styleClass: "class1")
    let multiClassSelector = createSelector(styleClasses: ["class1", "class2"])
    
    let view = UIView()
    let elementStyle = view.interfaCSS
    elementStyle.addStyleClass("class1")
    
    XCTAssertTrue(singleClassSelector.matches(elementStyle, context: createStylingContext()), "Single class selector must match element with style class!")
    XCTAssertFalse(multiClassSelector.matches(elementStyle, context: createStylingContext()), "Multi class selector must NOT match element with single class!")
    
    elementStyle.addStyleClass("anotherClass")
    
    XCTAssertTrue(singleClassSelector.matches(elementStyle, context: createStylingContext()), "Single class selector must match element with style class!")
    XCTAssertFalse(multiClassSelector.matches(elementStyle, context: createStylingContext()), "Multi class selector must NOT match element with only partial match!")
    
    elementStyle.addStyleClass("class2")
    
    XCTAssertTrue(singleClassSelector.matches(elementStyle, context: createStylingContext()), "Single class selector must match element with style class!")
    XCTAssertTrue(multiClassSelector.matches(elementStyle, context: createStylingContext()), "Multi class selector must match element with multiple classes!")
  }
  
  func testDescendantButNotChild() {
    let descendantChain = createSelectorChain(withChildType: "UILabel", combinator:.descendant)
    let childChain = createSelectorChain(withChildType: "UILabel", combinator:.child)
    
    let inbetweenView = UIView()
    rootView.addSubview(inbetweenView)
    
    let labelStyle = createChildLabel(andAddTo: inbetweenView)
    
    XCTAssertTrue(descendantChain.matches(labelStyle, context: createStylingContext()), "Descendant selector chain must match!")
    
    XCTAssertFalse(childChain.matches(labelStyle, context: createStylingContext()), "Child selector chain must NOT match!")
    
    XCTAssertFalse(childChain.hasPseudoClassSelector, "Expected selector chain to report not having pseudo class")
  }
  
  func testInvalidDescendant() {
    let descendantChain = createSelectorChain(withChildType: "UILabel", combinator:.descendant)
    
    let otherRootView = UIView()
    window.addSubview(otherRootView)
    otherRootView.interfaCSS.addStyleClass("otherParentClass")
    
    let labelStyle = createChildLabel(andAddTo: otherRootView)
    
    XCTAssertFalse(descendantChain.matches(labelStyle, context: createStylingContext()), "Descendant selector chain must NOT match label with other parent!")
  }
  
  func testChildAndDescendant() {
    let descendantChain = createSelectorChain(withChildType: "UILabel", combinator:.descendant)
    let childChain = createSelectorChain(withChildType: "UILabel", combinator:.child)
    
    let labelStyle = createChildLabel(andAddTo: rootView)
    
    XCTAssertTrue(descendantChain.matches(labelStyle, context: createStylingContext()), "Descendant selector chain must match!")
    
    XCTAssertTrue(childChain.matches(labelStyle, context:createStylingContext()), "Child selector chain must match!")
    
    XCTAssertFalse(childChain.hasPseudoClassSelector, "Expected selector chain to report not having pseudo class")
  }
  
  func testDeepChildAndDescendant() {
    let view1 = setup(UIView(), withClass: "view1", andAddTo: rootView)
    let view2 = setup(UIScrollView(), withClass: "view2", andAddTo: view1)
    
    let button = UIButton()
    view2.addSubview(button)
    
    let chain = SelectorChain(components: [
                                           .selector(createSelector(withType: "UIView")),
                                           .combinator(.child),
                                           .selector(createSelector(withType: "UIView", styleClass: "view1")),
                                           .combinator(.descendant),
                                           .selector(createSelector(withType: "UIScrollView", styleClass: "view2")),
                                           .combinator(.child),
                                           .selector(createSelector(withType: "UIButton")),
                                           .combinator(.descendant),
                                           .selector(.nestedElement(nestedElementKeyPath: "titleLabel")),
                                          ])
    
    let elementStyle = button.titleLabel!.interfaCSS
    
    XCTAssertTrue(chain!.matches(elementStyle, context: createStylingContext()), "Deep descendant/child selector chain must match!")
  }
  
  private func doTestSibling(adjacent: Bool) {
    _ = setup(UIButton(), withClass: "buttonClass", andAddTo: rootView)
    if( !adjacent ) {
      _ = setup(UILabel(), withClass: "anotherLabelClass", andAddTo: rootView)
    }
    let labelStyle = setup(UILabel(), withClass: "labelClass", andAddTo: rootView).interfaCSS
    
    let buttonSelector = createSelector(withType: "UIButton", styleClass: "buttonClass")
    let labelSelector = createSelector(withType: "UILabel", styleClass: "labelClass")
    var chain = SelectorChain(components: [.selector(buttonSelector), .combinator(.sibling), .selector(labelSelector)])
    
    if( adjacent ) {
      XCTAssertTrue(chain!.matches(labelStyle, context:createStylingContext()), "Adjacent sibling selector chain must match!")
    } else {
      XCTAssertFalse(chain!.matches(labelStyle, context:createStylingContext()), "Adjacent sibling selector chain must NOT match!")
    }
    
    chain = SelectorChain(components: [.selector(buttonSelector), .combinator(.generalSibling), .selector(labelSelector)])
    
    XCTAssertTrue(chain!.matches(labelStyle, context:createStylingContext()), "General sibling selector chain must match!")
    
    XCTAssertFalse(chain!.hasPseudoClassSelector, "Expected selector chain to report not having pseudo class")
  }
  
  func testAdjacentSibling() {
    doTestSibling(adjacent: true)
  }
  
  func testGeneralSibling() {
    doTestSibling(adjacent: false)
  }
  
  private func assertDescendantPseudo(_ label: UILabel, pseudoClassType: String, a: Int, b: Int, message: String) {
    let labelStyle = label.interfaCSS
    let pseudo = styleSheetManager.pseudoClassFactory.createStructuralPseudoClass(ofType: pseudoClassType, a: a, b: b)!
    
    let chain = createSelectorChain(withChildType: "UILabel", combinator: .descendant, childPseudoClasses: [pseudo])
    XCTAssertTrue(chain.matches(labelStyle, context:createStylingContext()), message)
    XCTAssertTrue(chain.hasPseudoClassSelector, "Expected selector chain to report having pseudo class")
  }
  
  private func doTestNthChild(ofType: Bool) {
    let pseudoClassType = ofType ? "nthoftype" : "nthchild"
    
    var labels = [UILabel]()
    for i in 0..<5 {
      labels.append(setup(UILabel(), withClass: "childClass", andAddTo: rootView))
      if ofType  {
        rootView.addSubview(UIButton())
        if i == 0 {
          // Test only of type
          assertDescendantPseudo(labels[0], pseudoClassType: "onlyoftype", a: 0, b: 1, message: "Descendant only of type pseudo selector chain must match!")
        }
      } else if i == 0 {
        // Test only child
        assertDescendantPseudo(labels[0], pseudoClassType: "onlychild", a: 0, b: 1, message: "Descendant only child pseudo selector chain must match!")
      }
    }
    
    // First child - same logic applies for ISSPseudoClassTypeNthChild/ISSPseudoClassTypeFirstChild and ISSPseudoClassTypeFirstOfType/ISSPseudoClassTypeNthOfType
    assertDescendantPseudo(labels[0], pseudoClassType: pseudoClassType, a: 0, b: 1, message: "Descendant first child pseudo selector chain must match!")
    
    // 5th child
    assertDescendantPseudo(labels[4], pseudoClassType: pseudoClassType, a: 0, b: 5, message: "Descendant nth child (5) pseudo selector chain must match!")
    
    // Odd child
    assertDescendantPseudo(labels[0], pseudoClassType: pseudoClassType, a: 2, b: 1, message: "Descendant odd child (first) pseudo selector chain must match!")
    assertDescendantPseudo(labels[2], pseudoClassType: pseudoClassType, a: 2, b: 1, message: "Descendant odd child (third) pseudo selector chain must match!")
    
    // Even child
    assertDescendantPseudo(labels[1], pseudoClassType: pseudoClassType, a: 2, b: 0, message: "Descendant even child (second) pseudo selector chain must match!")
    assertDescendantPseudo(labels[3], pseudoClassType: pseudoClassType, a: 2, b: 0, message: "Descendant even child (fourth) pseudo selector chain must match!")
  }
  
  func testPseudoClassNthChild() {
    doTestNthChild(ofType: false)
  }
  
  func testPseudoClassNthChildOfType() {
    doTestNthChild(ofType: true)
  }
  
  func doTestNthLastChild(ofType: Bool) {
    let pseudoClassType = ofType ? "nthlastoftype" : "nthlastchild"
    
    var labels = [UILabel]()
    for _ in 0..<5 {
      labels.append(setup(UILabel(), withClass: "childClass", andAddTo: rootView))
      if( ofType ) {
        rootView.addSubview(UIButton())
      }
    }
    
    // Last child
    assertDescendantPseudo(labels[4], pseudoClassType: pseudoClassType, a: 0, b: 1, message: "Descendant last child pseudo selector chain must match!")
    
    // 5th last child
    assertDescendantPseudo(labels[0], pseudoClassType: pseudoClassType, a: 0, b: 5, message: "Descendant nth last child (5) pseudo selector chain must match!")
  }
  
  func testPseudoClassNthLastChild() {
    doTestNthLastChild(ofType: false)
  }
  
  func testPseudoClassNthLastChildOfType() {
    doTestNthLastChild(ofType: true)
  }
  
  func testPseudoClassEmpty() {
    let viewDetails = rootView.interfaCSS
    let pseudo = styleSheetManager.pseudoClassFactory.createStructuralPseudoClass(ofType: "empty", a: 0, b: 1)!
    let parentSelector = createSelector(withType: "UIView", styleClass: "parentClass", pseudoClasses: [pseudo])
    let chain = SelectorChain(selector: parentSelector)
    
    XCTAssertTrue(chain.matches(viewDetails, context:createStylingContext()), "Empty structural pseudo class selector must match empty root view!")
    
    rootView.addSubview(UIButton())
    
    XCTAssertFalse(chain.matches(viewDetails, context:createStylingContext()), "Empty structural pseudo class selector must NOT match root view that contains subviews!")
  }
  
  
  func testPseudoClassControlState() {
    let button = UIButton()
    let viewDetails = button.interfaCSS
    
    let enabledPseudo = pseudoClassWithTypeString("enabled")
    let disabledPseudo = pseudoClassWithTypeString("disabled")
    let selectedPseudo = pseudoClassWithTypeString("selected")
    let highlightedPseudo = pseudoClassWithTypeString("highlighted")
    
    let enabledSelector = SelectorChain(selector: createSelector(withType: "UIButton", pseudoClasses: [enabledPseudo]))
    let disabledSelector = SelectorChain(selector: createSelector(withType: "UIButton", pseudoClasses: [disabledPseudo]))
    let selectedSelector = SelectorChain(selector: createSelector(withType: "UIButton", pseudoClasses: [selectedPseudo]))
    let highlightedSelector = SelectorChain(selector: createSelector(withType: "UIButton", pseudoClasses: [highlightedPseudo]))
    let selectedHighlightedSelector = SelectorChain(selector: createSelector(withType: "UIButton", pseudoClasses: [selectedPseudo, highlightedPseudo]))
    
    // Test disabled
    button.isEnabled = false
    XCTAssertTrue(disabledSelector.matches(viewDetails, context:createStylingContext()))
    XCTAssertFalse(enabledSelector.matches(viewDetails, context:createStylingContext()))
    
    // Test enabled
    button.isEnabled = true
    XCTAssertTrue(enabledSelector.matches(viewDetails, context:createStylingContext()))
    XCTAssertFalse(disabledSelector.matches(viewDetails, context:createStylingContext()))
    
    // Check negative result for selected and highlighted
    XCTAssertFalse(selectedSelector.matches(viewDetails, context:createStylingContext()))
    XCTAssertFalse(highlightedSelector.matches(viewDetails, context:createStylingContext()))
    XCTAssertFalse(selectedHighlightedSelector.matches(viewDetails, context:createStylingContext()))
    
    // Test selected
    button.isSelected = true
    XCTAssertTrue(selectedSelector.matches(viewDetails, context:createStylingContext()))
    
    // Test highlighted
    button.isHighlighted = true
    XCTAssertTrue(highlightedSelector.matches(viewDetails, context:createStylingContext()))
    
    // Test selected & highlighted (chained)
    XCTAssertTrue(selectedHighlightedSelector.matches(viewDetails, context:createStylingContext()))
  }
  
  func testPseudoClassOSVersion() {
    let currentSystemVersion = UIDevice.current.systemVersion
    let majorVersion = currentSystemVersion.components(separatedBy: ".")[0] as NSString
    let previousVersion = "\(majorVersion.integerValue - 1)"
    let nextVersion = "\(majorVersion.integerValue + 1)"
    
    let randomView = UIView()
    let randomViewDetails = randomView.interfaCSS
    let context = createStylingContext()
    
    var osVersionPseudoClass = pseudoClassWithTypeString("minOSVersion", andParameter: currentSystemVersion)
    XCTAssertTrue(osVersionPseudoClass.matches(randomViewDetails, context: context))
    osVersionPseudoClass = pseudoClassWithTypeString("minOSVersion", andParameter: previousVersion)
    XCTAssertTrue(osVersionPseudoClass.matches(randomViewDetails, context: context))
    osVersionPseudoClass = pseudoClassWithTypeString("minOSVersion", andParameter: nextVersion)
    XCTAssertFalse(osVersionPseudoClass.matches(randomViewDetails, context: context))
    
    osVersionPseudoClass = pseudoClassWithTypeString("maxOSVersion", andParameter: currentSystemVersion)
    XCTAssertTrue(osVersionPseudoClass.matches(randomViewDetails, context: context))
    osVersionPseudoClass = pseudoClassWithTypeString("maxOSVersion", andParameter: previousVersion)
    XCTAssertFalse(osVersionPseudoClass.matches(randomViewDetails, context: context))
    osVersionPseudoClass = pseudoClassWithTypeString("maxOSVersion", andParameter:nextVersion)
    XCTAssertTrue(osVersionPseudoClass.matches(randomViewDetails, context: context))
  }
  
  func testPseudoClassScreenWidth() {
    let width = min(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    let narrower = "\(width - 1)"
    let wider = "\(width + 1)"
    
    let randomView = UIView()
    let randomViewDetails = randomView.interfaCSS
    let context = createStylingContext()
    
    var widthPseudoClass = pseudoClassWithTypeString("screenWidth", andParameter: "\(width)")
    XCTAssertTrue(widthPseudoClass.matches(randomViewDetails, context: context))
    widthPseudoClass = pseudoClassWithTypeString("screenWidth", andParameter: narrower)
    XCTAssertFalse(widthPseudoClass.matches(randomViewDetails, context: context))
    widthPseudoClass = pseudoClassWithTypeString("screenWidth", andParameter: wider)
    XCTAssertFalse(widthPseudoClass.matches(randomViewDetails, context: context))
    
    widthPseudoClass = pseudoClassWithTypeString("screenWidthLessThan", andParameter: wider)
    XCTAssertTrue(widthPseudoClass.matches(randomViewDetails, context: context))
    widthPseudoClass = pseudoClassWithTypeString("screenWidthLessThan", andParameter: narrower)
    XCTAssertFalse(widthPseudoClass.matches(randomViewDetails, context: context))
    
    widthPseudoClass = pseudoClassWithTypeString("screenWidthGreaterThan", andParameter: narrower)
    XCTAssertTrue(widthPseudoClass.matches(randomViewDetails, context: context))
    widthPseudoClass = pseudoClassWithTypeString("screenWidthGreaterThan", andParameter: wider)
    XCTAssertFalse(widthPseudoClass.matches(randomViewDetails, context: context))
  }
  
  func testPseudoClassScreenHeight() {
    let height = max(UIScreen.main.bounds.size.width, UIScreen.main.bounds.size.height)
    let shorter = "\(height - 1)"
    let taller = "\(height + 1)"
    
    let randomView = UIView()
    let randomViewDetails = randomView.interfaCSS
    let context = createStylingContext()
    
    var widthPseudoClass = pseudoClassWithTypeString("screenHeight", andParameter: "\(height)")
    XCTAssertTrue(widthPseudoClass.matches(randomViewDetails, context: context))
    widthPseudoClass = pseudoClassWithTypeString("screenHeight", andParameter: shorter)
    XCTAssertFalse(widthPseudoClass.matches(randomViewDetails, context: context))
    widthPseudoClass = pseudoClassWithTypeString("screenHeight", andParameter: taller)
    XCTAssertFalse(widthPseudoClass.matches(randomViewDetails, context: context))
    
    widthPseudoClass = pseudoClassWithTypeString("screenHeightLessThan", andParameter: taller)
    XCTAssertTrue(widthPseudoClass.matches(randomViewDetails, context: context))
    widthPseudoClass = pseudoClassWithTypeString("screenHeightLessThan", andParameter: shorter)
    XCTAssertFalse(widthPseudoClass.matches(randomViewDetails, context: context))
    
    widthPseudoClass = pseudoClassWithTypeString("screenHeightGreaterThan", andParameter: shorter)
    XCTAssertTrue(widthPseudoClass.matches(randomViewDetails, context: context))
    widthPseudoClass = pseudoClassWithTypeString("screenHeightGreaterThan", andParameter: taller)
    XCTAssertFalse(widthPseudoClass.matches(randomViewDetails, context: context))
  }
  
  func testWildcardSelectorFirst() {
    let wildcardSelector = createSelector(withType: "*")
    let childSelector = createSelector(withType: "UILabel", styleClass:"childClass")
    let chain = SelectorChain(components: [.selector(wildcardSelector), .combinator(.descendant), .selector(childSelector)])!
    
    let labelStyle = setup(UILabel(), withClass: "childClass", andAddTo: rootView).interfaCSS
    
    XCTAssertTrue(chain.matches(labelStyle, context:createStylingContext()), "Wildcard selector chain must match!")
  }
  
  func testWildcardSelectorMiddle() {
    let wildcardSelector = createSelector(withType: "*")
    let parentSelector = createSelector(withType: "uiwindow")
    let childSelector = createSelector(withType: "UILabel", styleClass:"childClass")
    let chain = SelectorChain(components: [.selector(parentSelector), .combinator(.descendant), .selector(wildcardSelector), .combinator(.descendant), .selector(childSelector)])!
    
    let labelStyle = setup(UILabel(), andAddTo: rootView).interfaCSS
    
    XCTAssertTrue(chain.matches(labelStyle, context:createStylingContext()), "Wildcard selector chain must match!")
  }
  
  func testWildcardSelectorLast() {
    let wildcardSelector = createSelector(withType: "*")
    let parentSelector = createSelector(withType: "uiview")
    let chain = SelectorChain(components: [.selector(parentSelector), .combinator(.descendant), .selector(wildcardSelector)])!
    
    let labelStyle = setup(UILabel(), andAddTo: rootView).interfaCSS
    
    XCTAssertTrue(chain.matches(labelStyle, context:createStylingContext()), "Wildcard selector chain must match!")
  }
  
  func testWildcardSelectorFirstAndLast() {
    let wildcardSelector = createSelector(withType: "*")
    let parentSelector = createSelector(withType: "uiview")
    let chain = SelectorChain(components: [.selector(wildcardSelector), .combinator(.descendant), .selector(parentSelector), .combinator(.descendant), .selector(wildcardSelector)])!
    
    let labelStyle = setup(UILabel(), andAddTo: rootView).interfaCSS
    
    XCTAssertTrue(chain.matches(labelStyle, context:createStylingContext()), "Wildcard selector chain must match!")
  }
  
  func testUsingNonUIKitClassAsType() {
    let customClassTypeSelector = createSelector(withType: "MyCustomView")
    let customClassTypeSelectorChain = SelectorChain(selector: customClassTypeSelector)
    
    // Verify that custom type selector matches custom class
    let myCustomView = MyCustomView()
    var elementStyle = myCustomView.interfaCSS
    
    XCTAssertTrue(customClassTypeSelectorChain.matches(elementStyle, context:createStylingContext()), "Custom type selector chain must match custom class!")
    
    // Verify that custom type selector does NOT match UIView
    let randomView = UIView()
    elementStyle = randomView.interfaCSS
    
    XCTAssertFalse(customClassTypeSelectorChain.matches(elementStyle, context:createStylingContext()), "Custom type selector chain must NOT match standard UIView!")
    
    // Verify that custom type selector does NOT match other custom class
    let myCustomView2 = MyCustomView2()
    elementStyle = myCustomView2.interfaCSS
    
    XCTAssertFalse(customClassTypeSelectorChain.matches(elementStyle, context:createStylingContext()), "Custom type selector chain must NOT match other custom class!")
    
    // Verify that custom type selector does match other custom class that is subclass of first class
    let myCustomViewSubClass = MyCustomViewSubClass()
    elementStyle = myCustomViewSubClass.interfaCSS
    
    XCTAssertTrue(customClassTypeSelectorChain.matches(elementStyle, context:createStylingContext()), "Custom type selector chain must match other custom class that is sub class of type in custom type selector!")
  }
  
  func testViewControllerAsTypeSelector() {
    let vc = SomeViewController()
    
    // Test selector "UIViewController UIView"
    let viewControllerSelector = createSelector(withType: "UIViewController")
    let viewSelector = createSelector(withType: "UIView")
    let viewSelectorChain = SelectorChain(components: [.selector(viewControllerSelector), .combinator(.descendant), .selector(viewSelector)])!
    
    let viewProxy = vc.view.interfaCSS
    let vcProxy = vc.interfaCSS
    
    XCTAssertTrue(viewSelectorChain.matches(viewProxy, context:createStylingContext()))
    
    // Test selector "SomeViewController UIView"
    styler.propertyManager.registerCanonicalTypeClass(SomeViewController.self) // Register SomeViewController as a valid type selector class
    
    viewProxy.reset(with: styler)
    vcProxy.reset(with: styler)
    
    let someViewControllerSelector = createSelector(withType: "SomeViewController")
    let someViewControllerSelectorChain = SelectorChain(components: [.selector(someViewControllerSelector), .combinator(.descendant), .selector(viewSelector)])!
    
    // Check that the view controller matches the selector chain with the newly registered type class:
    XCTAssertTrue(someViewControllerSelectorChain.matches(viewProxy, context:createStylingContext()))
    // Make sure that the "UIViewController" type selector no longer matches "SomeViewController"
    XCTAssertFalse(viewSelectorChain.matches(viewProxy, context:createStylingContext()))
    
    // Test selector "UIView SomeViewController UIView"
    let someViewControllerSelectorChain2 = SelectorChain(components: [.selector(viewSelector), .combinator(.descendant), .selector(someViewControllerSelector), .combinator(.descendant), .selector(viewSelector)])!
    
    // Selector chain shouldn't match view controller with no super view:
    XCTAssertFalse(someViewControllerSelectorChain2.matches(viewProxy, context:createStylingContext()))
    
    let superView = UIView()
    superView.addSubview(vc.view)
    
    // When added to super view, selector chanin should match:
    XCTAssertTrue(someViewControllerSelectorChain2.matches(viewProxy, context:createStylingContext()))
  }
  
  func testSelectorChainPartialMatch() {
    let label = UILabel()
    
    let viewSelector = createSelector(withType: "UIView")
    let labelSelector = createSelector(withType: "UILabel")
    let selectorChain = SelectorChain(components: [.selector(viewSelector), .combinator(.descendant), .selector(labelSelector)])!
    
    let context = createStylingContext()
    let result = selectorChain.matches(label.interfaCSS, context: context)
    
    XCTAssertEqual(result, false);
    XCTAssertEqual(context.containsPartiallyMatchedDeclarations, true)
  }
  
  func testRulesetPartialMatch() {
    let label = UILabel()
    
    let viewSelector = createSelector(withType: "UIView")
    let labelSelector = createSelector(withType: "UILabel")
    let disabledPseudo = pseudoClassWithTypeString("disabled")
    let disabledViewSelector = createSelector(withType: "UIView", pseudoClasses: [disabledPseudo])
    let selectorChain = SelectorChain(components: [.selector(viewSelector), .combinator(.descendant), .selector(disabledViewSelector), .combinator(.descendant), .selector(labelSelector)])!
    let ruleset = Ruleset(selectorChains: [selectorChain], andProperties: [])
    let context = createStylingContext()
    let result = ruleset.matches(label.interfaCSS, context: context)
    
    XCTAssertEqual(result, false);
    XCTAssertEqual(context.containsPartiallyMatchedDeclarations, true)
  }
}

class MyCustomView : UIView {}

class MyCustomViewSubClass : MyCustomView {}

class MyCustomView2 : UIView {}

class SomeViewController : UIViewController {}
