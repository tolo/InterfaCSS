//
//  StyleSheetPropertyParser.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation
import Parsicle


private typealias P = AnyParsicle
private let S = StyleSheetParserSyntax.shared

public class StyleSheetPropertyParser: NSObject, StyleSheetPropertyParsingDelegate, StyleSheetParserSupport {
  
  private(set) weak var styleSheetParser: StyleSheetParser?
  
  private var identifier: StringParsicle { S.identifier }
  private var anyName: StringParsicle { S.anyName }
  
  func parser(for propertyType: PropertyType) -> AnyParsicle? {
    return typeToParser[propertyType]
  }
  
  func setParser(_ parser: AnyParsicle, for propertyType: PropertyType) {
    typeToParser[propertyType] = parser
  }
  
  private var typeToParser: [PropertyType : AnyParsicle] = [:]
  
  
  public func parsePropertyValue(_ propertyValue: String, of type: PropertyType) -> Any? {
    guard let parser = typeToParser[type] else { return nil }
    let result = parser.parse(propertyValue)
    if result.match, let value = result.value {
      return value
    }
    return nil
  }
  
  public func setup(with styleSheetParser: StyleSheetParser) {
    self.styleSheetParser = styleSheetParser
    //weak var blockSelf: StyleSheetPropertyParser? = self
    
    // Property parser setup:
    //* -- String -- *
    let cleanedQuotedStringParser = S.cleanedString
    let localizedStringParser = S.parameterString(withPrefixes: ["localized", "L"]).map(S.cleanedString).map { parameters -> String? in
      guard let string = parameters.first else { return "" }
      return self.localizedString(withKey: string)
    }
    let stringParser = P.choice([localizedStringParser.beforeEOI(), cleanedQuotedStringParser.beforeEOI()])
    typeToParser[PropertyType.string] = stringParser.asAny()
    
    //* -- BOOL -- *
    let identifierOrQuotedString = AnyParsicle.choice([S.identifier, S.quotedString])
    let boolValueParser = identifierOrQuotedString.beforeEOI().map { value in
      return (value.trimQuotes() as NSString).boolValue
    }
    typeToParser[PropertyType.bool] = P.anyChoice([boolValueParser, S.logicalExpressionParser()])
    
    //* -- Number -- *
    let numberValue = S.numberValue.beforeEOI()
    let numericExpressionValue = S.numberOrExpressionValue.beforeEOI()
    let numberParser = P.choice([numberValue, numericExpressionValue])
    typeToParser[PropertyType.number] = numberParser.asAny()
    
    //* -- RelativeNumber -- *
    let percent = char("%", skipSpaces: true)
    let percentageValue = S.numberValue.keepLeft(percent).beforeEOI().map { value in
      return RelativeNumber(rawValue: value, unit: .percent)
    }
    let autoParser = string("auto").or(string("*"))
    let autoValue = autoParser.beforeEOI().map { value in
      return RelativeNumber(rawValue: NSNumber(value: 0), unit: .auto)
    }
    let absoluteNumber = numberParser.map { value in
      return RelativeNumber(rawValue: value, unit: .absolute)
    }
    typeToParser[PropertyType.relativeNumber] = P.anyChoice([percentageValue, autoValue, absoluteNumber])
    
    /** -- UIImage (1) -- **/
    // Ex: image.png
    // Ex: image(image.png);
    // Ex: image(image.png, 1, 2);
    // Ex: image(image.png, 1, 2, 3, 4);
    let imageParser = S.parameterString(withPrefix: "image", optionalPrefix: true).map(S.cleanedString).map { [unowned self] v -> UIImage? in
      guard v.count > 0, let image = self.imageNamed(v[0]) else { return nil }
      let str = v as [NSString]
      
      if v.count == 5 {
        return image.resizableImage(withCapInsets: UIEdgeInsets(top: CGFloat(str[1].floatValue), left: CGFloat(str[2].floatValue), bottom: CGFloat(str[3].floatValue), right: CGFloat(str[4].floatValue)))
      } else {
        return image
      }
    }
    
    /** -- UIColor / CGColor -- **/
    let colorCatchAllParsers = colorCatchAllParser(imageParser)
    let uiColorValueParsers = basicColorValueParsers()
    let colorPropertyParser = colorParsers(uiColorValueParsers, colorCatchAllParsers: colorCatchAllParsers)
    typeToParser[PropertyType.color] = colorPropertyParser.asAny()
    
    typeToParser[PropertyType.cgColor] = colorPropertyParser.map { $0.cgColor }
    
    /** -- UIImage (2) -- **/
    typeToParser[PropertyType.image] = imageParsers(imageParser, colorValueParsers: uiColorValueParsers).asAny()
    
    /** -- CGAffineTransform -- **/
    // Ex: rotate(90) scale(2,2) translate(100,100);
    let rotateValueParser = S.numericParameterString(withPrefix: "rotate").map { values -> CGAffineTransform in
      guard let value = values.first else { return .identity }
      let angle = .pi * value / 180.0
      return CGAffineTransform(rotationAngle: angle)
    }
    let scaleValueParser = S.numericParameterString(withPrefix: "scale").map { values -> CGAffineTransform in
      if values.count == 2 { return CGAffineTransform(scaleX: values[0], y: values[1]) }
      else if values.count == 1 { return CGAffineTransform(scaleX: values[0], y: values[0]) }
      else { return .identity }
    }
    let translateValueParser = S.numericParameterString(withPrefix: "translate").map { values -> CGAffineTransform in
      if values.count == 2 { return CGAffineTransform(translationX: values[0], y: values[1]) }
      else if values.count == 1 { return CGAffineTransform(translationX: values[0], y: values[0]) }
      else { return .identity }
    }
    let transformValuesParser = P.choice([rotateValueParser, scaleValueParser, translateValueParser]).sepBy(.spaces()).map { values -> CGAffineTransform in
      var transform: CGAffineTransform = .identity
      if values.count == 1 {
        transform = values[0]
      } else {
        for transformVal in values {
          transform = transform.concatenating(transformVal)
        }
      }
      return transform
    }
    typeToParser[PropertyType.transform] = transformValuesParser.asAny()
  }
  
  
  // MARK: - Color parsing
  
  func basicColorValueParsers() -> [Parsicle<UIColor>] {
    let rgb = S.numericParameterString(withPrefix: "rgb").map { cc -> UIColor in
      guard cc.count == 3 else {
        return .magenta
        
      }
      return UIColor(r: Int(cc[0]), g: Int(cc[1]), b: Int(cc[2]))
    }
    let rgba = S.numericParameterString(withPrefix: "rgba").map { cc -> UIColor in
      guard cc.count == 4 else {
        return .magenta }
      return UIColor(r: Int(cc[0]), g: Int(cc[1]), b: Int(cc[2]), a: cc[3])
    }
    
    var hexDigitsSet = CharacterSet(charactersIn: "aAbBcCdDeEfF")
    hexDigitsSet.formUnion(CharacterSet.decimalDigits)
    let hexColor = P.char("#").keepRight(P.take(whileIn: hexDigitsSet, minCount: 3)).map { value in
      return UIColor.fromHexString(value)
    }
    return [rgb, rgba, hexColor]
  }
  
  func parsePredefColorValue(_ value: String) -> UIColor? {
    let colorString = value.trimQuotes().lowercased()
    return CssColors.color(forName: colorString);
  }
  
  func colorFunctionParser(_ colorValueParsers: [Parsicle<UIColor>], preDefColorParser: Parsicle<UIColor>) -> Parsicle<UIColor> {
    var colorValueParsers = colorValueParsers
    let colorFunctionParserProxy = DelegatingParsicle<UIColor>()
    colorValueParsers = [colorFunctionParserProxy] + colorValueParsers
    colorValueParsers = colorValueParsers + [preDefColorParser]
    
    let colorParamParser = P.choice(colorValueParsers)
    let colorFunctionParser = identifier.keepLeft(.charSpaced("("))
      .then(colorParamParser).keepLeft(.charSpaced(","))
      .then(anyName).keepLeft(.charSpaced(")")).map { values -> UIColor in
        let (fun, color, paramString) = values
        let param = CGFloat((paramString as NSString).floatValue)
        if "lighten" ==⇧ fun { return color.adjustBrightness(by: param) }
        else if "darken" ==⇧ fun { return color.adjustBrightness(by: -param) }
        else if "saturate" ==⇧ fun { return color.adjustSaturation(by: param) }
        else if "desaturate" ==⇧ fun { return color.adjustSaturation(by: -param) }
        else if "fadein" ==⇧ fun { return color.adjustAlpha(by: param) }
        else if "fadeout" ==⇧ fun { return color.adjustAlpha(by: -param) }
        else if "opacity" ==⇧ fun || "alpha" ==⇧ fun { return color.withAlphaComponent(param) }
        return .magenta
    }
    colorFunctionParserProxy.delegate = colorFunctionParser
    return colorFunctionParserProxy
  }
  
  func colorCatchAllParser(_ imageParser: Parsicle<UIImage>) -> [Parsicle<UIColor>] {
    // Parses an arbitrary text string as a predefined color (i.e. redColor) or pattern image from file name - in that order
    let catchAll = S.anyName.map { [unowned self] value -> UIColor in
      if let color = self.parsePredefColorValue(value) {
        return color
      } else if let image = self.imageNamed(value) {
        return UIColor(patternImage: image)
      }
      return UIColor.magenta
    }
    
    // Parses well defined image value (i.e. "image(...)") as pattern image
    let patternImageParser = imageParser.map { value in
      return UIColor(patternImage: value)
    }
    return [patternImageParser, catchAll]
  }
  
  func colorParsers(_ colorValueParsers: [Parsicle<UIColor>], colorCatchAllParsers: [Parsicle<UIColor>]) -> Parsicle<UIColor> {
    let preDefColorParser = S.identifier.map { [unowned self] in self.parsePredefColorValue($0) }
    let colorFunctionParser = self.colorFunctionParser(colorValueParsers, preDefColorParser: preDefColorParser)
    return P.choice([colorFunctionParser] + colorValueParsers + colorCatchAllParsers)
  }
  
  
  // MARK: - Image parsing
  
  func imageParsers(_ imageParser: Parsicle<UIImage>, colorValueParsers: [Parsicle<UIColor>]) -> Parsicle<UIImage> {
    let preDefColorParser = S.identifier.map { [unowned self] in self.parsePredefColorValue($0) }
    
    // Parse color functions as UIImage
    let colorFunctionParser = self.colorFunctionParser(colorValueParsers, preDefColorParser: preDefColorParser)
    let colorFunctionAsImage = colorFunctionParser.map {
      $0.asUIImage()
    }
    
    // Parses well defined color values (i.e. basicColorValueParsers)
    let colorParser = P.choice(colorValueParsers)
    let colorAsImage = colorParser.map {
      $0.asUIImage()
    }
    
    // Parses an arbitrary text string as an image from file name or pre-defined color name - in that order
    let catchAll = S.cleanedString.map { [unowned self] value -> UIImage? in
      let trimmed = value.trim()
      if let image = self.imageNamed(trimmed) {
        return image
      } else if let color = self.parsePredefColorValue(trimmed) {
        return color.asUIImage()
      }
      return nil
    }
    return P.choice([imageParser, colorFunctionAsImage, colorAsImage, catchAll])
  }
  
  
  // MARK: - Methods existing mainly for testing purposes
  
  open func imageNamed(_ name: String) -> UIImage? {
    return UIImage(named: name)
  }
  
  open func localizedString(withKey key: String) -> String {
    return NSLocalizedString(key, comment: "")
  }
}
