//
//  YogaKitAdditions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit
import YogaKit

extension UIView {
  func markYogaViewTreeDirty() {
    yoga.markDirty()
    for sub in subviews {
      sub.markYogaViewTreeDirty()
    }
  }
}

extension YGDirection: StringParsableEnum {
  public typealias AllCases = [YGDirection]
  public static var allCases: YGDirection.AllCases {
    return [.inherit, .LTR, .RTL]
  }
  public var description: String {
    return String(cString: YGDirectionToString(self))
  }
}

extension YGFlexDirection: StringParsableEnum {
  public typealias AllCases = [YGFlexDirection]
  public static var allCases: YGFlexDirection.AllCases {
    return [.column, .columnReverse, .row, .rowReverse]
  }
  public var description: String {
    return String(cString: YGFlexDirectionToString(self))
  }
}

extension YGJustify: StringParsableEnum {
  public typealias AllCases = [YGJustify]
  public static var allCases: YGJustify.AllCases {
    return [.flexStart, .center, .flexEnd, .spaceBetween, .spaceAround, .spaceEvenly]
  }
  public var description: String {
    return String(cString: YGJustifyToString(self))
  }
}

extension YGAlign: StringParsableEnum {
  public typealias AllCases = [YGAlign]
  public static var allCases: YGAlign.AllCases {
    return [.auto, .flexStart, .center, .flexEnd, .stretch, .baseline, .spaceBetween, .spaceAround]
  }
  public var description: String {
    return String(cString: YGAlignToString(self))
  }
}

extension YGPositionType: StringParsableEnum {
  public typealias AllCases = [YGPositionType]
  public static var allCases: YGPositionType.AllCases {
    return [.relative, .absolute]
  }
  public var description: String {
    return String(cString: YGPositionTypeToString(self))
  }
}

extension YGWrap: StringParsableEnum {
  public typealias AllCases = [YGWrap]
  public static var allCases: YGWrap.AllCases {
    return [.noWrap, .wrap, .wrapReverse]
  }
  public var description: String {
    return String(cString: YGWrapToString(self))
  }
}

extension YGOverflow: StringParsableEnum {
  public typealias AllCases = [YGOverflow]
  public static var allCases: YGOverflow.AllCases { return [.visible, .hidden, .scroll] }
  public var description: String { return String(cString: YGOverflowToString(self)) }
}

extension YGDisplay: StringParsableEnum {
  public typealias AllCases = [YGDisplay]
  public static var allCases: YGDisplay.AllCases {
    return [.flex, .none]
  }
  public var description: String {
    return String(cString: YGDisplayToString(self))
  }
}

extension YGValue {
  public init(_ floatValue: CGFloat) {
    self.init(value: Float(floatValue), unit: .point)
  }
  
  public init(_ relativeNumber: RelativeNumber) {
    switch relativeNumber.unit {
      case .percent:
        self.init(value: relativeNumber.rawValue.floatValue, unit: .percent)
      case .auto:
        self.init(value: 0, unit: .auto)
      default:
        self.init(value: relativeNumber.value.floatValue, unit: .point)
    }
  }
}
