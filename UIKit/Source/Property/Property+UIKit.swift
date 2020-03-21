//
//  Property+UIKit.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import Foundation

extension Property {
  public convenience init(runtimeProperty: RuntimeProperty, type: PropertyType, enumValueMapping: AnyPropertyEnumValueMappingType? = nil) {
    self.init(withName: runtimeProperty.propertyName, in: runtimeProperty.foundInClass, type: type, enumValueMapping: enumValueMapping, parameterTransformers: nil, setterBlock: { property, target, value, parameters in
      var propertyValue: Any = value ?? NSNull()
      if let mapping = enumValueMapping, let val = value as? String {
        propertyValue = mapping.value(from: val)
      }
      return RuntimeIntrospectionUtils.invokeSetter(for: runtimeProperty, withValue: propertyValue, in: target)
    })
  }
  
  public convenience init(withName name: String, in clazz: AnyClass, type: PropertyType, selector: Foundation.Selector, enumValueMapping: AnyPropertyEnumValueMappingType? = nil, parameterTransformers: [PropertyParameterTransformer]? = nil) {
    self.init(withName: name, in: clazz, type: type, enumValueMapping: enumValueMapping, parameterTransformers: parameterTransformers, setterBlock: { property, target, value, parameters in
      let arguments = [value ?? NSNull()] + parameters
      RuntimeIntrospectionUtils.invokeInstanceSelector(selector, withArguments: arguments, in: target)
      return true
    })
  }
}
