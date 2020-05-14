//
//  TransformPropertyParser.swift
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


// Ex: rotate(90) scale(2,2) translate(100,100);
class TransformPropertyParser: BasicPropertyParser<CGAffineTransform> {
  
  init() {
    // Ex: rotate(90) scale(2,2) translate(100,100);
    let rotateValueParser = S.numericParameterString(withPrefix: "rotate").map { values -> CGAffineTransform in
      guard let value = values.first else { return .identity }
      let angle = .pi * value / 180.0
      return CGAffineTransform(rotationAngle: angle)
    }
    let scaleValueParser = S.numericParameterString(withPrefix: "scale").map { values -> CGAffineTransform in
      if values.count == 2 { return CGAffineTransform(scaleX: values[0], y: values[1]) }
      else if values.count == 1 { return CGAffineTransform(scaleX: values[0], y: values[0]) }
      else { return .identity }
    }
    let translateValueParser = S.numericParameterString(withPrefix: "translate").map { values -> CGAffineTransform in
      if values.count == 2 { return CGAffineTransform(translationX: values[0], y: values[1]) }
      else if values.count == 1 { return CGAffineTransform(translationX: values[0], y: values[0]) }
      else { return .identity }
    }
    let transformValuesParser = P.choice([rotateValueParser, scaleValueParser, translateValueParser]).sepBy(.spaces()).map { values -> CGAffineTransform in
      var transform: CGAffineTransform = .identity
      if values.count == 1 {
        transform = values[0]
      } else {
        for transformVal in values {
          transform = transform.concatenating(transformVal)
        }
      }
      return transform
    }
    super.init(parser: transformValuesParser)
  }
}
