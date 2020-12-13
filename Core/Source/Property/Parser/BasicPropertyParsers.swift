//
//  BasicPropertyParsers.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation
import Parsicle


private typealias P = AnyParsicle
private let S = StyleSheetParserSyntax.shared
private let identifier = S.identifier


class BasicPropertyParser<ParsedType>: TypedPropertyParser<ParsedType> {
  let parser: Parsicle<ParsedType>
  
  init(parser: Parsicle<ParsedType>) {
    self.parser = parser
  }
  
  override public func parse(propertyValue: PropertyValue) -> ParsedType? {
    guard let rawValue = propertyValue.rawValue else { return nil }
    let result = parser.parse(rawValue)
    if result.match, let value = result.value {
      return value
    }
    return nil
  }
}

class StringPropertyParser: BasicPropertyParser<String> {
  init() {
    let cleanedQuotedStringParser = S.cleanedString
    let localizedStringParser = S.parameterString(withPrefixes: ["localized", "L"]).map(S.cleanedString).map { parameters -> String? in
      guard let key = parameters.first else { return "" }
      return NSLocalizedString(key, comment: "")
    }
    let parser = P.choice([localizedStringParser.beforeEOI(), cleanedQuotedStringParser.beforeEOI()])
    super.init(parser: parser)
  }
}

class BoolPropertyParser: BasicPropertyParser<Bool> {
  init() {
    let identifierOrQuotedString = AnyParsicle.choice([S.identifier, S.quotedString])
    let boolValueParser = identifierOrQuotedString.beforeEOI().map { value in
      return (value.trimQuotes() as NSString).boolValue
    }
    let boolOrLogical = P.choice([boolValueParser, S.logicalExpressionParser()])
    super.init(parser: boolOrLogical)
  }
}

struct ScaledNumber {
  enum Scale {
    case none
    case dynamicTypeScale
    case scaleFactor(Double)
    
    func scale(_ number: NSNumber) -> NSNumber {
      switch self {
        case .none: return number
        case .dynamicTypeScale: return NSNumber(value: Double(UIFontMetrics.default.scaledValue(for: CGFloat(number.doubleValue))))
        case .scaleFactor(let factor): return NSNumber(value: number.doubleValue * factor)
      }
    }
  }
  
  let number: NSNumber
  let scale: Scale
  var scaledNumber: NSNumber { scale.scale(number) }
}

class ScalableNumberPropertyParser: BasicPropertyParser<ScaledNumber> {
  
  static func makeParser(addBeforeEOI: Bool = true, useSimpleExpressions: Bool = false) -> Parsicle<ScaledNumber> {
    let numberValue = useSimpleExpressions ? S.numberOrSimpleExpressionValue : S.numberOrExpressionValue
    let onlyNumberValue = numberValue.map { ScaledNumber(number: $0, scale: .none) }
    let pointsValue = numberValue.keepLeft(S.string("pt", skipSpaces: true)).map { ScaledNumber(number: $0, scale: .none) }
    let pixelsValue = numberValue.keepLeft(S.string("px", skipSpaces: true)).map { (value: NSNumber) in
      return ScaledNumber(number: value, scale: .scaleFactor(1.0 / Double(UIScreen.main.scale)))
    }
    let scalableValue = numberValue.keepLeft(
      P.choice([S.string("sp", skipSpaces: true), S.string("em", skipSpaces: true), S.string("rem", skipSpaces: true)])
    ).map { (value: NSNumber) in
      return ScaledNumber(number: value, scale: .dynamicTypeScale)
    }
    
    if addBeforeEOI {
      return P.choice([pointsValue.beforeEOI(), pixelsValue.beforeEOI(), scalableValue.beforeEOI(), onlyNumberValue.beforeEOI()])
    } else {
      return P.choice([pointsValue, pixelsValue, scalableValue, onlyNumberValue])
    }
  }
  
  init() {
    super.init(parser: ScalableNumberPropertyParser.makeParser())
  }
}

class NumberPropertyParser: BasicPropertyParser<NSNumber> {
  init() {
    let numberParser = ScalableNumberPropertyParser.makeParser().map { $0.scaledNumber }
    super.init(parser: numberParser)
  }
}

class RelativeNumberPropertyParser: BasicPropertyParser<RelativeNumber> {
  init() {
    let numberParser = NumberPropertyParser().parser
    
    //* -- RelativeNumber -- *
    let percent = S.char("%", skipSpaces: true)
    let percentageValue = S.numberValue.keepLeft(percent).beforeEOI().map { value in
      return RelativeNumber(rawValue: value, unit: .percent)
    }
    let autoParser = S.string("auto").or(S.string("*"))
    let autoValue = autoParser.beforeEOI().map { value in
      return RelativeNumber(rawValue: NSNumber(value: 0), unit: .auto)
    }
    let absoluteNumber = numberParser.map { value in
      return RelativeNumber(rawValue: value, unit: .absolute)
    }
    let parser = P.choice([percentageValue, autoValue, absoluteNumber])
    super.init(parser: parser)
  }
}

class EnumPropertyParser: BasicPropertyParser<String> {
  init() {
    let commaOrSpaceOrPipe = P.choice([P.space(), S.comma, P.char("|")]).many()
    let enumValueParser = P.choice([
      S.identifier,
      S.cleanedString,
      S.defaultString
    ])
    let parser = enumValueParser.sepBy(commaOrSpaceOrPipe).concat(" ")
    super.init(parser: parser)
  }
}
