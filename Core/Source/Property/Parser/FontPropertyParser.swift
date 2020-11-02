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
    let stringValue = P.choice([S.quotedString, S.anyName])
    let fontParser = stringValue.sepBy(P.space()).map(Self.parseShorthandFontComponents)
    
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
    
    let parser: Parsicle<UIFont> = P.choice([fontFunctionParser, fontParser])
    super.init(parser: parser)
  }
  
  override public func parse(propertyValue: PropertyValue) -> UIFont? {
    if let fontValue = propertyValue.resolvedCompoundValue as? CompoundFontPropertyValue {
      return Self.parseFont(name: fontValue.name, size: fontValue.size, weight: fontValue.weight, textStyle: fontValue.scalingTextStyle)
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
    return ["largetitle": .largeTitle, "title1": .title1, "title2": .title2, "title3": .title3,
            "headline": .headline, "body": .body, "callout": .callout,
            "subheadline": .subheadline, "subhead": .subheadline,
            "footnote": .footnote, "caption1": .caption1, "caption2": .caption2]
  }()
  
  static let fontWeigtMapping : [String: UIFont.Weight] = {
    return ["ultralight": .ultraLight, "thin": .thin, "light": .light, "regular": .regular, "medium": .medium,
            "semibold": .semibold, "bold": .bold, "heavy": .heavy, "black": .black]
  }()
  
  static let fontWeigtIntMapping : [Int: UIFont.Weight] = {
    return [100: .ultraLight, 200: .thin, 300: .light, 400: .regular, 500: .medium,
            600: .semibold, 700: .bold, 800: .heavy, 900: .black]
  }()
  
  private static func parseWeight(_ weight: String?) -> UIFont.Weight? {
    guard let weight = weight else { return nil }
    if weight.isNumeric(), let weightNumber = Int(weight) {
      var validWeight = (weightNumber / 100) * 100
      validWeight = min(max(validWeight, 100), 900)
      return fontWeigtIntMapping[validWeight]
    } else {
      return fontWeigtMapping[weight.lowercased()]
    }
  }
  
  static func parseFont(name _name: String?, size: String?, weight: String?, textStyle: String?) -> UIFont {
    let name = _name?.trimQuotes()
    
    var fontSize: CGFloat = Self.systemFontSize
    if let size = size {
      let sizeScanner = Scanner(string: size)
      var scanned: Double = 0
      if sizeScanner.scanDouble(&scanned) { fontSize = CGFloat(scanned) }
    }
    
    var alreadyScaled = false
    var font: UIFont?
    // System font, with optional weight in name, i.e. "system-bold" or "system-light-italic"
    if let fontLC = name?.lowercased(), fontLC.hasPrefix("system") {
      var optionalModifier = weight ?? fontLC.deletingPrefix("system").replacingOccurrences(of: "-", with: "")
      let hasItalicModifier = optionalModifier.rangeOf("italic") != nil
      optionalModifier = optionalModifier.replacingOccurrences(of: "italic", with: "")
      
      // Use weight, if specific
      if optionalModifier.hasData(), let weight = parseWeight(optionalModifier) {
        font = UIFont.systemFont(ofSize: fontSize, weight: weight)
      } else {
        font = UIFont.systemFont(ofSize: fontSize)
      }
      // Apply italic attribute, if specifed
      if hasItalicModifier, let f = font {
        var symTraits = f.fontDescriptor.symbolicTraits
        symTraits.insert([.traitItalic])
        if let fd = f.fontDescriptor.withSymbolicTraits(symTraits) {
          font = UIFont(descriptor: fd, size: f.pointSize)
        }
      }
    }
    // TODO: Monospaced system font?
    // In case only name specified - check if it matches a (dynamic) text style name:
    else if let fontLC = name?.lowercased(), let style = textStyleMapping[fontLC], size == nil, weight == nil, textStyle == nil {
      font = UIFont.preferredFont(forTextStyle: style)
      alreadyScaled = true
    }
    // Only text style
    else if let textStyle = textStyle?.lowercased(), let style = textStyleMapping[textStyle], size == nil, weight == nil, name == nil {
      font = UIFont.preferredFont(forTextStyle: style)
      alreadyScaled = true
    }
    else if let fontName = name {
      if let f = UIFont(name: fontName, size: fontSize) {
        font = f
        // Apply font weight
        if let weight = parseWeight(weight) {
          let traits = [UIFontDescriptor.TraitKey.weight: weight]
          let fd = f.fontDescriptor.addingAttributes([.traits: traits])
          font = UIFont(descriptor: fd, size: f.pointSize)
        }
      }
      else { error(.styling, "Unable to resolve font '\(fontName)' with size '\(fontSize)'")  }
    }
    
    let resolvedFont = font ?? UIFont.systemFont(ofSize: fontSize)
    if !alreadyScaled, let textStyle = textStyle {
      if let style = textStyleMapping[textStyle] {
        return resolvedFont.scaledFont(for: style)
      } else {
        return resolvedFont.scaledFont()
      }
    } else {
      return resolvedFont
    }
  }
  
  /**
   [ios-font-scaling-style | 'scaled'] [font-weight] font-size font-family
   */
  static func parseShorthandFontComponents(_ values: [String]) -> UIFont? {
    let reversed: [String] = values.reversed()
    
    var fontTextStyle: String? = reversed.count > 3 ? reversed[3].lowercased() : nil
    var fontWeight: String? = reversed.count > 2 ? reversed[2].lowercased() : nil
    var fontSize: String? = reversed.count > 1 ? reversed[1].lowercased() : nil
    var fontName: String? = reversed.count > 0 ? reversed[0].lowercased() : nil
    
    // Keep only digits (ignore any trailing px or pt etc)
    if let sizeNumberOnly = fontSize?.extractPrefix(withCharactersIn: .decimalDigits) {
      fontSize = sizeNumberOnly.str
    }
    // Attepmt switcharoo (if name and size are in incorrect order - legacy support):
    else if let numberInName = fontName?.extractPrefix(withCharactersIn: .decimalDigits) {
      (fontName, fontSize) = (fontSize, numberInName.str)
    }
    
    if fontTextStyle == nil, let weight = fontWeight?.lowercased() {
      let isWeight = weight.isNumeric() || fontWeigtMapping[weight] != nil
      let isTextStyle = weight ~= "scaled" || textStyleMapping[weight] != nil
      // Switcharoo (i.e. weight is text style):
      if isTextStyle && !isWeight {
        fontTextStyle = fontWeight
        fontWeight = nil
      }
    }
    
    return parseFont(name: fontName, size: fontSize, weight: fontWeight, textStyle: fontTextStyle)
  }
}
