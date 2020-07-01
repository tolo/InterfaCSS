//
//  AbstractLayoutParserTests.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import XCTest
@testable import Layout

class AbstractLayoutParserTests: XCTestCase {
  
  var styler: StylingManager!
  
  override func setUp() {
    styler = StylingManager()
    super.setUp()
  }
  
  func loadLayoutFile(_ name: String) -> AbstractLayout? {
    guard let url = Bundle(for: type(of: self)).url(forResource: name, withExtension: "xml"), let data = try? Data(contentsOf: url) else {
      XCTFail("Cannot load file \(name)")
      return nil
    }
    
    let parser = AbstractViewTreeParser(data: data, styler: styler)
    let (layout, error) = parser.parse()
    
    if let error = error {
      XCTFail("Unexpected parse error: \(error)")
      return nil
    }
    
    return layout
  }
  
  
  func testSimpleView() {
    let layout = loadLayoutFile("simpleView")!
    
    var nodeInfo: [String] = []
    let _ = layout.rootNode.visitAbstractViewTree(visitor: { (node, parent, parentView) -> AnyObject? in
      var elementId = node.elementId ?? ""
      if elementId.hasData() { elementId = " id='\(elementId)'" }
      var style = (node.inlineStyle ?? []).map({ $0.description }).joined(separator: "; ")
      if style.hasData() { style = " style='\(style)'" }
      var src = node.attributes.src ?? ""
      if src.hasData() { src = " src='\(src)'" }
      nodeInfo.append("<\(node.attributes.elementName)\(elementId)\(style)\(src)>\(node.stringContent ?? "")</\(node.attributes.elementName)>")
      return nil
    })
    
    let expected: [String] = [
      "<view id='rootView' style='flexdirection: column'></view>",
      "<label id='label1' style='margintop: 42'>Hello</label>",
      "<button id='button1' style='paddingvertical: 10'>World</button>",
      "<image id='image1' src='image.png'></image>",
    ]
    
    XCTAssertEqual(expected, nodeInfo)
  }
}
