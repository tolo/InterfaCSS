//
//  Hasher+Additions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

internal extension Hasher {
  mutating func combine<H1: Hashable, H2: Hashable>(_ h1: H1, _ h2: H2) {
    combineAll(AnyHashable(h1), AnyHashable(h2))
  }
  mutating func combine<H1: Hashable, H2: Hashable, H3: Hashable>(_ h1: H1, _ h2: H2, _ h3: H3) {
    combineAll(AnyHashable(h1), AnyHashable(h2), AnyHashable(h3))
  }
  mutating func combine<H1: Hashable, H2: Hashable, H3: Hashable, H4: Hashable>(_ h1: H1, _ h2: H2, _ h3: H3, _ h4: H4) {
    combineAll(AnyHashable(h1), AnyHashable(h2), AnyHashable(h3), AnyHashable(h4))
  }
  mutating func combine<H1: Hashable, H2: Hashable, H3: Hashable, H4: Hashable, H5: Hashable>(_ h1: H1, _ h2: H2, _ h3: H3, _ h4: H4, _ h5: H5) {
    combineAll(AnyHashable(h1), AnyHashable(h2), AnyHashable(h3), AnyHashable(h4), AnyHashable(h5))
  }
  mutating func combineAll<H: Hashable>(_ hashables: H...) {
    for h in hashables {
      combine(h)
    }
  }
}
