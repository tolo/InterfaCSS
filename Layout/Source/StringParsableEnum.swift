//
//  StringParsableEnum.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

protocol StringParsableEnum: CaseIterable, CustomStringConvertible /*where Self.AllCases == [Self]*/ {
  static var defaultEnumValue: Self { get }
  static func enumValue(from string: String) -> Self?
}

extension StringParsableEnum {
  public static var defaultEnumValue: Self {
    return allCases.first!
  }

  public static func enumValue(from string: String) -> Self? {
    return allCases.first {
      $0.description.caseInsensitiveCompare(string) == .orderedSame
    }
  }

  public static func enumValueWithDefault(from string: String) -> Self {
    return enumValue(from: string) ?? defaultEnumValue
  }

  public static func switchOn(_ string: String, switchFunc: (Self) -> Void) {
    guard let value = enumValue(from: string) else { return }
    switchFunc(value)
  }
}
