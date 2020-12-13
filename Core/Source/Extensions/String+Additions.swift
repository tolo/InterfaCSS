//
//  String+Additions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

fileprivate let splitOnSpaceOrCommaCharacterSet: CharacterSet = CharacterSet(charactersIn: " ,")


internal extension String.StringInterpolation {
  mutating func appendInterpolation<T>(describing value: T?) {
    if let value = value {
      appendInterpolation(value)
    } else {
      appendLiteral("nil")
    }
  }
}


infix operator ^= : ComparisonPrecedence

/// caseInsensitiveCompare operator ^=
internal func ^=(lhs: String, rhs: String) -> Bool {
  return lhs.caseInsensitiveCompare(rhs) == .orderedSame
}


internal extension StringProtocol where Self.Index == String.Index {
  
  var str: String {
    if let s = self as? String { return s }
    else { return String(self) }
  }
  
  func isEmpty() -> Bool {
    return trim().count == 0
  }
  
  func hasData() -> Bool {
    return trim().count > 0
  }
  
  func trim() -> String {
    return trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
  }
  
  func trimQuotes() -> String {
    return trim().trimmingCharacters(in: CharacterSet(charactersIn: "\"\'"))
  }
  
  func trimmedSplit(_ sep: String) -> [String] {
    return components(separatedBy: sep).map { $0.trim() }
  }
  
  func trimmedSplit(with characterSet: CharacterSet) -> [String] {
    return components(separatedBy: characterSet).map { $0.trim() }
  }
  
  func splitOnSpaceOrComma() -> [String] {
    return components(separatedBy: splitOnSpaceOrCommaCharacterSet).filter { $0.hasData() }
  }
  
  func isNumeric() -> Bool {
    return self.range(of: "^(?:|0|[1-9]\\d*)(?:\\.\\d*)?$", options: .regularExpression) != nil
  }
  
  func index(_ offsetBy: Int) -> Self.Index {
    return index(startIndex, offsetBy: offsetBy)
  }
  
  func index(ofChar char: Character, from intIndex: Int) -> Int {
    guard let stringIndex = self[range(from: intIndex)].firstIndex(of: char) else { return NSNotFound }
    return index(ofIndex: stringIndex)
  }
  
  func index(ofString string: String, from intIndex: Int) -> Int {
    guard let stringIndex = rangeOf(string, from: intIndex)?.lowerBound else { return NSNotFound }
    return index(ofIndex: stringIndex)
  }
  
  func index(ofCharInSet charset: CharacterSet, from intIndex: Int) -> Int {
    guard let stringIndex = self[range(from: intIndex)].rangeOfCharacter(from: charset)?.lowerBound else { return NSNotFound }
    return index(ofIndex: stringIndex)
  }
  
  func index(ofIndex index: String.Index) -> Int {
    return distance(from: startIndex, to: index)
  }
  
  func charAt(index charIndex: Int, matches set: CharacterSet) -> Bool {
    let i = index(charIndex)
    return rangeOfCharacter(from: set, options: [], range: i..<index(after: i))?.lowerBound == i
  }
  
  func charAt(index charIndex: Int) -> Character {
    return self[index(startIndex, offsetBy: charIndex)]
  }
  
  func deletingPrefix(_ prefix: String) -> Self.SubSequence {
    guard self.hasPrefix(prefix) else { return self[startIndex...] }
    return self.dropFirst(prefix.count)
  }
  
  func extractPrefix(withCharactersIn charset: CharacterSet) -> Self.SubSequence? {
    if let range = rangeOfCharacter(from: charset.inverted) {
      if range.lowerBound != startIndex { return self[startIndex ..< range.lowerBound] } // If first char not in char set is larger than startIndex...
      else { return nil }
    } else {
      return self[startIndex...]
    }
  }
  
  func rangeOf(_ string: String, options: String.CompareOptions = [], from index: Int = 0) -> Range<Self.Index>? {
    return range(of: string, options: options, range: range(from: index))
  }
  
  func range(from index: Int) -> Range<Self.Index> {
    return self.index(startIndex, offsetBy: index) ..< endIndex
  }
  
  func range(from: Int, to: Int) -> Range<Self.Index> {
    guard to <= count else { return startIndex..<endIndex }
    return index(startIndex, offsetBy: from) ..< index(startIndex, offsetBy: to)
  }
  
  func substring(from: Int, to: Int) -> Self.SubSequence {
    return self[range(from: from, to: to)]
  }
  
  func substring(from: Int) -> Self.SubSequence {
    return self[range(from: from)]
  }
  
  func replaceCharacterAt(index: Int, length: Int = 1, with string: Self) -> String {
    return replaceCharacterInRange(from: index, to: index + length, with: string)
  }
  
  func replaceCharacterInRange(from: Int, to: Int, with string: Self) -> String {
    let range = index(startIndex, offsetBy: from) ..< index(startIndex, offsetBy: to)
    return replacingCharacters(in: range, with: string)
  }
  
  subscript(index: Int) -> Character {
    return charAt(index: index)
  }
}


internal extension Optional where Wrapped == String {
  func asSet() -> Set<String>? {
    if let self = self {
      return Set([self])
    }
    return nil
  }
  
  func asArray() -> Array<String>? {
    if let self = self {
      return [self]
    }
    return nil
  }
}


internal extension String {
  
  func isCaseInsensitiveEqual(_ otherString: String) -> Bool {
    return self ^= otherString
  }
  
  func isCaseInsensitiveEqual(_ otherString: String, withOptionalPrefix prefix: String) -> Bool {
    if isCaseInsensitiveEqual(otherString) { return true }
    return (prefix + self).isCaseInsensitiveEqual(otherString)
  }
  
  func stringByReplacingUnicodeSequences() -> String {
    var location: String.Index = startIndex
    var result = self
    while location < result.endIndex {
      // Scan for \u or \U
      guard let uRange = result.range(of: "\\u", options: .caseInsensitive, range: location ..< result.endIndex) else {
        break
      }
      
      // Set expected length to 4 for \u and 8 for \U
      let replaceRange: Range<String.Index>
      if result[result.index(uRange.lowerBound, offsetBy: 1)] == "u" {
        replaceRange = uRange.lowerBound ..< result.index(uRange.upperBound, offsetBy: 4)
      } else {
        replaceRange = uRange.lowerBound ..< result.index(uRange.upperBound, offsetBy: 8)
      }
      // Attempt parsing of unicode char
      if replaceRange.upperBound <= result.endIndex {
        if let unicode = String(result[replaceRange]).unicodeCharacterStringFromSequenceString() {
          result = result.replacingCharacters(in: replaceRange, with: unicode)
          location = replaceRange.upperBound
        } else {
          location = result.index(location, offsetBy: 2)
        }
      } else {
        break
      }
    }
    return result
  }
  
  func unicodeCharacterStringFromSequenceString() -> String? {
    let unicodeChar: UTF32Char = unicodeCharacterFromSequenceString()
    if unicodeChar == UINT32_MAX {
      return nil
    } else {
      return String.string(from: unicodeChar)
    }
  }
  
  func unicodeCharacterFromSequenceString() -> UTF32Char {
    // Remove prefix
    var hexString = self
    while hexString.hasPrefix("\\") {
      hexString = String(hexString[hexString.index(hexString.startIndex, offsetBy: 1)...])
    }
    if hexString.hasPrefix("U") || hexString.hasPrefix("u") {
      hexString = String(hexString[hexString.index(hexString.startIndex, offsetBy: 1)...])
    }
    // Scan UTF32Char
    var unicodeChar: UTF32Char = 0
    let scanner = Scanner(string: hexString)
    if scanner.scanHexInt32(&unicodeChar) {
      return unicodeChar
    } else {
      return UINT32_MAX
    }
  }
  
  static func string(from input: UTF32Char) -> String {
    var unicodeChar = input
    if (Int64(unicodeChar) & 0xffff0000) != 0 {
      unicodeChar -= 0x10000
      var highSurrogate = unichar(unicodeChar >> 10) // use top ten bits
      highSurrogate += unichar(0xd800)
      var lowSurrogate = unichar(unicodeChar & 0x3ff) // use low ten bits
      lowSurrogate += unichar(0xdc00)
      return NSString(characters: [highSurrogate, lowSurrogate], length: 2) as String
    } else {
      return NSString(characters: [unichar(input)], length: 1) as String
    }
  }
}


internal extension Character {
  var toInt: UInt32 {
    return unicodeScalars.first?.value ?? 0
  }
}

internal extension CharacterSet {
  func containsUnicodeScalars(of member: Character) -> Bool {
    return member.unicodeScalars.allSatisfy(contains(_:))
  }
}
