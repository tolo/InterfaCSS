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

public class UIKitStyleSheetPropertyParser: StyleSheetPropertyParser {
  
  @override public func setup(with styleSheetParser: StyleSheetParser) {
    super.setup(with: styleSheetParser)
    
    //* -- CGRect -- *//
    let rectValueParser = S.numericParameterString(withPrefix: "rect", optionalPrefix: true).map { c -> CGRect in
      guard c.count == 4 else { return .zero }
      return CGRect(x: c[0], y: c[1], width: c[2], height: c[3])
    }
    let cgRectFromStringParser = cleanedQuotedStringParser.map { NSCoder.cgRect(for: $0) }
    typeToParser[PropertyType.rect] = P.anyChoice([rectValueParser, cgRectFromStringParser])
    
    //* -- UIOffset -- *//
    let offsetValueParser = S.numericParameterString(withPrefix: "offset", optionalPrefix: true).map { c -> UIOffset in
      if c.count == 2 { return UIOffset(horizontal: c[0], vertical: c[1]) }
      else if c.count == 1 { return UIOffset(horizontal: c[0], vertical: c[0]) }
      return .zero
    }
    let uiOffsetFromStringParser = cleanedQuotedStringParser.map { NSCoder.uiOffset(for: $0) }
    typeToParser[PropertyType.offset] = P.anyChoice([offsetValueParser, uiOffsetFromStringParser])
    
    //* -- CGSize -- *//
    let sizeValueParser = S.numericParameterString(withPrefix: "size", optionalPrefix: true).map { c -> CGSize in
      if c.count == 2 { return CGSize(width: c[0], height: c[1]) }
      else if c.count == 1 { return CGSize(width: c[0], height: c[0]) }
      return .zero
    }
    let cgSizeFromStringParser = cleanedQuotedStringParser.map { NSCoder.cgSize(for: $0) }
    typeToParser[PropertyType.size] = P.anyChoice([sizeValueParser, cgSizeFromStringParser])
    
    //* -- CGPoint -- *//
    let pointValueParser = S.numericParameterString(withPrefix: "point", optionalPrefix: true).map { c -> CGPoint in
      if c.count == 2 { return CGPoint(x: c[0], y: c[1]) }
      else if c.count == 1 { return CGPoint(x: c[0], y: c[0]) }
      return .zero
    }
    let cgPointFromStringParser = cleanedQuotedStringParser.map { NSCoder.cgPoint(for: $0) }
    typeToParser[PropertyType.point] = P.anyChoice([pointValueParser, cgPointFromStringParser])
    
    //* -- UIEdgeInsets -- *//
    let insetsValueParser = S.numericParameterString(withPrefix: "insets", optionalPrefix: true).map { c -> UIEdgeInsets in
      if c.count == 4 { return UIEdgeInsets(top: c[0], left: c[1], bottom: c[2], right: c[3]) }
      else if c.count == 2 { return UIEdgeInsets(top: c[0], left: c[1], bottom: c[0], right: c[1]) }
      else if c.count == 1 { return UIEdgeInsets(top: c[0], left: c[0], bottom: c[0], right: c[0]) }
      return .zero
    }
    let uiEdgeInsetsFromStringParser = cleanedQuotedStringParser.map { NSCoder.uiEdgeInsets(for: $0) }
    typeToParser[PropertyType.edgeInsets] = P.anyChoice([insetsValueParser, uiEdgeInsetsFromStringParser])
    
    //* -- UIFont -- *//
    // Ex: Helvetica 12
    // Ex: bigger(@font, 1)
    // Ex: smaller(@font, 1)
    // Ex: fontWithSize(@font, 12)
    let textStyleMapping : [String: UIFont.TextStyle] = [
      "body": .body, "callout": .callout, "caption1": .caption1, "caption2": .caption2, "footnote": .footnote,
      "headline": .headline, "subheadline": .subheadline, "title1": .title1, "title2": .title2, "title3": .title3]
    
    let commaOrSpace = P.choice([P.space(), S.comma]).many()
    let stringValue = P.choice([S.quotedString, S.anyName])
    let optionalSecondStringValue = P.optional(P.sequential([commaOrSpace.ignore(), stringValue])).map { $0.first }
    
    let systemFontSize: CGFloat
    if #available(iOS 2, *) { systemFontSize = UIFont.systemFontSize }
    else { systemFontSize = 17 }
    
    let fontParser = stringValue.then(optionalSecondStringValue).map { values -> UIFont? in
      var fontSize: CGFloat = systemFontSize
      var fontName: String? = nil
      for value in values {
        var lc = value.lowercased().trim()
        if lc.hasSuffix("pt") || lc.hasSuffix("px") {
          lc = String(lc.prefix(lc.count - 2))
        }
        if lc.count > 0 {
          if lc.isNumeric() {
            fontSize = CGFloat((lc as NSString).floatValue)
          } else { // If not pt, px or comma
            fontName = value.trimQuotes()
          }
        }
      }
      
      if let fontLC = fontName?.lowercased() {
        if fontLC.hasPrefix("boldsystem") || fontLC.hasPrefix("systembold") { return UIFont.boldSystemFont(ofSize: fontSize) }
        else if fontLC.hasPrefix("italicsystem") || fontLC.hasPrefix("systemitalic") { return UIFont.italicSystemFont(ofSize: fontSize) }
        else if fontLC ==⇧ "system" { return UIFont.systemFont(ofSize: fontSize) }
        else if let dynamicFontStyle = textStyleMapping[fontLC] { return UIFont.preferredFont(forTextStyle: dynamicFontStyle) }
      }
      if let fontName = fontName {
        return UIFont(name: fontName, size: fontSize)
      }
      else {
        return UIFont.systemFont(ofSize: fontSize)
      }
    }
    
    let fontFunctionParser =
      identifier.keepLeft(.charSpaced("("))
        .then(fontParser).keepLeft(.charSpaced(","))
        .then(S.plainNumberValue).keepLeft(.charSpaced(")"))
        .map { (fun, font, adjust) -> UIFont in
          if "larger" ==⇧ fun || "bigger" ==⇧ fun {
            return font.withSize(font.pointSize + adjust.cgFloatValue)
          } else if "smaller" ==⇧ fun {
            return font.withSize(font.pointSize - adjust.cgFloatValue)
          } else if "fontWithSize" ==⇧ fun {
            return font.withSize(adjust.cgFloatValue)
          } else {
            return font
          }
    }
    
    if #available(iOS 11, tvOS 11, *) {
      let scaledFontParser = P.sequential([P.string("scaledFont").ignore(), P.charSpacedIgnored("("),
                                           fontParser.asAny(), optionalSecondStringValue.asAny(), P.charSpacedIgnored(")")]).map { values -> UIFont? in
                                            guard let font = values[0] as? UIFont else { return UIFont.systemFont(ofSize: systemFontSize) }
                                            if values.count > 1, let textStyleString = values[1] as? String, let style = textStyleMapping[textStyleString]  {
                                              return UIFontMetrics(forTextStyle: style).scaledFont(for: font)
                                            } else {
                                              return UIFontMetrics.default.scaledFont(for: font)
                                            }
      }
      typeToParser[PropertyType.font] = P.anyChoice([scaledFontParser, fontFunctionParser, fontParser])
    } else {
      typeToParser[PropertyType.font] = P.anyChoice([fontFunctionParser, fontParser])
    }
    
    /** -- Enums -- **/
    let commaOrSpaceOrPipe = P.choice([P.space(), S.comma, P.char("|")]).many()
    let enumValueParser = P.choice([
      S.identifier,
      cleanedQuotedStringParser,
      S.defaultString
    ])
    typeToParser[PropertyType.enumType] = enumValueParser.sepBy(commaOrSpaceOrPipe).concat(" ").asAny()
  }
}
