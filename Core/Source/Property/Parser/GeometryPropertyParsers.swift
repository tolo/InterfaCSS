//
//  GeometryPropertyParsers.swift
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


class CGRectPropertyParser: BasicPropertyParser<CGRect> {
  init() {
    let rectValueParser = S.numericParameterString(withPrefix: "rect", optionalPrefix: true).map { c -> CGRect in
      guard c.count == 4 else { return .zero }
      return CGRect(x: c[0], y: c[1], width: c[2], height: c[3])
    }
    let cgRectFromStringParser = S.cleanedString.map { NSCoder.cgRect(for: $0) }
    let parser = P.choice([rectValueParser, cgRectFromStringParser])
    super.init(parser: parser)
  }
}

class UIOffsetPropertyParser: BasicPropertyParser<UIOffset> {
  init() {
    let offsetValueParser = S.numericParameterString(withPrefix: "offset", optionalPrefix: true).map { c -> UIOffset in
      if c.count == 2 { return UIOffset(horizontal: c[0], vertical: c[1]) }
      else if c.count == 1 { return UIOffset(horizontal: c[0], vertical: c[0]) }
      return .zero
    }
    let uiOffsetFromStringParser = S.cleanedString.map { NSCoder.uiOffset(for: $0) }
    let parser = P.choice([offsetValueParser, uiOffsetFromStringParser])
    super.init(parser: parser)
  }
}

class CGSizePropertyParser: BasicPropertyParser<CGSize> {
  init() {
    let sizeValueParser = S.numericParameterString(withPrefix: "size", optionalPrefix: true).map { c -> CGSize in
      if c.count == 2 { return CGSize(width: c[0], height: c[1]) }
      else if c.count == 1 { return CGSize(width: c[0], height: c[0]) }
      return .zero
    }
    let cgSizeFromStringParser = S.cleanedString.map { NSCoder.cgSize(for: $0) }
    let parser = P.choice([sizeValueParser, cgSizeFromStringParser])
    super.init(parser: parser)
  }
}

class CGPointPropertyParser: BasicPropertyParser<CGPoint> {
  init() {
    let pointValueParser = S.numericParameterString(withPrefix: "point", optionalPrefix: true).map { c -> CGPoint in
      if c.count == 2 { return CGPoint(x: c[0], y: c[1]) }
      else if c.count == 1 { return CGPoint(x: c[0], y: c[0]) }
      return .zero
    }
    let cgPointFromStringParser = S.cleanedString.map { NSCoder.cgPoint(for: $0) }
    let parser = P.choice([pointValueParser, cgPointFromStringParser])
    super.init(parser: parser)
  }
}

class UIEdgeInsetsPropertyParser: BasicPropertyParser<UIEdgeInsets> {
  init() {
    let insetsValueParser = S.numericParameterString(withPrefix: "insets", optionalPrefix: true).map { c -> UIEdgeInsets in
      if c.count == 4 { return UIEdgeInsets(top: c[0], left: c[1], bottom: c[2], right: c[3]) }
      else if c.count == 2 { return UIEdgeInsets(top: c[0], left: c[1], bottom: c[0], right: c[1]) }
      else if c.count == 1 { return UIEdgeInsets(top: c[0], left: c[0], bottom: c[0], right: c[0]) }
      return .zero
    }
    let uiEdgeInsetsFromStringParser = S.cleanedString.map { NSCoder.uiEdgeInsets(for: $0) }
    let parser = P.choice([insetsValueParser, uiEdgeInsetsFromStringParser])
    super.init(parser: parser)
  }
}
