//
//  FontPropertyParser.swift
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


// Ex: Helvetica 12
// Ex: bigger(@font, 1)
// Ex: smaller(@font, 1)
// Ex: fontWithSize(@font, 12)
class UIFontPropertyParser: BasicPropertyParser<UIFont> {
  init() {
    let commaOrSpace = P.choice([P.space(), S.comma]).many()
    let stringValue = P.choice([S.quotedString, S.anyName])
    let optionalSecondStringValue = P.optional(P.sequential([commaOrSpace.ignore(), stringValue])).map { $0.first }
    
    let fontParser = stringValue.then(optionalSecondStringValue).map(Self.parseFont)
    
    let fontFunctionParser =
      identifier.keepLeft(.charSpaced("("))
        .then(fontParser).keepLeft(.charSpaced(","))
        .then(S.plainNumberValue).keepLeft(.charSpaced(")"))
        .map { (fun, font, adjust) -> UIFont in
          if "larger" ~= fun || "bigger" ~= fun {
            return font.withSize(font.pointSize + adjust.cgFloatValue)
          } else if "smaller" ~= fun {
            return font.withSize(font.pointSize - adjust.cgFloatValue)
          } else if "fontWithSize" ~= fun {
            return font.withSize(adjust.cgFloatValue)
          } else {
            return font
          }
    }
    
    let parser: Parsicle<UIFont>
    if #available(iOS 11, tvOS 11, *) {
      let toFont = { (values: [Any]) -> UIFont? in
        guard let font = values[0] as? UIFont else { return UIFont.systemFont(ofSize: Self.systemFontSize) }
        if values.count > 1, let textStyleString = values[1] as? String, let style = Self.textStyleMapping[textStyleString]  {
          return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
        } else {
          return UIFontMetrics.default.scaledFont(for: font)
        }
      }
      let scaledFontParser = P.sequential([P.string("scaledFont").ignore(),
                                           P.charSpacedIgnored("("),
                                           fontParser.asAny(),
                                           optionalSecondStringValue.asAny(),
                                           P.charSpacedIgnored(")")]).map(toFont)
      parser = P.choice([scaledFontParser, fontFunctionParser, fontParser])
    } else {
      parser = P.choice([fontFunctionParser, fontParser])
    }
    super.init(parser: parser)
  }
  
  override public func parse(propertyValue: PropertyValue) -> UIFont? {
    if case .compoundValues(let compoundProperty, let compoundValues) = propertyValue.value {
      let values = compoundProperty.rawValues(from: compoundValues)
      return Self.parseFont(name: values[CompoundFontProperty.fontFamily], size: values[CompoundFontProperty.fontWeight])
    } else {
      return super.parse(propertyValue: propertyValue)
    }
  }
  
}


extension UIFontPropertyParser {
  static let systemFontSize: CGFloat = {
    if #available(iOS 2, *) { return UIFont.systemFontSize }
    else { return 17 }
  }()
  
  static let textStyleMapping : [String: UIFont.TextStyle] = {
    return ["body": .body, "callout": .callout, "caption1": .caption1, "caption2": .caption2, "footnote": .footnote,
            "headline": .headline, "subheadline": .subheadline, "title1": .title1, "title2": .title2, "title3": .title3]
  }()
  
  static func parseFont(name: String?, size: String?) -> UIFont {
    var fontSize: CGFloat = Self.systemFontSize
    if let size = size {
      let sizeScanner = Scanner(string: size)
      var scanned: Double = 0
      if sizeScanner.scanDouble(&scanned) { fontSize = CGFloat(scanned) }
    }
    
    if let fontLC = name?.lowercased() {
      if fontLC.hasPrefix("boldsystem") || fontLC.hasPrefix("systembold") { return UIFont.boldSystemFont(ofSize: fontSize) }
      else if fontLC.hasPrefix("italicsystem") || fontLC.hasPrefix("systemitalic") { return UIFont.italicSystemFont(ofSize: fontSize) }
      else if fontLC ~= "system" { return UIFont.systemFont(ofSize: fontSize) }
      else if let dynamicFontStyle = textStyleMapping[fontLC] { return UIFont.preferredFont(forTextStyle: dynamicFontStyle) }
    }
    if let fontName = name {
      return UIFont(name: fontName, size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
    }
    else {
      return UIFont.systemFont(ofSize: fontSize)
    }
  }
  
  static func parseFont(_ values: [String]) -> UIFont? {
    var fontSize: String?
    var fontName: String?
    for _string in values {
      var string = _string.lowercased().trim()
      if string.hasSuffix("pt") || string.hasSuffix("px") {
        string = String(string.prefix(string.count - 2))
      }
      if string.count > 0 {
        if string.isNumeric() {
          fontSize = string
        } else { // If not pt, px or comma
          fontName = string.trimQuotes()
        }
      }
    }
    
    return parseFont(name: fontName, size: fontSize)
  }
}
