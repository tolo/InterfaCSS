//
//  InterfaCSSTests.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import XCTest
@testable import Core


class InterfaCSSTests: XCTestCase {
  
  private func initializeWithStyleSheet(_ name: String) -> StylingManager {
    let styler = StylingManager()
    let path = Bundle(for: type(of: self)).url(forResource: name, withExtension: "css")!
    styler.loadStyleSheet(fromLocalFile: path)
    return styler;
  }
  
  private func loadStyleSheet(stylingManager: StylingManager, name: String, group: String? = nil) {
    let path = Bundle(for: type(of: self)).url(forResource: name, withExtension: "css")!
    stylingManager.loadStyleSheet(fromLocalFile: path, group: group)
  }
  
  private func format(_ value: CGFloat) -> String {
    return String(format: "%\(0.2)f", value)
  }
  
  private func setup<T: UIView>(_ view: T, withClass clazz: String = "childClass", andAddTo parentView: UIView? = nil) -> T {
    if let parentView = parentView {
      parentView.addSubview(view)
    }
    view.interfaCSS.addStyleClass(clazz);
    return view
  }
  
  
  // MARK: - Test Caching properties
  
  func testCaching() {
    let styler = initializeWithStyleSheet("stylingTest-caching")
    let rootView = UIView()
    rootView.interfaCSS.addStyleClass("class1")
    
    let label = UILabel()
    rootView.addSubview(label)
    
    label.isEnabled = true
    styler.applyStyling(label)
    
    XCTAssertEqual(format(label.alpha), "0.25")
    
    label.isEnabled = false
    styler.applyStyling(label) // Styling should not be cached
    
    XCTAssertEqual(format(label.alpha), "0.75", "Expected change in property value after state change")
  }
  
  func testCachingWhenParentObjectStateAffectsSelectorMatching() {
    let styler = initializeWithStyleSheet("stylingTest-caching")
    let rootView = UIView()
    rootView.interfaCSS.addStyleClass("class1")
    
    let control = UIControl()
    rootView.addSubview(control)
    
    let label = UILabel()
    control.addSubview(label)
    
    control.isEnabled = true
    styler.applyStyling(label)
    
    XCTAssertEqual(format(label.alpha), "0.33")
    
    control.isEnabled = false
    styler.applyStyling(label) // Styling should not be cached
    
    XCTAssertEqual(format(label.alpha), "0.66", "Expected change in property value after state change")
  }
  
  
  // MARK: - Test common UIView properties
  
  func testUIViewProperties() {
    let styler = initializeWithStyleSheet("stylingTest-properties")
    
    let rootView = UIView()
    rootView.interfaCSS.addStyleClass("uiViewTest")
    
    let label = setup(UILabel(), withClass: "uiViewTest", andAddTo: rootView)
    styler.applyStyling(rootView)
    
    XCTAssertEqual(rootView.autoresizingMask, [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight])
    XCTAssertEqual(rootView.backgroundColor, UIColor.red)
    XCTAssertEqual(rootView.clipsToBounds, true)
    XCTAssertEqual(rootView.isHidden, true)
    XCTAssertEqual(rootView.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
    XCTAssertEqual(rootView.tag, 5)
    XCTAssertEqual(rootView.tintColor, UIColor.blue)
    
    // Test "inheritance" of properties from UIView
    XCTAssertEqual(label.autoresizingMask, [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight])
    XCTAssertEqual(label.backgroundColor, UIColor.red)
    XCTAssertEqual(label.clipsToBounds, true)
    XCTAssertEqual(label.isHidden, true)
    XCTAssertEqual(label.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
    XCTAssertEqual(label.tag, 5)
    XCTAssertEqual(label.tintColor, UIColor.blue)
  }
  
  func testButton() {
    let styler = initializeWithStyleSheet("stylingTest-properties")
    
    let button = UIButton()
    button.interfaCSS.addStyleClass("buttonTest")
    styler.applyStyling(button)
    
    XCTAssertEqual(button.title(for: .normal), "1")
    XCTAssertEqual(button.title(for: .selected), "2")
    XCTAssertEqual(button.title(for: .highlighted), "3")
    XCTAssertEqual(button.title(for: [.selected, .highlighted]), "4")
    
    XCTAssertEqual(button.titleColor(for: .normal), .red)
    XCTAssertEqual(button.titleColor(for: .selected), .green)
    XCTAssertEqual(button.titleColor(for: .highlighted), .blue)
    XCTAssertEqual(button.titleColor(for: [.selected, .highlighted]), UIColor.init(fromHexString: "ff00ff"))
  }
  
  
  // MARK: - Nested element properties
  
  func testNestedElements() {
    let styler = initializeWithStyleSheet("stylingTest-properties")
    
    let rootView = UIView()
    rootView.interfaCSS.addStyleClass("nestedProperties")
    styler.applyStyling(rootView)
    
    XCTAssertEqual(rootView.layer.cornerRadius, 5)
    XCTAssertEqual(rootView.layer.borderWidth, 10)
  }
    
  
  // MARK: - Various CSS functionality
  
  func testNotPseudoClass() {
    let styler = initializeWithStyleSheet("stylingTest-properties")
    
    let rootView = UIView()
    rootView.interfaCSS.styleClass = "not-pseudo-test"
    
    let label1 = UILabel()
    label1.interfaCSS.styleClass = "label"
    label1.interfaCSS.elementId = "label1"
    rootView.addSubview(label1)
    let label2 = UILabel()
    label2.interfaCSS.styleClass = "label"
    label2.interfaCSS.elementId = "label2"
    rootView.addSubview(label2)
    let label3 = UILabel()
    label3.interfaCSS.styleClasses = ["label", "other-label"]
    label3.interfaCSS.elementId = "label3"
    rootView.addSubview(label3)
    
    rootView.interfaCSS.applyStyling(with: styler)
    
    XCTAssertEqual(label1.tag, 42)
    XCTAssertEqual(label2.tag, 10)
    XCTAssertEqual(label3.tag, 20)
  }
  
  func testExtendedDeclaration() {
    let styler = initializeWithStyleSheet("stylingTest-properties")
    
    let rootView = UIView()
    rootView.interfaCSS.styleClass = "extension-test"
    
    let label1 = UILabel()
    label1.interfaCSS.styleClass = "label"
    rootView.addSubview(label1)
    let label2 = UILabel()
    label2.interfaCSS.styleClass = "another-label"
    rootView.addSubview(label2)
    
    rootView.interfaCSS.applyStyling(with: styler)
    
    XCTAssertEqual(label1.tag, 42)
    XCTAssertEqual(label1.text, "test")
    XCTAssertEqual(label1.alpha, 0.5)
    
    XCTAssertEqual(label2.tag, 4711)
    XCTAssertEqual(label2.text, "test")
    XCTAssertEqual(label2.alpha, 0.5)
  }
  
  func testInitial() {
    let styler = initializeWithStyleSheet("stylingTest-properties")
    
    let rootView = UIView()
    rootView.interfaCSS.styleClass = "initial-test"
    
    let label1 = UILabel()
    label1.interfaCSS.styleClass = "label"
    rootView.addSubview(label1)
        
    label1.interfaCSS.applyStyling(with: styler)
    XCTAssertEqual(label1.tag, 42)
    
    label1.interfaCSS.elementId = "initial-value-label"
    label1.interfaCSS.applyStyling(with: styler, force: true)
    XCTAssertEqual(label1.tag, 42)
    
    label1.tag = 4711
    label1.interfaCSS.applyStyling(with: styler, force: true)
    XCTAssertEqual(label1.tag, 4711)

    label1.interfaCSS.elementId = nil
    label1.interfaCSS.applyStyling(with: styler, force: true)
    XCTAssertEqual(label1.tag, 42)
  }
  
  
  // MARK: - Stylesheet scopes
  
  func testScoping() {
    let stylingManager = initializeWithStyleSheet("scopeTest-base")
    
    let rootView = UIView()
    rootView.interfaCSS.addStyleClass("someClass")
    
    stylingManager.applyStyling(rootView)
    XCTAssertEqual(rootView.isHidden, true)
    XCTAssertEqual(rootView.tag, 5)
    
    loadStyleSheet(stylingManager: stylingManager, name: "scopeTest-scope", group: "group")
    let scopedStyler = stylingManager.styler(withScope: .using(group: "group"))
    
    rootView.isHidden = false
    scopedStyler.applyStyling(rootView, force: true)
    XCTAssertEqual(rootView.isHidden, true)
    XCTAssertEqual(rootView.tag, 10)
    
    let globalScopedStyler = stylingManager.styler(withScope: .global)
    
    rootView.isHidden = false
    globalScopedStyler.applyStyling(rootView, force: true)
    XCTAssertEqual(rootView.isHidden, true)
    XCTAssertEqual(rootView.tag, 5)
  }
  
  
  // MARK: - Compound properties
  
  func testCompoundFontProperty() {
    let styler = initializeWithStyleSheet("stylingTest-properties")
    
    let label = UILabel()
    label.text = "Test"
    label.adjustsFontForContentSizeCategory = true
    label.interfaCSS.addStyleClass("cssfont1")
    styler.applyStyling(label)
    
    XCTAssertEqual(label.font, UIFont.systemFont(ofSize: 42, weight: .bold))
    
    label.interfaCSS.addStyleClass("cssfont2")
    styler.applyStyling(label)
    XCTAssertEqual(label.font, UIFont.systemFont(ofSize: 42, weight: .heavy))
    
    //UITraitCollection(preferredContentSizeCategory: .extraExtraLarge).performAsCurrent {
      label.interfaCSS.addStyleClass("cssfont3")
      styler.applyStyling(label)
    // TODO: This may have to be tested manually
      XCTAssertEqual(label.font.pointSize, UIFont.systemFont(ofSize: 42, weight: .heavy).scaledFont(for: .largeTitle).pointSize)
    //}
  }
  

  // MARK: - Misc
    
  func testElementStyleIdentityPath() {
    let root = UIView()
    root.interfaCSS.styleClass = "root"
    let level1 = UIView()
    level1.interfaCSS.styleClass = "level1"
    let level2 = UIView()
    level2.interfaCSS.styleClass = "level2"
    let level3 = UIView()
    level3.interfaCSS.styleClass = "level3"
    
    root.addSubview(level1)
    level1.addSubview(level2)
    level2.addSubview(level3)
    
    StylingManager.shared.applyStyling(root) // Apply style to make sure ElementStyle objects are initialized
    XCTAssertEqual(level3.interfaCSS.elementStyleIdentityPath, "UIView[root] UIView[level1] UIView[level2] UIView[level3]")
    
    level1.interfaCSS.elementId = "level1"
    StylingManager.shared.applyStyling(root) // Apply style to make sure ElementStyle objects are initialized
    XCTAssertEqual(level3.interfaCSS.elementStyleIdentityPath, "#level1[level1] UIView[level2] UIView[level3]")
    
    level2.interfaCSS.isRootElement = true
    StylingManager.shared.applyStyling(root) // Apply style to make sure ElementStyle objects are initialized
    XCTAssertEqual(level3.interfaCSS.elementStyleIdentityPath, "UIView[level2] UIView[level3]")
  }
}
