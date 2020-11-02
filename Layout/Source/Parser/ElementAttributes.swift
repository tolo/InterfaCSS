//
//  ElementAttributes.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import UIKit

public struct ElementAttributes {
  
  public enum AttributeName: String, StringParsableEnum {
    public static var defaultEnumValue: AttributeName {
      return .unknownAttribute
    }
        
    case unknownAttribute = "unknownAttribute"
    
    case id = "id"
    case styleClasses = "class"
    case style = "style"
    case property = "property"
    case addSubview = "addSubview"
    case implementationClass = "implementation"
    case collectionViewLayoutClass = "collectionViewLayout"
    case accessibilityIdentifier = "accessibilityIdentifier"
    
    case type = "type"
    case image = "image" // TODO: Remove?
    case src = "src"
    case title = "title"
    case text = "text"
    
    case layout = "layout"
  }
  
  let elementName: String
  
  let elementId: String?
  let styleClasses: [String]?
  let propertyName: String?
  let inlineStyle: [PropertyValue]?
  let accessibilityIdentifier: String?
  let implementationClass: UIResponder.Type?
  let addToViewHierarchy: Bool
  let collectionViewLayoutClass: UICollectionViewLayout.Type
  let layoutFile: String?
  let buttonType: UIElementType.ButtonType
  let src: String?

  let text: String?
  
  let rawAttributes: [String: String]
}


extension ElementAttributes {
  init(forElementName elementName: String, attributes attributesDict: [String: String], withStyler styler: Styler) {
    var elementId: String? = nil
    var styleClasses: [String]? = nil
    var propertyName: String? = nil
    var inlineStyle: [PropertyValue]? = nil
    var accessibilityIdentifier: String? = nil
    var implementationClass: UIResponder.Type? = nil
    var addToViewHierarchy: Bool = true
    var collectionViewLayoutClass: UICollectionViewLayout.Type = UICollectionViewFlowLayout.self
    var layoutFile: String? = nil
    var buttonType: UIElementType.ButtonType = .custom
    var src: String? = nil
    var text: String? = nil
    var rawAttributes: [String: String] = [:]
    
    for (key, value) in attributesDict {
      let attribute = AttributeName.enumValueWithDefault(from: key)
      
      switch attribute {
        case .id: elementId = value // "id" or "elementId":
        case .styleClasses: styleClasses = value.splitOnSpaceOrComma() // "class":
        case .style:
          if let style = styler.styleSheetManager.parsePropertyNameValuePairs(value) {
            inlineStyle = (inlineStyle ?? []) + style
        }
        case .property: propertyName = value
        case .implementationClass: // "implementation"
          if let clazz = RuntimeIntrospectionUtils.class(withName: value) as? UIResponder.Type {
            implementationClass = clazz
        }
        case .collectionViewLayoutClass: // "collectionViewLayout"
          if let clazz = RuntimeIntrospectionUtils.class(withName: value) as? UICollectionViewLayout.Type {
            collectionViewLayoutClass = clazz
        }
        case .accessibilityIdentifier: accessibilityIdentifier = value
        case .addSubview: addToViewHierarchy = (value as NSString).boolValue
        case .layout: layoutFile = value
        case .type: buttonType = UIElementType.ButtonType.enumValueWithDefault(from: value) // "type" (button type):
        case .image, .src: src = value
        case .text, .title: text = value
        default: break
      }
      
      if attribute != .unknownAttribute {
        rawAttributes[attribute.rawValue] = value
      } else {
        // Attempt to convert unrecognized attribute into inline style:
        if let style = styler.styleSheetManager.parsePropertyNameValuePair("\(key): \"\(value)\"") {
          inlineStyle = (inlineStyle ?? []) + [style]
        }
        rawAttributes[key] = value
      }
    }
    
    self.init(elementName: elementName, elementId: elementId, styleClasses: styleClasses, propertyName: propertyName,
              inlineStyle: inlineStyle, accessibilityIdentifier: accessibilityIdentifier, implementationClass: implementationClass,
              addToViewHierarchy: addToViewHierarchy, collectionViewLayoutClass: collectionViewLayoutClass, layoutFile: layoutFile,
              buttonType: buttonType, src: src, text: text, rawAttributes: rawAttributes)
  }
}
