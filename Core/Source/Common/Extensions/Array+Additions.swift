//
//  NSArray+Additions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

internal extension Array where Element == String {
  func trimStringElements() -> [String] {
    var trimmed: [String] = []
    for e in self {
      trimmed.append(e.trim())
    }
    return trimmed
  }
}

internal extension Array where Element: Hashable {
  func toSet() -> Set<Element> {
    return Set(self)
  }
}

internal extension Array {
  func compactFlattened<Result>() -> [Result] {
    return compactAndFlattenArray(self)
  }
}

internal extension Array where Element: Equatable {
  mutating func addAndReplaceUniqueObjects(inArray array: [Element]) {
    removeAll { array.contains($0) }
    append(contentsOf: array)
  }
}

internal func compactAndFlattenArray<Result>(_ array: [Any]) -> [Result] {
  var flattened: [Result] = []
  for e in array.compactMap({ $0 }) {
    if let e = e as? [Any] {
      flattened.append(contentsOf: compactAndFlattenArray(e))
    } else if let r = e as? Result {
      flattened.append(r)
    }
  }
  return flattened
}
