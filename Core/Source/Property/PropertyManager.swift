//
//  PropertyManager.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit


/**
 * The property registry keeps track on all properties that can be set through stylesheets.
 */
open class PropertyManager {
  
  let logger = Logger.properties
  
  /// Dependencies
  public weak var styleSheetManager: StyleSheetManager!
    
  let propertyRepository: PropertyRepository
  
  
  // MARK: - initialization - setup of properties
  
  convenience init() {
    self.init(withDefaultProperties: true)
  }
  
  public init(withDefaultProperties: Bool) {
    propertyRepository = PropertyRepository(withDefaultProperties: withDefaultProperties)
  }
  
  
  // MARK: - Type utility methods
  
  public static func classNamed(_ className: String) -> AnyClass? {
    var clazz: AnyClass? = NSClassFromString(className)
    if( clazz == nil ) { // If direct match not found, check if it's a Swift class name
      let bundles = [Bundle.main] + Bundle.allBundles
      for bundle in bundles where clazz == nil {
        guard let bundleName = bundle.infoDictionary?[kCFBundleNameKey as String] as? String else { continue }
        clazz = NSClassFromString("\(bundleName).\(className)")
      }
    }
    return clazz
  }
    
  public static func doesPropertyExist(_ propertyName: String, in object: AnyObject) -> Bool {
    return RuntimeIntrospectionUtils.validKeyPath(forCaseInsensitivePath: propertyName, in: type(of: object)) != nil
  }
  
  
  // MARK: - Types
  
  /**
   * Returns the canonical type class for the given class, i.e. the closest super class that represents a valid type selector. For instance, for all `UIView`
   * subclasses, this would by default be `UIView`.
   */
  open func canonicalTypeClass(for clazz: AnyClass) -> AnyClass? {
    return propertyRepository.canonicalTypeClass(for: clazz)
  }
  
  open func canonicalType(for clazz: AnyClass) -> String? {
    return propertyRepository.canonicalType(for: clazz)
  }
  
  open func canonicalTypeClass(forType type: String, registerIfNotFound: Bool = false) -> AnyClass? {
    return propertyRepository.canonicalTypeClass(forType: type, registerIfNotFound: registerIfNotFound)
  }
  
  /**
   * Registers a class for use as a valid type selector in stylesheets. Note: this happens automatically whenever an unknown, but valid, class name is encountered
   * in a type selector in a stylesheet. This method exist to be able to register all custom canonical type classes before stylesheet parsing occurs, and to also
   * enable case-insensitive matching of type name -> class.
   *
   * @see canonicalTypeClassForClass:
   */
  @discardableResult
  open func registerCanonicalTypeClass(_ clazz: AnyClass) -> String {
    return propertyRepository.registerCanonicalTypeClass(clazz)
  }
  
  
  // MARK: - Property lookup
  
  open func findProperty(withName name: String, in clazz: AnyClass) -> Property? {
    let normalizedName = Property.normalizeName(name)
    return findProperty(withNormalizedName: normalizedName, in: clazz)
  }
  
  func findProperty(withNormalizedName normalizedName: String, in clazz: AnyClass) -> Property? {
    return propertyRepository.findProperty(withNormalizedName: normalizedName, in: clazz)
  }
  
  
  // MARK: - Property registration
  
  /**
   * Registers a custom property.
   */
  //open func register(_ property: Property, in clazz: AnyClass, replaceExisting: Bool = true) -> Property {
  open func register(_ property: Property, replaceExisting: Bool = true) -> Property {
    return propertyRepository.register(property, replaceExisting: replaceExisting)
  }
  
  
  // MARK: - Property application
  
  open func preProcess(propertyValues: [PropertyValue], styleSheetScope scope: StyleSheetScope) -> [PropertyValue] {
    // Replace variable references in values and paramerters
    var propertyValues = propertyValues.map { p -> PropertyValue in
      guard let propertyRawValueInitial = p.rawValue else { return p }
      var containsVariables = false
      let propertyRawValue = styleSheetManager.replaceVariableReferences(propertyRawValueInitial, scope: scope, didReplace: &containsVariables)
      let rawParams = p.rawParameters?.map { styleSheetManager.replaceVariableReferences($0, scope: scope, didReplace: &containsVariables) }
      return p.copyWith(value: propertyRawValue, parameters: rawParams)
    }
    
    // Sort array to separate compound properties from regular properties
    let i = propertyValues.partition {
      propertyRepository.compoundProperties.keys.contains($0.propertyName)
    }
    var remainingCompoundPropertyValues = Array(propertyValues[i...])
    let standardPropertyValues = propertyValues[..<i]
    
    // Process compound properties
    let matchingCompoundProperties = remainingCompoundPropertyValues.compactMap{ propertyRepository.compoundProperties[$0.propertyName] }.toSet()
    var processedCompoundPropertyValues: [PropertyValue] = []
    matchingCompoundProperties.forEach { c in
      if let match = c.process(propertyValues: &remainingCompoundPropertyValues) {
        processedCompoundPropertyValues.append(match)
      }
    }
    
    return standardPropertyValues + processedCompoundPropertyValues + remainingCompoundPropertyValues
  }
  
  @discardableResult
  open func apply(_ propertyValue: PropertyValue, onTarget targetElement: ElementStyle, styleSheetScope scope: StyleSheetScope) -> Bool {
    guard let element = targetElement.uiElement else { return false }
    if propertyValue.useCurrentValue {
      logger.trace("Property value not changed - using existing value for '\(propertyValue.description)' in '\(targetElement)'")
      return true
    }
    
    guard let property = findProperty(withName: propertyValue.propertyName, in: type(of: element)) else {
      logger.trace("Cannot apply property value to '\(targetElement)' - unknown property (\(propertyValue))!")
      return false
    }
    
    // Transform value
    guard let value = property.transform(value: propertyValue) else {
      logger.trace("Cannot apply property value to '\(property.fqn)' in '\(targetElement)' - value is nil!")
      return false
    }
    
    // Transform parameters
    var params: [Any]?
    if let rawParameters = propertyValue.rawParameters {
      params = property.transform(parameters: rawParameters)
    }
  
    let result = property.setValue(value, onTarget: element, withParameters: params)
    if result {
      logger.trace("Applied property value \(propertyValue.rawValue ?? "") to '\(property.fqn)' in '\(targetElement)'")
    } else {
      logger.trace("Unable to apply property value to '\(property.fqn)' in '\(targetElement)'!")
    }
    return result
  }
}
