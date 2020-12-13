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
  
  func loadLayout(_ name: String) -> AbstractLayout? {
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
    let layout = loadLayout("simpleView")!
    
    var nodeInfo: [String] = []
    let _ = layout.rootNode.visitAbstractViewTree(visitor: { (node, parent, parentView) -> AnyObject? in
      let elementName = node.elementType.description.lowercased() // Testing that element type has been correctly interpreted
      var elementId = node.elementId ?? ""
      if elementId.hasData() { elementId = " id='\(elementId)'" }
      var style = (node.inlineStyle ?? []).map({ $0.description }).joined(separator: "; ")
      if style.hasData() { style = " style='\(style)'" }
      var src = node.attributes.src ?? ""
      if src.hasData() { src = " src='\(src)'" }
      nodeInfo.append("<\(elementName)\(elementId)\(style)\(src)>\(node.stringContent ?? "")</\(elementName)>")
      return nil
    })
    
    let expected: [String] = [
      "<view id='rootView' style='flexdirection: column; backgroundcolor: red'></view>",
      "<text id='label1' style='margintop: 42'>Hello</text>",
      "<button id='button1' style='paddingvertical: 10'>World</button>",
      "<image id='image1' src='image.png'></image>",
      "<textinput id='textInput1'>TextInput</textinput>",
      "<textarea id='textArea1'>TextArea</textarea>",
    ]
    
    var i = 0
    expected.forEach {
      XCTAssertEqual($0, nodeInfo[i])
      i += 1
    }
  }
  
  func testNestedViews() {
    let layout = loadLayout("nestedViews")!
    
    var nodeInfo: [String] = []
    let _ = layout.rootNode.visitAbstractViewTree(visitor: { (node, parent, parentView) -> AnyObject? in
      let elementName = node.elementType.description.lowercased() // Testing that element type has been correctly interpreted
      var elementId = node.elementId ?? ""
      if elementId.hasData() { elementId = " id='\(elementId)'" }
      var parentElementId = parent?.elementId ?? ""
      if parentElementId.hasData() { parentElementId = " pid='\(parentElementId)'" }
      nodeInfo.append("<\(elementName)\(elementId)\(parentElementId)>\(node.stringContent ?? "")</\(elementName)>")
      return nil
    })
    
    let expected: [String] = [
      "<view id='rootView'></view>",
      "<view id='view1' pid='rootView'></view>",
      "<text id='label1' pid='view1'>Hello</text>",
      "<view id='view2' pid='view1'></view>",
      "<text id='label2' pid='view2'>Hello</text>",
      "<view id='view3' pid='rootView'></view>",
      "<text id='label3' pid='view3'>Hello</text>",
      "<view id='view4' pid='view3'></view>",
      "<text id='label4' pid='view4'>Hello</text>",
    ]
    
    var i = 0
    expected.forEach {
      XCTAssertEqual($0, nodeInfo[i])
      i += 1
    }
  }
}
