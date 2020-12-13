//
//  StyleSheetParserTests.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import XCTest
@testable import Core

private let S = StyleSheetParserSyntax.shared


class StyleSheetParserTests: XCTestCase {
  var styler: StylingManager!
  var styleSheetManager: StyleSheetManager!
  var parser: StyleSheetParser!
  
  override func setUp() {
    parser = StyleSheetParser()
    styleSheetManager = StyleSheetManager(styleSheetParser: parser)
    parser.styleSheetManager = styleSheetManager
    styler = StylingManager(styleSheetManager: styleSheetManager)
    
    ImagePropertyParser.imageNamed = Self.imageNamed
  }
  
  override func tearDown() {
  }
    
  private static func imageNamed(_ name: String) -> UIImage? {
    guard let path = Bundle(for: self).path(forResource: name, ofType: nil) else { return nil }
    return UIImage(contentsOfFile: path)
  }
  
  func parse<T>(propertyValue: String, as propertyType: PropertyType) -> T? {
    return parse(propertyValue: PropertyValue(propertyName: "", value: propertyValue), as: propertyType)
  }
  
  func parse<T>(propertyValue: PropertyValue, as propertyType: PropertyType) -> T? {
    return parseAny(propertyValue: propertyValue, as: propertyType) as? T
  }
  
  func parseAny(propertyValue: PropertyValue, as propertyType: PropertyType) -> Any? {
    let stringValue = styleSheetManager.replaceVariableReferences(propertyValue.rawValue ?? "")
    return propertyType.parseAny(propertyValue: propertyValue.copyWith(value: stringValue))
  }
  
  func colorOfFirstPixel(_ image: UIImage?) -> UIColor? {
    guard let image = image, let cgImage = image.cgImage, let provider = cgImage.dataProvider, let pixelData = provider.data else { return nil }
    let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
    
    let pos = CGPoint(x: 0, y: 0)
    let numberOfComponents = 4
    let pixelInfo = ((Int(image.size.width) * Int(pos.y)) + Int(pos.x)) * numberOfComponents
    
    let r = CGFloat(Double(data[pixelInfo]) / 255.0)
    let g = CGFloat(Double(data[pixelInfo+1]) / 255.0)
    let b = CGFloat(Double(data[pixelInfo+2]) / 255.0)
    let a = CGFloat(Double(data[pixelInfo+3]) / 255.0)
    
    return UIColor(red: r, green: g, blue: b, alpha: a)
  }
  
  func compareRGBA(color1: UIColor, color2: UIColor) -> Bool {
    let rgba1 = color1.rgba()
    let rgba2 = color2.rgba()
    for i in 0..<4 {
      guard rgba1[i] == rgba2[i] || rgba1[i] == (rgba2[i]-1) || rgba1[i] == (rgba2[i]+1) else { return false }
    }
    return true
  }
  
  func parseStyleSheet(_ name: String) -> StyleSheetContent? {
    guard let url = Bundle(for: type(of: self)).url(forResource: name, withExtension: "css") else {
      return nil
    }
    return styleSheetManager.loadStyleSheet(fromLocalFile: url)?.content
  }
  
  func loadRulesets(withStyleClass className: String, in styleSheet: String = "propertyValues") -> [Ruleset] {
    guard let content = parseStyleSheet(styleSheet) else {
      XCTFail()
      return []
    }
    
    return content.rulesets.filter { $0.chainsDescription.contains(".\(className)") }
  }
  
  func loadProperties(withStyleClass className: String, in styleSheet: String = "propertyValues") -> [PropertyValue] {
    let matchingRulesets = loadRulesets(withStyleClass: className, in: styleSheet)
    return matchingRulesets.flatMap { $0.properties }
  }
  
  func parsePropertiesToDict<T>(withStyleClass className: String, in styleSheet: String = "propertyValues", propertyType: PropertyType) -> [String: T] {
    let properties = loadProperties(withStyleClass: className, in: styleSheet)
    var result = [String: T]()
    properties.forEach {
      if let prop: T = parse(propertyValue: $0, as: propertyType) {
        result[$0.propertyName] = prop
      }
    }
    return result
  }
  
  func parseProperties(withStyleClass className: String, in styleSheet: String = "propertyValues", propertyType: PropertyType) -> [String] {
    let properties = loadProperties(withStyleClass: className, in: styleSheet)
    return properties.compactMap {
      if let value = parseAny(propertyValue: $0, as: propertyType) {
        return "\($0.propertyName): \(describing: value)"
      } else {
        return "\($0.propertyName): null"
      }
    }
  }
  
  
  // MARK: - Tests for parsers of individual parts of the CSS format
  
  func testParameterString() {
    let p = S.parameterString(withPrefix: "moo")
    let r1 = p.parse("moo(mu, mupp)")
    XCTAssertTrue(r1.match)
    XCTAssertEqual(r1.value, ["mu", "mupp"])
  }
  
  func testNumericParameterString() {
    let p = S.numericParameterString(withPrefix: "fun")
    let r1 = p.parse("fun(1, 2)")
    XCTAssertTrue(r1.match)
    XCTAssertEqual(r1.value, [CGFloat(1), CGFloat(2)])
  }
  
  func testVariableParser() {
    var parsingContext = StyleSheetParsingContext()
    let r1 = parser.variableParser.parse("@variable: 0.666;", userInfo: parsingContext)
    XCTAssertTrue(r1.match)
    XCTAssertEqual(r1.residual, "")
    XCTAssertEqual(parsingContext.variables["variable"], "0.666")
    parsingContext = StyleSheetParsingContext()
    let r2 = parser.cssParser.parse("/* Variables: */\n@variable1: 0.666;\n@variable2: 42;", userInfo: parsingContext)
    XCTAssertTrue(r2.match)
    XCTAssertEqual(parsingContext.variables["variable1"], "0.666")
    XCTAssertEqual(parsingContext.variables["variable2"], "42")
  }
  
  func testCommentParser() {
    var r = S.comment.parse("/* Comment: */\n@variable1: 0.666;")
    XCTAssertTrue(r.match)
    XCTAssertEqual(r.value, "Comment:")
    XCTAssertEqual(r.residual, "\n@variable1: 0.666;")
    r = S.comment.parse("/* Comment \n on \n multiple lines: */\n@variable1: 0.666;")
    XCTAssertTrue(r.match)
    XCTAssertEqual(r.value, "Comment \n on \n multiple lines:")
    XCTAssertEqual(r.residual, "\n@variable1: 0.666;")
  }
  
  func testPropertyPairParser() {
    let s = StyleSheetParserSyntax()
    let p = s.propertyPairParser(forVariable: false, standalone: true)
    var r = p.parse("name=value;")
    XCTAssertTrue(r.match)
    XCTAssertEqual(r.value?.first, "name")
    XCTAssertEqual(r.value?.last, "value")
    r = p.parse("name = \"value\";")
    XCTAssertEqual(r.value?.first, "name")
    XCTAssertEqual(r.value?.last, "\"value\"")
  }
  
  func testParsePropertyPairs() {
    let values = parser.parsePropertyNameValuePairs("flex-direction: column; background-color: red")
    XCTAssertEqual(values?.count, 2)
    XCTAssertEqual(values?.first?.propertyName, "flexdirection")
    XCTAssertEqual(values?.first?.rawValue, "column")
    XCTAssertEqual(values?.last?.propertyName, "backgroundcolor")
    XCTAssertEqual(values?.last?.rawValue, "red")
  }
  
  func testSelectorsChainsParser() {
    let p = parser.selectorsChainsParser!
    let selectors = ["type", "type.class", "type:phone", ".class", ".class:phone", "uiview .class1", "uiview:minosversion(8.4)"]
    for s in selectors {
      let r = p.parse(s)
      XCTAssertTrue(r.match)
      XCTAssertEqual(r.value?.chainsDescription, s)
    }
  }
  
  func testStringParser() {
    let r1: String? = parse(propertyValue: "42", as: .string)
    XCTAssertEqual(r1 ?? "", "42")
    let r2: String? = parse(propertyValue: "\"dr \\\"evil\\\" rules\"", as: .string)
    XCTAssertEqual(r2 ?? "", "dr \"evil\" rules")
  }
  
  func testNumberParser() {
    var r: Int? = parse(propertyValue: "42", as: .number)
    XCTAssertEqual(r ?? 0, 42)
    
    r = parse(propertyValue: "22 + 20", as: .number)
    XCTAssertEqual(r ?? 0, 42)
  }
  
  func testPointParser() {
    let r: CGPoint? = parse(propertyValue: "point(50, 50)", as: .point)
    XCTAssertEqual(r ?? CGPoint.zero, CGPoint(x: 50, y: 50))
  }
  
  func testColorParser() {
    let r: UIColor? = parse(propertyValue: "lighten(rgb(17, 34, 51), 50%)", as: .color)
    XCTAssertEqual(r ?? UIColor.magenta, UIColor(fromHexString: "112233")!.adjustBrightness(by: 50))
  }
  
  
  // MARK: - Structure and parsing tests
  
  func testStylesheetStructure() {
    guard let content = parseStyleSheet("styleSheetStructure") else {
      XCTFail()
      return
    }
    
    let usesVariable = Set(["uilabel"])
    var expectedChains = Set(["uilabel", "uilabel.class1", "uilabel#identity.class1", "uilabel#identity.class1.class2", "#identity.class1", ".class1", ".class1.class2",
                              "uiview .class1 .class2", "uiview .class1.class2",
                              "uiview > .class1 + .class2 ~ .class3",
                              "uilabel, uilabel.class1, .class1, uiview .class1 .class2",
                              "uilabel, uilabel.class1.class2, .class1, uiview .class1.class2 .class3",
                              "uiview", "uiview .classn1", "uiview .classn1 .classn2",
                              "uiview:onlychild", "uiview:minosversion(8.4)", "uiview#identifier.class1:onlychild", "uiview:nthchild(2n+1)", "uiview uilabel:firstoftype", "uiview.classx", "uiview.classx uilabel:lastoftype", "uiview:pad:landscape", "uiview:portrait:phone",
                              "* uiview", "* uiview *", "uiview *", "uiview * uiview"])
    
    for ruleset in content.rulesets {
      let chainsDescription = ruleset.chainsDescription.lowercased()
      expectedChains.remove(chainsDescription)
      
      if usesVariable.contains(chainsDescription) {
        XCTAssertEqual(ruleset.propertiesDescription, "alpha: @variable", "Unexpected property value for '\(chainsDescription)'")
      } else {
        XCTAssertEqual(ruleset.propertiesDescription, "alpha: 0.666", "Unexpected property value for '\(chainsDescription)'")
      }
    }
    
    XCTAssertEqual(expectedChains, Set())
  }
  
  func testNumbers() {
    let properties = parseProperties(withStyleClass: "numbers", in: "propertyValues", propertyType: .number)
    let expected = ["numberone: 0.33", "numbertwo: 5", "expression1: 100", "expression2: 0.5", "expression3: 142"]
    XCTAssertEqual(Set(properties), Set(expected))
  }
  
  func testBooleans() {
    let properties = parseProperties(withStyleClass: "booleans", in: "propertyValues", propertyType: .bool)
    let expected = ["bool1: true", "bool2: true", "bool3: true", "bool4: true",
                    "bool5: false", "bool6: false", "bool7: false", "bool8: false", "bool9: true"]
    XCTAssertEqual(Set(properties), Set(expected))
  }
  
  func testPoints() {
    let properties = parseProperties(withStyleClass: "points", in: "propertyValues", propertyType: .point)
    let expextedValue = CGPoint(x: 50.0, y: 50.0)
    let expected = ["point1: \(expextedValue)", "point2: \(expextedValue)"]
    XCTAssertEqual(Set(properties), Set(expected))
  }
  
  func testRects() {
    let properties = parseProperties(withStyleClass: "rects", in: "propertyValues", propertyType: .rect)
    let expextedValue = CGRect(x: 1.0, y: 2.0, width: 3.0, height: 4.0)
    let expected = ["rect1: \(expextedValue)", "rect2: \(expextedValue)", "rect3: \(expextedValue)"]
    XCTAssertEqual(Set(properties), Set(expected))
  }
  
  func testSizes() {
    let properties = parseProperties(withStyleClass: "sizes", in: "propertyValues", propertyType: .size)
    let expextedValue = CGSize(width: 50.0, height: 50.0)
    let expextedExpressionValue = CGSize(width: 42, height: 100)
    let expected = ["size1: \(expextedValue)", "size2: \(expextedValue)", "size3: \(expextedExpressionValue)"]
    XCTAssertEqual(Set(properties), Set(expected))
  }
  
  func testOffsets() {
    let properties = parseProperties(withStyleClass: "offsets", in: "propertyValues", propertyType: .offset)
    let expextedValue = UIOffset(horizontal: 50.0, vertical: 50.0)
    let expected = ["offset1: \(expextedValue)", "offset2: \(expextedValue)"]
    XCTAssertEqual(Set(properties), Set(expected))
  }
  
  func testInsets() {
    let properties = parseProperties(withStyleClass: "insets", in: "propertyValues", propertyType: .edgeInsets)
    let expextedValue = UIEdgeInsets(top: 1.0, left: 2.0, bottom: 3.0, right: 4.0)
    let expected = ["inset1: \(expextedValue)", "inset2: \(expextedValue)"]
    XCTAssertEqual(Set(properties), Set(expected))
  }
  
  func testStrings() {
    let properties: [String: String] = parsePropertiesToDict(withStyleClass: "strings", in: "propertyValues", propertyType: .string)
    XCTAssertEqual(properties["string1"], "Text's:")
    XCTAssertEqual(properties["string2"], "Prompt")
    XCTAssertEqual(properties["string3"], "Title")
    XCTAssertEqual(properties["string4"], "dr \"evil\" rules")
    XCTAssertEqual(properties["string5"], "Text")
    XCTAssertEqual(properties["string6"], "Title")
  }
  
  func testColors() {
    let properties: [String: UIColor] = parsePropertiesToDict(withStyleClass: "colors", in: "propertyValues", propertyType: .color)
    XCTAssertEqual(properties["color1"], UIColor(r: 128, g: 128, b: 128))
    XCTAssertEqual(properties["color2"], UIColor(r: 64, g: 64, b: 64, a: 0.5))
    XCTAssertEqual(properties["color3"], UIColor.blue)
    XCTAssertEqual(properties["color4"], UIColor(r: 127, g: 127, b: 127))
    XCTAssertEqual(properties["color5"], UIColor(r: 64, g: 128, b: 176, a: 0))
    XCTAssertEqual(properties["color6"], UIColor(r: 128, g: 0, b: 0, a: 128 / 255.0))
    XCTAssertEqual(properties["color7"], UIColor(r: 136, g: 136, b: 136, a: 8 / 15.0))
    XCTAssertEqual(properties["color8"], UIColor(r: 136, g: 136, b: 136))
  }
  
  func testColorFunctions() {
    let properties: [String: UIColor] = parsePropertiesToDict(withStyleClass: "colorFunctions", in: "propertyValues", propertyType: .color)
    let sourceColor = UIColor(fromHexString: "112233")!
    XCTAssertEqual(properties["color1"], sourceColor.adjustBrightness(by: 50))
    XCTAssertEqual(properties["color2"], sourceColor.adjustBrightness(by: -50))
    XCTAssertEqual(properties["color3"], sourceColor.adjustSaturation(by: 50))
    XCTAssertEqual(properties["color4"], sourceColor.adjustSaturation(by: -50))
    XCTAssertEqual(properties["color5"], sourceColor.adjustAlpha(by: 50))
    XCTAssertEqual(properties["color6"], sourceColor.adjustAlpha(by: -50))
    XCTAssertEqual(properties["color7"], sourceColor.adjustAlpha(by: -50).adjustSaturation(by: 50))
    XCTAssertEqual(properties["color8"], sourceColor.adjustAlpha(by: -50).adjustSaturation(by: 50))
  }
  
  func testFonts() {
    let properties: [String: UIFont] = parsePropertiesToDict(withStyleClass: "fonts", in: "propertyValues", propertyType: .font)
    
    XCTAssertEqual(properties["font1"], UIFont(name: "HelveticaNeue-Medium", size: 15))
    XCTAssertEqual(properties["font2"], UIFont.systemFont(ofSize: 5, weight: .bold))
    XCTAssertEqual(properties["font3"], UIFont.systemFont(ofSize: 5, weight: .bold).scaledFont(for: .body))
    XCTAssertEqual(properties["font4"], UIFont.systemFont(ofSize: 5).scaledFont(for: .body, maxSize: 10))
    XCTAssertEqual(properties["font5"], UIFont(name: "HelveticaNeue-Medium", size: 5))
    XCTAssertEqual(properties["font6"], UIFont(name: "Courier", size: 5))
    XCTAssertEqual(properties["font7"], UIFont(name: "Avenir", size: 5))
    XCTAssertEqual(properties["font8"], UIFont.systemFont(ofSize: 42))
    XCTAssertEqual(properties["font9"], UIFont.systemFont(ofSize: 42))
    XCTAssertEqual(properties["font10"], UIFont.italicSystemFont(ofSize: 42))
    XCTAssertEqual(properties["font11"], UIFont.systemFont(ofSize: 42, weight: .bold))
    XCTAssertEqual(properties["font12"], UIFont.systemFont(ofSize: 24, weight: .ultraLight))
    XCTAssertEqual(properties["font13"], UIFont(name: "GillSans", size: 42))
  }
  
  func testTransforms() {
    let properties: [String: CGAffineTransform] = parsePropertiesToDict(withStyleClass: "transforms", in: "propertyValues", propertyType: .transform)
    let expected1 = CGAffineTransform(rotationAngle: 10.0 * .pi/180.0)
    let expected2 = expected1.concatenating(CGAffineTransform(scaleX: 20, y: 30)).concatenating(CGAffineTransform(translationX: 40, y: 50))
    XCTAssertEqual(properties["transform1"], expected1)
    XCTAssertEqual(properties["transform2"], expected2)
  }
  
  func testEnums() {
    let properties: [String: String] = parsePropertiesToDict(withStyleClass: "enums", in: "propertyValues", propertyType: .enumType)
    XCTAssertEqual(properties["enum1"], "width height left right top bottom")
    XCTAssertEqual(properties["enum2"], "bottomRight")
  }
  
  func testParameters() {
    let properties = loadProperties(withStyleClass: "parameters", in: "propertyValues")
    let actual = properties.map { $0.description }
    let expected = ["params1__selected: blue", "params2__selected_highlighted: blue"]
    XCTAssertEqual(Set(actual), Set(expected))
  }
  
  func testPrefixes() {
    let rulesets = loadRulesets(withStyleClass: "prefixes", in: "propertyValues")
    let actual = rulesets.map { $0.description }
    let expected = [".prefixes $layer { borderwidth: 10 }"]
    XCTAssertEqual(Set(actual), Set(expected))
  }
  
  func testImages() {
    let properties: [String: UIImage] = parsePropertiesToDict(withStyleClass: "images", in: "propertyValues", propertyType: .image)
    let actual = properties.values.compactMap { $0.pngData() }
    let refImage = ImagePropertyParser.imageNamed("image.png")?.pngData()
    XCTAssertEqual(properties.count, 8)
    actual.forEach { XCTAssertEqual($0, refImage) }
  }
  
  func testImagesFromColors() {
    let properties: [String: UIImage] = parsePropertiesToDict(withStyleClass: "imageFromColor", in: "propertyValues", propertyType: .image)
    XCTAssertTrue(compareRGBA(color1: colorOfFirstPixel(properties["image1"])!, color2: UIColor(fromHexString: "112233")!))
    XCTAssertTrue(compareRGBA(color1: colorOfFirstPixel(properties["image2"])!, color2: UIColor(fromHexString: "112233")!.adjustBrightness(by: 50)))
  }
  
  func testNestedWithEmptyDeclaration() {
    let rulesets = loadRulesets(withStyleClass: "nestedWithEmpty", in: "propertyValues")
    let actual = rulesets.map { $0.description }
    let expected = [".nestedWithEmpty .withValue { tag: 42 }"]
    XCTAssertEqual(Set(actual), Set(expected))
  }
}

extension UIColor {
  func rgba() -> [Int] {
    self.rgbaComponents().map { Int(ceil($0 * 255.0)) }
  }
}
