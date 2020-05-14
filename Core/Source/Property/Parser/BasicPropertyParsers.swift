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


class BasicPropertyParser<T>: PropertyTypeValueParser {
  let parser: Parsicle<T>
  
  init(parser: Parsicle<T>) {
    self.parser = parser
  }
  
  func parse(propertyValue: PropertyValue) -> Any? {
    return propertyValue.rawValue != nil ? parser.parse(propertyValue.rawValue!) : nil
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

class NumberPropertyParser: BasicPropertyParser<NSNumber> {
  init() {
    let numberValue = S.numberValue.beforeEOI()
    let numericExpressionValue = S.numberOrExpressionValue.beforeEOI()
    let numberParser = P.choice([numberValue, numericExpressionValue])
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
