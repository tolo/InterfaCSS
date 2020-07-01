//
//  StringParsableEnum.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

public protocol StringParsableEnum: RawRepresentable, CaseIterable, CustomStringConvertible /*where Self.AllCases == [Self]*/ {
  static var defaultEnumValue: Self { get }
  static func enumValue(from string: String) -> Self?
}

public extension StringParsableEnum {
  static var defaultEnumValue: Self {
    return allCases.first!
  }

  static func enumValue(from string: String) -> Self? {
    return allCases.first {
      $0.description.caseInsensitiveCompare(string) == .orderedSame
    }
  }

  static func enumValueWithDefault(from string: String) -> Self {
    return enumValue(from: string) ?? defaultEnumValue
  }

  static func switchOn(_ string: String, switchFunc: (Self) -> Void) {
    guard let value = enumValue(from: string) else { return }
    switchFunc(value)
  }
}

public extension StringParsableEnum where RawValue: ExpressibleByStringLiteral {
  var description: String {
    return String(describing: rawValue)
  }
}

public extension StringParsableEnum where RawValue == String {
  var description: String { rawValue }
}
