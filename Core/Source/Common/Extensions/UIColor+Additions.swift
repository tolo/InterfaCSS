//
//  UIColor+Additions.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation
import UIKit

public extension UIColor {
  convenience init(r red: Int, g green: Int, b blue: Int, a alpha: CGFloat = 1) {
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
  }
  
  convenience init?(fromHexString hexValue: String) {
    let hex = hexValue.trim()
    let withAlpha: Bool = hex.count == 4 || hex.count == 8
    let compact: Bool = hex.count == 3 || hex.count == 4
    
    if hex.count == 6 || compact || withAlpha {
      let scanner = Scanner(string: hex)
      var cc: UInt32 = 0
      let alphaOffset: UInt32 = withAlpha ? (compact ? 4 : 8) : 0
      let chanelOffset: UInt32 = compact ? 4 : 8
      let mask: UInt32 = compact ? 0x0f : 0xff
      let multiplier: UInt32 = 0xff / mask
      
      if scanner.scanHexInt32(&cc) {
        let r = Int(((cc >> (2 * chanelOffset + alphaOffset)) & mask) * multiplier)
        let g = Int(((cc >> (chanelOffset + alphaOffset)) & mask) * multiplier)
        let b = Int(((cc >> alphaOffset) & mask) * multiplier)
        if withAlpha {
          let a = CGFloat((cc & mask)) / CGFloat(mask)
          self.init(r: r, g: g, b: b, a: a)
        } else {
          self.init(r: r, g: g, b: b)
        }
      } else { return nil }
    } else { return nil }
  }
  
  class func fromHexString(_ hexValue: String) -> UIColor {
    return UIColor(fromHexString: hexValue) ?? UIColor.magenta
  }
  
  func rgbaComponents() -> [CGFloat] {
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    if !getRed(&r, green: &g, blue: &b, alpha: &a) {
      if getWhite(&r, alpha: &a) {
        // Grayscale
        return [r, r, r, a]
      }
    }
    return [r, g, b, a]
  }
  
  func adjustBrightness(by amount: CGFloat) -> UIColor {
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
      // RGB or HSB
      b = adjustWithAbsoluteAmount(b, amount)
      return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
    } else if getWhite(&b, alpha: &a) {
      // Grayscale
      b = adjustWithAbsoluteAmount(b, amount)
      return UIColor(white: b, alpha: a)
    } else {
      return self
    }
  }
  
  func adjustSaturation(by amount: CGFloat) -> UIColor {
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
      // RGB or HSB
      s = adjustWithAbsoluteAmount(s, amount)
      return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
    } else {
      return self
    }
  }
  
  func adjustAlpha(by amount: CGFloat) -> UIColor {
    var h: CGFloat = 0
    var s: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    if getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
      // RGB or HSB
      a = adjustWithAbsoluteAmount(a, amount)
      return UIColor(hue: h, saturation: s, brightness: b, alpha: a)
    } else if getWhite(&b, alpha: &a) {
      // Grayscale
      a = adjustWithAbsoluteAmount(a, amount)
      return UIColor(white: b, alpha: a)
    } else {
      return self
    }
  }
  
  class func color(asUIImage color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
    return UIGraphicsImageRenderer(size: size).image { rendererContext in
      color.setFill()
      rendererContext.fill(CGRect(origin: .zero, size: size))
    }
  }
  
  func asUIImage() -> UIImage? {
    return UIColor.color(asUIImage: self)
  }
  
  func topDownLinearGradientImage(to color: UIColor, height: CGFloat) -> UIImage? {
    guard let context = UIGraphicsGetCurrentContext() else { return nil }
    
    let size = CGSize(width: 1, height: height)
    
    UIGraphicsBeginImageContextWithOptions(size, _: false, _: 0)
    
    let locations: [CGFloat] = [0.0, 1.0]
    var components = [CGFloat](repeating: 0.0, count: 8)
    var colorComponents = rgbaComponents()
    for i in 0..<colorComponents.count {
      components[i] = colorComponents[i]
    }
    colorComponents = color.rgbaComponents()
    for i in 0..<colorComponents.count {
      components[i + 4] = colorComponents[i]
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let gradient = CGGradient(colorSpace: colorSpace, colorComponents: components, locations: locations, count: 2) else {
      return nil
    }
    
    context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
  }
  
  func topDownLinearGradient(to color: UIColor, height: CGFloat) -> UIColor? {
    let image = topDownLinearGradientImage(to: color, height: height)
    if let image = image {
      return UIColor(patternImage: image)
    } else {
      return nil
    }
  }
}

@inline(__always) private func adjustWithAbsoluteAmount(_ value: CGFloat, _ adjustAmount: CGFloat) -> CGFloat {
  return min(max(0.0, value + value * adjustAmount / 100.0), 1.0)
}
