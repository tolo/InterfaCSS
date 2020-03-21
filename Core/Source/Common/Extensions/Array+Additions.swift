//
//  NSArray+Additions.swift
//  InterfaCSS-Core
//
//  Created by Tobias on 2019-02-12.
//  Copyright © 2019 Leafnode AB. All rights reserved.
//

import Foundation

extension Array where Element == String {
  public func trimStringElements() -> [String] {
    var trimmed: [String] = []
    for e in self {
      trimmed.append(e.trim())
    }
    return trimmed
  }
}

extension Array {
  public func compactFlattened<Result>() -> [Result] {
    return compactAndFlattenArray(self)
  }
}

extension Array where Element: Equatable {
  public mutating func addAndReplaceUniqueObjects(inArray array: [Element]) {
    removeAll { array.contains($0) }
    append(contentsOf: array)
  }
}

public func compactAndFlattenArray<Result>(_ array: [Any]) -> [Result] {
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
