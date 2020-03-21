//
//  PropertyManager.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

import UIKit

typealias PropertyValueAndParametersTuple = (propertyValue: Any, propertyParameters: [Any]?)

private func canonicalClassName(_ clazz: AnyClass) -> String {
  return String(describing: clazz).lowercased()
}

class CompoundProperty {
  
  final let properties: [Property]
  
  public init(properties: [Property]) {
    self.properties = properties
  }
  
  func process(propertyValues: [PropertyValue]) -> [PropertyValue] {
    
  }
}

/**
 * The property registry keeps track on all properties that can be set through stylesheets.
 */
open class PropertyManager {
  
  let logger = Logger.properties
  
  public weak var stylingManager: StylingManager? // TODO: Review if this dependency can be removed
  
  var compoundProperties: [String: CompoundProperty] = [:]
  
  var propertiesByType: [String: [String: Property]] = [:]
  var typeNamesToClasses: [String: AnyClass] = [:]
  var cachedTransformedProperties: [String : PropertyValueAndParametersTuple] = [:]
  
  
  // MARK: - initialization - setup of properties
  
  convenience init() {
    self.init(withStandardProperties: true)
  }
  
  public init(withStandardProperties: Bool) {
    var validTypeClasses = [ CALayer.self, UIWindow.self, UIView.self, UIImageView.self, UIScrollView.self, UITableView.self,
                             UITableViewCell.self, UICollectionView.self, UINavigationBar.self, UISearchBar.self, UIBarButtonItem.self,
                             UITabBar.self, UITabBarItem.self, UIControl.self, UIActivityIndicatorView.self, UIButton.self,
                             UILabel.self, UIProgressView.self, UISegmentedControl.self, UITextField.self, UITextView.self]
    if #available(iOS 9.0, *) { // iOS-only view classes
      validTypeClasses += [UIToolbar.self, UISlider.self, UIStepper.self, UISwitch.self]
    }
    // Extend the default set of valid type classes with a few common view controller classes
    validTypeClasses += [UIViewController.self, UINavigationController.self, UITabBarController.self, UIPageViewController.self, UITableViewController.self, UICollectionViewController.self]
    
    for clazz in validTypeClasses {
      let typeName = canonicalClassName(clazz)
      typeNamesToClasses[typeName] = clazz
    }
    
    if withStandardProperties {
      registerDefaultCSSProperties()
    }
  }
  
  
  // MARK: - Type utility methods
  
  final func classNamed(_ className: String) -> AnyClass? {
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
  
  final func validProperty(_ propertyName: String, in object: AnyObject) -> String? {
    let mirror = Mirror(reflecting: object)
    for child in mirror.children {
      guard let label = child.label else { continue }
      if label ==⇧ propertyName { return label }
    }
    return nil
  }
  
  final func doesPropertyExist(_ propertyName: String, in object: AnyObject) -> Bool {
    return validProperty(propertyName, in: object) != nil
  }
  
  
  // MARK: - Types
  
  /**
   * Returns the canonical type class for the given class, i.e. the closest super class that represents a valid type selector. For instance, for all `UIView`
   * subclasses, this would by default be `UIView`.
   */
  open func canonicalTypeClass(for clazz: AnyClass) -> AnyClass? {
    //if classesToTypeNames[clazz] != nil {
    if typeNamesToClasses[canonicalClassName(clazz)] != nil {
      return clazz
    } else {
      // Custom view class or "unsupported" UIKit view class
      let superClass: AnyClass? = clazz.superclass()
      if let superClass = superClass, superClass != NSObject.self {
        return canonicalTypeClass(for: superClass)
      } else {
        return nil
      }
    }
  }
  
  open func canonicalType(for clazz: AnyClass) -> String? {
    let className = canonicalClassName(clazz)
    if typeNamesToClasses[className] != nil {
      return className
    } else {
      // Custom view class or "unsupported" UIKit view class
      let superClass: AnyClass? = clazz.superclass()
      if let superClass = superClass, superClass != NSObject.self {
        return canonicalType(for: superClass)
      } else {
        return nil
      }
    }
  }
  
  open func canonicalTypeClass(forType type: String) -> AnyClass? {
    var uiKitClassName = type.lowercased()
    if !uiKitClassName.hasPrefix("ui") {
      uiKitClassName = "ui" + uiKitClassName
    }
    var clazz: AnyClass? = typeNamesToClasses[uiKitClassName]
    if clazz == nil {
      clazz = typeNamesToClasses[type.lowercased()] // If not UIKit class - see if it is a custom class (typeNamesToClasses always uses lowecase keys)
    }
    return clazz
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
    let type = canonicalClassName(clazz)
    if typeNamesToClasses[type] != nil { return type } // Already registered
    
    typeNamesToClasses[type] = clazz
    
    // Reset all cached data ElementStyle, since canonical type class may have changed for some elements
    ElementStyle.markAllCachedStylingInformationAsDirty()
    return type
  }
  
  
  // MARK: - Property lookup
  
  open func findProperty(withName name: String, in clazz: AnyClass) -> Property? {
    let normalizedName = Property.normalizeName(name)
    return findProperty(withNormalizedName: normalizedName, in: clazz)
  }
  
  open func findProperty(withNormalizedName normalizedName: String, in clazz: AnyClass) -> Property? {
    guard let canonicalType = self.canonicalType(for: clazz) else { return nil }
    
    let properties = propertiesByType[canonicalType] ?? [:]
    var property = properties[normalizedName]
    if property == nil {
      // Search in super class
      let superClass: AnyClass? = clazz.superclass()
      if let superClass = superClass, superClass != NSObject.self {
        property = findProperty(withNormalizedName: normalizedName, in: superClass)
      }
    }
    return property
  }
  
  
  // MARK: - Property registration
  
  /**
   * Registers a custom property.
   */
  open func register(_ property: Property, in clazz: AnyClass, replaceExisting: Bool = true) -> Property {
    let normalizedName = property.normalizedName
    let typeName = registerCanonicalTypeClass(clazz) // Register canonical type, if needed
    if var properties = propertiesByType[typeName] {
      if !replaceExisting, let existing = findProperty(withName: normalizedName, in: clazz) {
        return existing
      }
      properties[normalizedName] = property
      propertiesByType[typeName] = properties
    } else {
      propertiesByType[typeName] = [normalizedName: property]
    }
    return property
  }
  
  
  // MARK: - Property application
  
  func preProcess(propertyValues: [PropertyValue]) -> [PropertyValue] {
    var propertyValues = propertyValues
    let i = propertyValues.partition {
      compoundProperties.keys.contains(Property.normalizeName($0.propertyName))
    }
    let compoundPropertyValues = propertyValues[i...]
    let remainingPropertyValues = propertyValues[..<i]
    
    // TODO
  }
  
  
  // TODO: Use this
  func getValue(for propertyValue: PropertyValue, onTarget targetElement: ElementStyle, styleSheetScope scope: StyleSheetScope) -> PropertyValueAndParametersTuple? {
    guard let element = targetElement.uiElement else { return nil }
    
    guard let propertyRawValue = propertyValue.rawValue, let property = findProperty(withName: propertyValue.propertyName, in: type(of: element)) else {
      logger.debug("Cannot apply property value to '\(targetElement)' - unknown property (\(propertyValue))!")
      return nil
    }
    
    var propertyAndParams = cachedTransformedProperties[propertyValue.description]
    
    if propertyAndParams == nil, let styleSheetManager = stylingManager?.styleSheetManager {
      var valueContainsVariables = false
      // TODO: Move propery value parsing into PropertyType (or something)?
      let parsed = styleSheetManager.parsePropertyValue(propertyRawValue, as: property.type, scope: scope, didReplaceVariableReferences: &valueContainsVariables)
      guard let value = parsed else {
        logger.error("Cannot apply property value to '\(property.fqn)' in '\(targetElement)' - value is nil!")
        return nil
      }
      
      // Transform parameters
      var params: [Any]?
      var paramsContainsVariables = false
      if let rawParameters = propertyValue.rawParameters {
        let rawParams = rawParameters.map { styleSheetManager.replaceVariableReferences($0, scope: scope, didReplace: &paramsContainsVariables) }
        params = property.transformParameters(rawParams)
      }
      if !valueContainsVariables && !paramsContainsVariables {
        // TODO: Instead of skipping caching when variables are present - consider clearing cache when variables are changed
        cachedTransformedProperties[propertyValue.description] = (value, params)
      }
      
      propertyAndParams = (value, params)
    }
    
    return propertyAndParams
  }
  
  @discardableResult
  func apply(_ propertyValue: PropertyValue, onTarget targetElement: ElementStyle, styleSheetScope scope: StyleSheetScope) -> Bool {
    guard let element = targetElement.uiElement else { return false }
    if propertyValue.useCurrentValue {
      logger.debug("Property value not changed - using existing value for '\(propertyValue.description)' in '\(targetElement)'")
      return true
    }
    
    // TODO: Remove? - nested element registration not needed?
    //    if let nestedElementKeyPath = propertyValue.nestedElementKeyPathToRegister {
//    if let nestedElementKeyPath = propertyValue.prefixKeyPath {
//      if let keyPath = RuntimeIntrospectionUtils.validKeyPath(forCaseInsensitivePath: nestedElementKeyPath, in: type(of: element)) {
//        //        return targetElement.addValidNestedElementKeyPath(keyPath)
//        targetElement.addValidNestedElementKeyPath(keyPath)
//      } else {
//        logger.debug("Unable to resolve keypath '\(nestedElementKeyPath)' in '\(targetElement)'")
//        //        return false
//      }
//    }
    
    guard let propertyRawValue = propertyValue.rawValue, let property = findProperty(withName: propertyValue.propertyName, in: type(of: element)) else {
      //      if propertyValue.propertyName.firstIndex(of: ".") == nil { // Only log warning if not a prefixed property (which is expected to not match is most cases)
//      if propertyValue.prefixKeyPath == null { // Only log warning if not a prefixed property (which is expected to not match is most cases)
        logger.debug("Cannot apply property value to '\(targetElement)' - unknown property (\(propertyValue))!")
//      }
      return false
    }
    
    let cachedData = cachedTransformedProperties[propertyValue.description]
    var value = cachedData?.propertyValue
    var params = cachedData?.propertyParameters
    
    if cachedData == nil, let styleSheetManager = stylingManager?.styleSheetManager {
      //id value = [propertyValue valueForProperty:property];
      //PropertyValueAndParameters* valueAndParams = [propertyValue transformedValueAndParametersForProperty:property withStyleSheetManager:self.stylingManager.styleSheetManager];
      var valueContainsVariables = false
      // TODO: Move propery value parsing into PropertyType (or something)?
      value = styleSheetManager.parsePropertyValue(propertyRawValue, as: property.type, scope: scope, didReplaceVariableReferences: &valueContainsVariables)
      guard let value = value else {
        logger.error("Cannot apply property value to '\(property.fqn)' in '\(targetElement)' - value is nil!")
        return false
      }
      
      // Transform parameters
      var paramsContainsVariables = false
      if let rawParameters = propertyValue.rawParameters {
        let rawParams = rawParameters.map { styleSheetManager.replaceVariableReferences($0, scope: scope, didReplace: &paramsContainsVariables) }
        params = property.transformParameters(rawParams)
      }
      if !valueContainsVariables && !paramsContainsVariables {
        // TODO: Instead of skipping caching when variables are present - consider clearing cache when variables are changed
        cachedTransformedProperties[propertyValue.description] = (value, params)
      }
    }
    let result = property.setValue(value, onTarget: element, withParameters: params)
    if result {
      //logger.debug("Applied property value \(propertyRawValue) to '\(property.fqn)' in '\(targetElement)'")
    } else {
      logger.error("Unable to apply property value to '\(property.fqn)' in '\(targetElement)'!")
    }
    return result
  }
}
