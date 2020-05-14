//
//  ImagePropertyParser.swift
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

// Ex: image.png
// Ex: image(image.png);
// Ex: image(image.png, 1, 2);
// Ex: image(image.png, 1, 2, 3, 4);
class ImagePropertyParser: BasicPropertyParser<UIImage> {
  
  class var imageParser: Parsicle<UIImage> {
    return S.parameterString(withPrefix: "image", optionalPrefix: true).map(S.cleanedString).map { v -> UIImage? in
      guard v.count > 0, let image = UIImage(named: v[0]) else { return nil }
      let str = v as [NSString]
      
      if v.count == 5 {
        return image.resizableImage(withCapInsets: UIEdgeInsets(top: CGFloat(str[1].floatValue), left: CGFloat(str[2].floatValue), bottom: CGFloat(str[3].floatValue), right: CGFloat(str[4].floatValue)))
      } else {
        return image
      }
    }
  }
  
  class func imageParsers(_ imageParser: Parsicle<UIImage>, colorValueParsers: [Parsicle<UIColor>]) -> Parsicle<UIImage> {
    let preDefColorParser = S.identifier.map { UIColorPropertyParser.parsePredefColorValue($0) }
    
    // Parse color functions as UIImage
    let colorFunctionParser = UIColorPropertyParser.colorFunctionParser(colorValueParsers, preDefColorParser: preDefColorParser)
    let colorFunctionAsImage = colorFunctionParser.map {
      $0.asUIImage()
    }
    
    // Parses well defined color values (i.e. basicColorValueParsers)
    let colorParser = P.choice(colorValueParsers)
    let colorAsImage = colorParser.map {
      $0.asUIImage()
    }
    
    // Parses an arbitrary text string as an image from file name or pre-defined color name - in that order
    let catchAll = S.cleanedString.map { value -> UIImage? in
      let trimmed = value.trim()
      if let image = UIImage(named: trimmed) {
        return image
      } else if let color = UIColorPropertyParser.parsePredefColorValue(trimmed) {
        return color.asUIImage()
      }
      return nil
    }
    return P.choice([imageParser, colorFunctionAsImage, colorAsImage, catchAll])
  }
  
  init() {
    
    super.init(parser: Self.imageParsers(Self.imageParser, colorValueParsers: UIColorPropertyParser.basicColorValueParsers))
  }
}
