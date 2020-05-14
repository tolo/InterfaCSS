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
  
  private func initializeWithStyleSheet(_ name: String) -> Styler {
    let styler = StylingManager()
    let path = Bundle(for: type(of: self)).url(forResource: name, withExtension: "css")!
    styler.loadStyleSheet(fromFileURL: path)
    return styler;
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
  
  // MARK: - Nested element properties
  
  func testNestedElements() {
    let styler = initializeWithStyleSheet("stylingTest-properties")
    
    let rootView = UIView()
    rootView.interfaCSS.addStyleClass("nextedProperties")
    styler.applyStyling(rootView)
    
    XCTAssertEqual(rootView.layer.cornerRadius, 5)
    XCTAssertEqual(rootView.layer.borderWidth, 10)
  }
}
