//
//  StyleSheetParserSyntax.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation
import Parsicle


private typealias P = AnyParsicle


public class StyleSheetParserSyntax {
  
  public static let shared: StyleSheetParserSyntax = {
    return StyleSheetParserSyntax()
  }()
  
  // Common charsets
  public let validInitialIdentifierCharacterCharsSet: CharacterSet!
  public let validIdentifierExcludingMinusCharsSet: CharacterSet!
  public let validIdentifierCharsSet: CharacterSet!
  public let mathExpressionCharsSet: CharacterSet!
  public let simpleMathExpressionCharsSet: CharacterSet!
  
  // Common basic parsers
  public let dot: StringParsicle
  public let hashSymbol: StringParsicle
  public let comma: StringParsicle
  public let openBraceSkipSpace: StringParsicle
  public let closeBraceSkipSpace: StringParsicle
  public let spacesIgnored: StringParsicle
  public let singleQuote: StringParsicle
  public let doubleQuote: StringParsicle
  
  // Common complex parsers
  private(set) public lazy var identifier: StringParsicle = validIdentifierChars(1)
  private(set) public lazy var anyName: StringParsicle = anythingButWhiteSpaceAndExtendedControlChars(1)
  private(set) public lazy var anythingButControlChars: StringParsicle = anythingButBasicControlChars(1)
  private(set) public lazy var anythingButControlCharsAndWhiteSpace: StringParsicle = anythingButWhiteSpaceAndBasicControlChars(1)
    
  private func number() -> StringParsicle {
    let plainNumber = P.digit().concatMany()
    let fraction = dot.then(plainNumber).concat()
    return plainNumber.then(AnyParsicle.optional(fraction, defaultValue: "")).concat()
  }
  
  private(set) public lazy var plainNumber: StringParsicle = {
    return number()
  }()
  private(set) public lazy var plainNumberValue: Parsicle<NSNumber> = {
    number().asNumber()
  }()
  private(set) public lazy var numberValue: Parsicle<NSNumber> = {
    let plus = char("+", skipSpaces: true)
    let minus = char("-", skipSpaces: true)
    let negativeNumber = minus.keepRight(plainNumber).map { NSNumber(value: -($0 as NSString).doubleValue) }
    let positiveNumberString = plus.keepRight(plainNumber)
    let positiveNumber = P.choice([positiveNumberString, plainNumber]).map { NSNumber(value: ($0 as NSString).doubleValue) }
    return P.choice([negativeNumber, positiveNumber])
  }()
  private(set) public lazy var numberOrSimpleExpressionValue: Parsicle<NSNumber> = mathExpressionParser(simple: true)
  private(set) public lazy var numberOrExpressionValue: Parsicle<NSNumber> = mathExpressionParser()
  private(set) public lazy var quotedString: StringParsicle = {
    let notSingleQuote = P.stringWithEscapesUp(to: "\'", skipPastEndChar: true)
    let singleQuotedString = singleQuote.keepRight(notSingleQuote).keepLeft(singleQuote)
    let notDoubleQuote = P.stringWithEscapesUp(to: "\"", skipPastEndChar: true)
    let doubleQuotedString = doubleQuote.keepRight(notDoubleQuote)
    
    return P.choice([singleQuotedString, doubleQuotedString])
  }()
  private(set) public lazy var defaultString: StringParsicle = {
    return anythingButControlChars
  }()
  private(set) public lazy var cleanedString: StringParsicle = {
    quotedString.or(defaultString).skipSurroundingSpaces().map {
      self.cleanedStringValue($0)
    }
  }()
  private(set) public lazy var quotedIdentifier: StringParsicle = {
    singleQuote.keepRight(identifier).keepLeft(singleQuote).or(doubleQuote.keepRight(identifier).keepLeft(doubleQuote))
  }()
  private(set) public lazy var comment: StringParsicle = {
    let commentParser = P.string("/*", skipSpaces: true).keepRight(P.take(untilString: "*/", andSkip: true))
    return commentParser.map { $0.trim() }
  }()
  
  private(set) public lazy var propertyName: StringParsicle = {
    let nameInitial = AnyParsicle.char(in: validInitialIdentifierCharacterCharsSet)
    var validIdentifierCharsAndDotSet = CharacterSet(charactersIn: ".")
    validIdentifierCharsAndDotSet.formUnion(validIdentifierCharsSet)
    let nameRemaining = AnyParsicle.take(whileIn: validIdentifierCharsAndDotSet)
    return nameInitial.then(nameRemaining).concat()
  }()
  
  private(set) public lazy var propertyNameValueSeparator: StringParsicle = { AnyParsicle.char(":").or(AnyParsicle.char("=")) }()
  
  
  init() {
    var characterSet = CharacterSet(charactersIn: "_")
    characterSet.formUnion(CharacterSet.letters)
    validInitialIdentifierCharacterCharsSet = characterSet
    
    characterSet = CharacterSet(charactersIn: "_")
    characterSet.formUnion(CharacterSet.alphanumerics)
    validIdentifierExcludingMinusCharsSet = characterSet
    
    characterSet = CharacterSet(charactersIn: "-_")
    characterSet.formUnion(CharacterSet.alphanumerics)
    validIdentifierCharsSet = characterSet
    
    characterSet = CharacterSet(charactersIn: "+-*/%^=≠<>≤≥|&!().")
    characterSet.formUnion(CharacterSet.decimalDigits)
    characterSet.formUnion(CharacterSet.whitespaces)
    mathExpressionCharsSet = characterSet
    
    characterSet = CharacterSet(charactersIn: "+-*/%^=≠<>≤≥|&!.")
    characterSet.formUnion(CharacterSet.decimalDigits)
    characterSet.formUnion(CharacterSet.whitespaces)
    simpleMathExpressionCharsSet = characterSet
    
    /** Common parsers setup **/
    dot = P.char(".")
    hashSymbol = P.char("#")
    comma = P.char(",")
    openBraceSkipSpace = P.char("{", skipSpaces: true)
    closeBraceSkipSpace = P.char("}", skipSpaces: true)
    spacesIgnored = P.spaces().ignore()
    singleQuote = P.char("\'")
    doubleQuote = P.char("\"")
  }
  
  
  // MARK: - Indentifier and control char parsers
  
  func anythingButBasicControlChars(_ minCount: Int) -> StringParsicle {
    let characterSet = CharacterSet(charactersIn: ":;{}")
    return AnyParsicle.take(untilIn: characterSet, minCount: minCount)
  }
  
  func anythingButWhiteSpaceAndBasicControlChars(_ minCount: Int) -> StringParsicle {
    var characterSet = CharacterSet(charactersIn: ":;{}")
    characterSet.formUnion(CharacterSet.whitespacesAndNewlines)
    return AnyParsicle.take(untilIn: characterSet, minCount: minCount)
  }
  
  func anythingButBasicControlCharsExceptColon(_ minCount: Int) -> StringParsicle {
    let characterSet = CharacterSet(charactersIn: ";{}")
    return AnyParsicle.take(untilIn: characterSet, minCount: minCount)
  }
  
  func anythingButWhiteSpaceAndExtendedControlChars(_ minCount: Int) -> StringParsicle {
    var characterSet = CharacterSet(charactersIn: ",:;{}()")
    characterSet.formUnion(CharacterSet.whitespacesAndNewlines)
    return AnyParsicle.take(untilIn: characterSet, minCount: minCount)
  }
  
  func validIdentifierChars(_ minCount: Int) -> StringParsicle {
    return validIdentifierChars(minCount, onlyAlphpaAndUnderscore: false)
  }
  
  func validIdentifierChars(_ minCount: Int, onlyAlphpaAndUnderscore: Bool) -> StringParsicle {
    let characterSet: CharacterSet
    if onlyAlphpaAndUnderscore {
      characterSet = validIdentifierExcludingMinusCharsSet
    } else {
      characterSet = validIdentifierCharsSet
    }
    return AnyParsicle.take(whileIn: characterSet, withInitialCharSet: validInitialIdentifierCharacterCharsSet, minCount: minCount) // First identifier char must not be digit...
  }
  
  
  // MARK: - Expression parsers
  
  func logicalExpressionParser() -> Parsicle<Bool> {
    let invertedCharacterSet: CharacterSet = mathExpressionCharsSet.inverted
    return AnyParsicle.take(untilIn: invertedCharacterSet, minCount: 1).map { value, context in
      guard !context.matchOnly else { return true }
      if let value = NSPredicate.evaluatePredicateAndCatchError(value) {
        return value.boolValue
      } else {
        error(.stylesheets, "Error evaluating logical expression '\(value)'")
        return false
      }
    }
  }
  
  func mathExpressionParser(simple: Bool = false) -> Parsicle<NSNumber> {
    let invertedCharacterSet: CharacterSet = simple ? simpleMathExpressionCharsSet.inverted : mathExpressionCharsSet.inverted
    return AnyParsicle.take(untilIn: invertedCharacterSet, minCount: 1).map { value, context in
      guard !context.matchOnly else { return NSNumber(1) }
      return self.parseMathExpression(value)
    }
  }
  
  func parseMathExpression(_ value: String) -> NSNumber? {
    if let value = NSPredicate.evaluateExpressionAndCatchError(value) {
      return value as? NSNumber
    } else {
      error(.stylesheets, "Error evaluating math expression '\(value)'")
      return false
    }
  }
  
  
  // MARK: - Property pair parsing
  
  func propertyPairParser(forVariable forVariableDefinition: Bool, standalone: Bool = false) -> Parsicle<[String]> {
    let nameParser = propertyName
    let valueParser = propertyValueParser(forVariable: forVariableDefinition, standalone: standalone).skipSurroundingSpaces()
    if forVariableDefinition {
      let nameAndSpacesParser = AnyParsicle.string("--").or(.char("@")).keepRight(nameParser).skipSurroundingSpaces()
      return nameAndSpacesParser.keepLeft(propertyNameValueSeparator).then(valueParser)
    } else {
      let nameAndSpacesParser = nameParser.skipSurroundingSpaces()
      return nameAndSpacesParser.keepLeft(propertyNameValueSeparator).then(valueParser)
    }
  }
  
  private func propertyValueParser(forVariable forVariableDefinition: Bool, standalone: Bool) -> StringParsicle {
    let invalidChars = CharacterSet(charactersIn: "{}")
    return StringParsicle.stringWithEscapesUp(to: ";", skipPastEndChar: !standalone, replaceEscapes: false, invalidChars: invalidChars)
  }
  
  
  // MARK: - Parameter strings
  
  private func prefixParser(_ prefixes: [String], optionalPrefix: Bool = false) -> StringParsicle {
    if prefixes.count > 1 {
      let p = prefixes.map { StringParsicle.string($0) }
      return optionalPrefix ? P.choice(p).optional() : P.choice(p)
    } else if let prefix = prefixes.first {
      return optionalPrefix ? StringParsicle.string(prefix).optional() : StringParsicle.string(prefix)
    } else {
      return PassThroughParsicle
    }
  }
  
  func parameterString(withPrefix prefix: String, optionalPrefix: Bool = false) -> Parsicle<[String]> {
    return parameterString(withPrefixes: [prefix], optionalPrefix: optionalPrefix)
  }
  func parameterString(withPrefixes prefixes: [String], optionalPrefix: Bool = false) -> Parsicle<[String]> {
    let prefix = prefixParser(prefixes, optionalPrefix: optionalPrefix)
    return prefix.keepRight(StringParsicle.paramList())
  }
  func parameterString(withPrefixesKeep prefixes: [String], optionalPrefix: Bool = false) -> Parsicle<(String, [String])> {
    let prefix = prefixParser(prefixes, optionalPrefix: optionalPrefix)
    return prefix.then(StringParsicle.paramList())
  }
  
  func numericParameterString(withPrefix prefix: String, optionalPrefix: Bool = false) -> Parsicle<[CGFloat]> {
    return numericParameterString(withPrefixes: [prefix], optionalPrefix: optionalPrefix)
  }
  func numericParameterString(withPrefixes prefixes: [String], optionalPrefix: Bool = false) -> Parsicle<[CGFloat]> {
    let prefix = prefixParser(prefixes, optionalPrefix: optionalPrefix)
    return prefix.keepRight(numericParameterList())
  }
  func numericParameterString(withPrefixesKeep prefixes: [String], optionalPrefix: Bool = false) -> Parsicle<(String, [CGFloat])> {
    let prefix = prefixParser(prefixes, optionalPrefix: optionalPrefix)
    return prefix.then(numericParameterList())
  }
  
  private func numericParameterList() -> Parsicle<[CGFloat]> {
    return StringParsicle.paramList().map { params in
      params.compactMap { self.numberOrExpressionValue.parse($0).value?.cgFloatValue }
    }
  }
  
  
  // MARK: - Misc
  
  func char(_ char: Character, skipSpaces: Bool = false) -> StringParsicle { return P.char(char, skipSpaces: skipSpaces) }
  
  func charIgnore<Result>(_ char: Character, skipSpaces: Bool = false) -> Parsicle<Result> { return P.char(char, skipSpaces: skipSpaces).ignore() }
  
  func string(_ string: String, skipSpaces: Bool = false) -> StringParsicle { return P.string(string, skipSpaces: skipSpaces) }
  
  func cleanedStringValue(_ string: String) -> String {
    return string.trimQuotes().stringByReplacingUnicodeSequences()
  }
  
  func parseLineUpToInvalidCharacters(in invalid: String) -> StringParsicle {
    let invalidChars = CharacterSet(charactersIn: "\r\n" + invalid)
    return P.stringWithEscapesUp(to: invalidChars)
  }
}

extension NSNumber {
  var cgFloatValue: CGFloat { CGFloat(self.doubleValue) }
}
