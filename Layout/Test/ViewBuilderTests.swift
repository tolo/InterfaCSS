//
//  ViewBuilderTests.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import XCTest
@testable import Layout

class ViewBuilderTests: XCTestCase {
  
  var viewBulder: ViewBuilder!
  
  override class func setUp() {
    super.setUp()
    Logger.traceLoggingEnabled = true
  }
  
  private func loadViewBuilder(_ name: String, viewBuilderClass: ViewBuilder.Type = ViewBuilder.defaultViewBuilderClass) -> UIView? {
    guard let url = Bundle(for: type(of: self)).url(forResource: name, withExtension: "xml") else {
      XCTFail("Cannot load file \(name)")
      return nil
    }
    
    viewBulder = viewBuilderClass.init(layoutFileURL: url)
    
    let expectation = XCTestExpectation(description: "View loaded")
    var error: Error?
    var rootView: UIView?
    _ = viewBulder.buildView { (_rootView, _, _, _error) in
      rootView = _rootView
      error = _error
      expectation.fulfill()
    }
    
    wait(for: [expectation], timeout: 1)
    
    if let error = error {
      XCTFail("Unexpected parse error: \(error)")
      return nil
    }
    
    return rootView
  }
  
  private func loadViewInContainer(_ name: String, viewBuilderClass: ViewBuilder.Type = ViewBuilder.defaultViewBuilderClass) -> UIView? {
    guard let view = loadViewBuilder(name) else {
      return nil
    }
    
    let container = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 300))
    view.frame = container.bounds
    container.addSubview(view)
    
    viewBulder.applyLayout(onView: view)
    
    return view
  }
  
  func testSimpleViewStructure() {
    guard let view = loadViewBuilder("simpleView") else {
      XCTFail()
      return
    }
    
    XCTAssertEqual(view.interfaCSS.elementId, "rootView")
    let subviews = view.subviews
    XCTAssertEqual(subviews.count, 5)
    
    var viewInfo: [String] = []
    for (i, s) in subviews.enumerated() {
      let elementId = s.interfaCSS.elementId ?? "\(i)"
      viewInfo.append("\(elementId) = \(type(of: s).description())")
    }
    
    let expected: [String] = ["label1 = UILabel", "button1 = UIButton", "image1 = UIImageView",
                                      "textInput1 = UITextField", "textArea1 = UITextView"]
    
    XCTAssertEqual(viewInfo.sorted(), expected.sorted())
  }
  
  func testSimpleViewLayoutColumn() {
    guard let view = loadViewInContainer("testLayoutColumn") else {
      XCTFail()
      return
    }
    
    let child1 = view.subviews.first
    let child2 = view.subviews.last
    
    XCTAssertEqual(child1?.frame, CGRect(x: 0, y: 0, width: 200, height: 150))
    XCTAssertEqual(child1?.backgroundColor, CssColors.color(forName: "red"))
    XCTAssertEqual(child2?.frame, CGRect(x: 0, y: 150, width: 200, height: 150))
    XCTAssertEqual(child2?.backgroundColor, CssColors.color(forName: "green"))
  }
  
  func testSimpleViewLayoutRow() {
    guard let view = loadViewInContainer("testLayoutRow") else {
      XCTFail()
      return
    }
    
    let child1 = view.subviews.first
    let child2 = view.subviews.last
    
    XCTAssertEqual(child1?.frame, CGRect(x: 0, y: 0, width: 100, height: 300))
    XCTAssertEqual(child1?.backgroundColor, CssColors.color(forName: "blue"))
    XCTAssertEqual(child2?.frame, CGRect(x: 100, y: 0, width: 100, height: 300))
    XCTAssertEqual(child2?.backgroundColor, CssColors.color(forName: "yellow"))
  }
}
