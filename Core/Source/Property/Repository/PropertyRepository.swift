//
//  PropertyRepository.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit


final class PropertyRepository {
  let logger = Logger.properties
  
  var compoundProperties: [String: CompoundProperty] = [:]
  
  var propertiesByType: [String: [String: Property]] = [:]
  
  var typeNamesToClasses: [String: AnyClass] = [:]
  
  
  // MARK: - initialization - setup of properties
  
  convenience init() {
    self.init(withDefaultProperties: true)
  }
  
  init(withDefaultProperties: Bool) {
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
    
    if withDefaultProperties {
      registerDefaultUIKitProperties()
      registerDefaultCSSProperties()
    }
  }
  
  
  // MARK: - Types
  
  /**
   * Returns the canonical type class for the given class, i.e. the closest super class that represents a valid type selector. For instance, for all `UIView`
   * subclasses, this would by default be `UIView`.
   */
  func canonicalTypeClass(for clazz: AnyClass) -> AnyClass? {
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
  
  func canonicalType(for clazz: AnyClass) -> String? {
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
  
  func canonicalTypeClass(forType type: String, registerIfNotFound: Bool) -> AnyClass? {
    var uiKitClassName = type.lowercased()
    if !uiKitClassName.hasPrefix("ui") {
      uiKitClassName = "ui" + uiKitClassName
    }
    var clazz: AnyClass? = typeNamesToClasses[uiKitClassName]
    if clazz == nil {
      clazz = typeNamesToClasses[type.lowercased()] // If not UIKit class - see if it is a custom class (typeNamesToClasses always uses lowecase keys)
    }
    if clazz == nil && registerIfNotFound {
      // If type doesn't match a registered class name, try to see if the type is a valid class...
      if let classForName = RuntimeIntrospectionUtils.class(withName: type) {
        // ...and if it is - register it as a canonical type (keep case)
        clazz = classForName
        registerCanonicalTypeClass(classForName)
      }
    }
    return clazz
  }
  
  func canonicalTypeClass(forType type: String) -> AnyClass? {
    return canonicalTypeClass(forType: type, registerIfNotFound: false)
  }
  
  /**
   * Registers a class for use as a valid type selector in stylesheets. Note: this happens automatically whenever an unknown, but valid, class name is encountered
   * in a type selector in a stylesheet. This method exist to be able to register all custom canonical type classes before stylesheet parsing occurs, and to also
   * enable case-insensitive matching of type name -> class.
   *
   * @see canonicalTypeClassForClass:
   */
  @discardableResult
  func registerCanonicalTypeClass(_ clazz: AnyClass) -> String {
    let type = canonicalClassName(clazz)
    if typeNamesToClasses[type] != nil { return type } // Already registered
    
    typeNamesToClasses[type] = clazz
    
    // Reset all cached data ElementStyle, since canonical type class may have changed for some elements
    ElementStyle.markAllCachedStylingInformationAsDirty()
    return type
  }
  
  
  // MARK: - Property lookup
  
  func findProperty(withName name: String, in clazz: AnyClass) -> Property? {
    let normalizedName = Property.normalizeName(name)
    return findProperty(withNormalizedName: normalizedName, in: clazz)
  }
  
  func findProperty(withNormalizedName normalizedName: String, in clazz: AnyClass) -> Property? {
    guard let canonicalType = self.canonicalType(for: clazz) else { return nil }
    
    var properties = propertiesByType[canonicalType] ?? [:]
    var property = properties[normalizedName]
    if property == nil {
      // Search in super class
      let superClass: AnyClass? = clazz.superclass()
      if let superClass = superClass, superClass != NSObject.self {
        property = findProperty(withNormalizedName: normalizedName, in: superClass)
      }
    }
    if property == nil, let superClass = clazz.superclass() {
      let runtimeProperties = RuntimeIntrospectionUtils.runtimeProperties(for: clazz, excludingRootClasses: [superClass], lowercasedNames: true)
      for (name, runtimeProperty) in runtimeProperties where properties[name] == nil {
        properties[name] = Property(runtimeProperty: runtimeProperty, type: self.runtimeProperty(toPropertyType: runtimeProperty), enumValueMapping: nil)
      }
      propertiesByType[canonicalType] = properties
      property = properties[normalizedName]
    }
    return property
  }
  
  
  // MARK: - Property registration
  
  /**
   * Registers a custom property.
   */
  func register(_ property: Property, in clazz: AnyClass, replaceExisting: Bool = true) -> Property {
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
  
  func register(_ compoundProperty: CompoundProperty) {
    compoundProperty.compoundPropertyNames.forEach { compoundProperties[$0] = compoundProperty }
  }
  
  // MARK: - Property type mapping
  
  func runtimeProperty(toPropertyType runtimeProperty: RuntimeProperty) -> PropertyType {
    if let propertyClass = runtimeProperty.propertyClass {
      if let _ = propertyClass as? NSString.Type {
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

func canonicalClassName(_ clazz: AnyClass) -> String {
  return String(describing: clazz).lowercased()
}
