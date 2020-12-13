//
//  BorderPropertyParser.swift
//  InterfaCSS
//
//  Created by Tobias on 2020-11-30.
//  Copyright © 2020 Leafnode AB. All rights reserved.
//

import UIKit
import Parsicle


public struct Border {
  let width: CGFloat
  let color: UIColor
}


class BorderPropertyParser: BasicPropertyParser<Border> {
  
  static let borderParser: Parsicle<Border> = {
    NumberPropertyParser().parser.then(UIColorPropertyParser().parser).map { result -> Border in
      let (width, color) = result
      return Border(width: width.cgFloatValue, color: color)
    }
  }()
  
  init() {
    super.init(parser: Self.borderParser)
  }
}
