//
//  UIKitPropertyManager.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit

open class UIKitPropertyManager: PropertyManager {
  
  override public init(withStandardProperties: Bool) {
    super.init(withStandardProperties);
    
    if withStandardProperties {
      registerDefaultUIKitProperties()
    }
  }
    
  
  // MARK: - Types
  
  public func canonicalTypeClass(forType type: String) -> AnyClass? {
    var clazz = super.canonicalTypeClass(forType: type);
    if clazz == nil {
      // If type doesn't match a registered class name, try to see if the type is a valid class...
      if let classForName = RuntimeIntrospectionUtils.class(withName: type) {
        // ...and if it is - register it as a canonical type (keep case)
        clazz = classForName
        registerCanonicalTypeClass(classForName)
      }
    }
    return clazz
  }
  
  
  // MARK: - Property lookup
  
  open func findProperty(withNormalizedName normalizedName: String, in clazz: AnyClass) -> Property? {
    var property = super.findProperty(withNormalizedName: normalizedName, in: clazz)
    if property == nil, let superClass = clazz.superclass() {
      let properties = propertiesByType[canonicalType] ?? [:]
      let runtimeProperties = RuntimeIntrospectionUtils.runtimeProperties(for: clazz, excludingRootClasses: [superClass], lowercasedNames: true)
      for (name, runtimeProperty) in runtimeProperties where properties[name] == nil {
        properties[name] = Property(runtimeProperty: runtimeProperty, type: self.runtimeProperty(toPropertyType: runtimeProperty), enumValueMapping: nil)
      }
      propertiesByType[canonicalType] = properties
      property = properties[normalizedName]
    }
    return property
  }
  
  
  // MARK: - Property type mapping
  
  open func runtimeProperty(toPropertyType runtimeProperty: RuntimeProperty) -> PropertyType {
    if let propertyClass = runtimeProperty.propertyClass {
      if let _ = propertyClass as? String.Type {
        return .string
      } else if let _ = propertyClass as? UIFont.Type {
        return .font
      } else if let _ = propertyClass as? UIImage.Type {
        return .image
      } else if let _ = propertyClass as? UIColor.Type {
        return .color
      }
    } else if runtimeProperty.isBooleanType {
      return .bool
    } else if runtimeProperty.isNumericType {
      return .number
    } else if runtimeProperty.isType(ISSCGColorTypeId) {
      return .cgColor
    } else if runtimeProperty.isType(ISSCGRectTypeId) {
      return .rect
    } else if runtimeProperty.isType(ISSCGPointTypeId) {
      return .point
    } else if runtimeProperty.isType(ISSUIEdgeInsetsTypeId) {
      return .edgeInsets
    } else if runtimeProperty.isType(ISSUIOffsetTypeId) {
      return .offset
    } else if runtimeProperty.isType(ISSCGSizeTypeId) {
      return .size
    } else if runtimeProperty.isType(ISSCGAffineTransformTypeId) {
      return .transform
    }
    return .unknown
  }
}
