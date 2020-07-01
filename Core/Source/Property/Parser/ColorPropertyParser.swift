//
//  ColorPropertyParser.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit
import Parsicle


private typealias P = AnyParsicle
private let S = StyleSheetParserSyntax.shared
private let identifier = S.identifier
private let anyName = S.anyName

class UIColorPropertyParser: BasicPropertyParser<UIColor> {
  
  class var basicColorValueParsers: [Parsicle<UIColor>] {
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
  
  class func parsePredefColorValue(_ value: String) -> UIColor? {
    let colorString = value.trimQuotes().lowercased()
    return CssColors.color(forName: colorString);
  }
  
  class func colorFunctionParser(_ colorValueParsers: [Parsicle<UIColor>], preDefColorParser: Parsicle<UIColor>) -> Parsicle<UIColor> {
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
        if "lighten" ~= fun { return color.adjustBrightness(by: param) }
        else if "darken" ~= fun { return color.adjustBrightness(by: -param) }
        else if "saturate" ~= fun { return color.adjustSaturation(by: param) }
        else if "desaturate" ~= fun { return color.adjustSaturation(by: -param) }
        else if "fadein" ~= fun { return color.adjustAlpha(by: param) }
        else if "fadeout" ~= fun { return color.adjustAlpha(by: -param) }
        else if "opacity" ~= fun || "alpha" ~= fun { return color.withAlphaComponent(param) }
        return .magenta
    }
    colorFunctionParserProxy.delegate = colorFunctionParser
    return colorFunctionParserProxy
  }
  
  class func colorCatchAllParser(_ imageParser: Parsicle<UIImage>) -> [Parsicle<UIColor>] {
    // Parses an arbitrary text string as a predefined color (i.e. redColor) or pattern image from file name - in that order
    let catchAll = S.anyName.map { value -> UIColor in
      if let color = parsePredefColorValue(value) {
        return color
      } else if let image = UIImage(named: value) {
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
  
  class func colorParsers(_ colorValueParsers: [Parsicle<UIColor>], colorCatchAllParsers: [Parsicle<UIColor>]) -> Parsicle<UIColor> {
    let preDefColorParser = S.identifier.map { parsePredefColorValue($0) }
    let colorFunctionParser = self.colorFunctionParser(colorValueParsers, preDefColorParser: preDefColorParser)
    return P.choice([colorFunctionParser] + colorValueParsers + colorCatchAllParsers)
  }
  
  init() {
    let colorCatchAllParsers = Self.colorCatchAllParser(ImagePropertyParser.imageParser)
    let uiColorValueParsers = Self.basicColorValueParsers
    
    super.init(parser: Self.colorParsers(uiColorValueParsers, colorCatchAllParsers: colorCatchAllParsers))
  }
}

class CGColorPropertyParser: BasicPropertyParser<CGColor> {
  init() {
    super.init(parser: UIColorPropertyParser().parser.map { $0.cgColor })
  }
}
