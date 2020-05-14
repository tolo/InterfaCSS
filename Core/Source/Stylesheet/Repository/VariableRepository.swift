//
//  VariableRepository.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation

final class VariableRepository {
  
  private static let notValidIdentifierCharsSet = StyleSheetParserSyntax.shared.validIdentifierCharsSet.inverted
  
  weak var styleSheetManager: StyleSheetManager!
  
  private var runtimeStyleSheetsVariables: [String : String] = [:]
  
  public func valueOfStyleSheetVariable(withName variableName: String, scope: StyleSheetScope = .defaultGroupScope) -> String? {
    var value: String? = runtimeStyleSheetsVariables[variableName]
    if value == nil {
      for styleSheet in styleSheetManager.activeStylesheets.reversed() {
        value = styleSheet.content.variables[variableName] // TODO: Review access
        if value != nil {
          break
        }
      }
    }
    return value
  }
  
  public func setValue(_ value: String, forStyleSheetVariableWithName variableName: String) {
    runtimeStyleSheetsVariables[variableName] = value
  }
  
  public func replaceVariableReferences(_ inPropertyValue: String, scope: StyleSheetScope = .defaultGroupScope, didReplace: inout Bool) -> String {
    var location: Int = 0
    var propertyValue = inPropertyValue
    while location < propertyValue.count {
      // Replace any variable references
      var varPrefixLength = 2
      var varBeginLocation = propertyValue.index(ofString: "--", from: location)
      if (varBeginLocation == NSNotFound) {
        varPrefixLength = 1
        varBeginLocation = propertyValue.index(ofChar: "@", from: location)
      }
      
      if varBeginLocation != NSNotFound {
        location = varBeginLocation + varPrefixLength
        
        let variableNameRangeEnd = propertyValue.index(ofCharInSet: Self.notValidIdentifierCharsSet, from: location)
        let variableNameRange = propertyValue.range(from: location, to: variableNameRangeEnd)
        
        var variableValue: String? = nil
        if !variableNameRange.isEmpty {
          let variableName = propertyValue[variableNameRange]
          variableValue = valueOfStyleSheetVariable(withName: String(variableName), scope: scope)
        }
        if let variableValue = variableValue {
          var variableValue = variableValue.trimQuotes()
          variableValue = replaceVariableReferences(variableValue, scope: scope, didReplace: &didReplace) // Resolve nested variables
          // Replace variable occurrence in propertyValue string with variableValue string
          propertyValue = propertyValue.replaceCharacterInRange(from: varBeginLocation, to: variableNameRangeEnd, with: variableValue)
          location += variableValue.count
          didReplace = true
        } else  {
          // ISSLogWarning("Unrecognized property variable: %@ (property value: %@)", variableName, propertyValue)
          location = variableNameRangeEnd
        }
      } else {
        break
      }
    }
    return propertyValue
  }
  
  public func transformedValueOfStyleSheetVariable(withName variableName: String, as propertyType: PropertyType, scope: StyleSheetScope = .defaultGroupScope) -> Any? {
    if let rawValue = valueOfStyleSheetVariable(withName: variableName, scope: scope) {
      var didReplace = false
      let value = replaceVariableReferences(rawValue, scope: scope, didReplace: &didReplace)
      return propertyType.parser.parse(propertyValue: PropertyValue(propertyName: variableName, value: value))
      //      return styleSheetParser.parsePropertyValue(modValue, as: propertyType)
    }
    return nil
  }
}
