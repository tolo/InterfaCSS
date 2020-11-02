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
  
  public func valueOfStyleSheetVariable(withName variableName: String, scope: StyleSheetScope = .all) -> String? {
    var value: String? = runtimeStyleSheetsVariables[variableName]
    if value == nil {
      let stylesheetsInScope = styleSheetManager.activeStylesheets(in: scope)
      for styleSheet in stylesheetsInScope.reversed() {
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
  
  public func replaceVariableReferences(_ inPropertyValue: String, scope: StyleSheetScope = .all, didReplace: inout Bool) -> String {
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
        let variableNameLocation = varBeginLocation + varPrefixLength
        
        var variableNameRangeEnd = propertyValue.index(ofCharInSet: Self.notValidIdentifierCharsSet, from: variableNameLocation)
        if (variableNameRangeEnd == NSNotFound) { variableNameRangeEnd = propertyValue.count }
        let variableNameRange = propertyValue.range(from: variableNameLocation, to: variableNameRangeEnd)
        
        var variableValue: String? = nil
        var variableName = "n/a"
        if !variableNameRange.isEmpty {
          variableName = String(propertyValue[variableNameRange])
          variableValue = valueOfStyleSheetVariable(withName: String(variableName), scope: scope)
        }
        if let variableValue = variableValue {
          var variableValue = variableValue.trimQuotes()
          variableValue = replaceVariableReferences(variableValue, scope: scope, didReplace: &didReplace) // Resolve nested variables
          // Replace variable occurrence in propertyValue string with variableValue string
          propertyValue = propertyValue.replaceCharacterInRange(from: varBeginLocation, to: variableNameRangeEnd, with: variableValue)
          location += variableValue.count
          didReplace = true
        } else {
          Logger.stylesheets.error("Unrecognized property variable: \(variableName) (property value: \(propertyValue)")
          location = variableNameRangeEnd
        }
      } else {
        break
      }
    }
    return propertyValue
  }
  
  private func stringValueOfStyleSheetVariable(withName variableName: String, scope: StyleSheetScope = .all) -> String? {
    if let rawValue = valueOfStyleSheetVariable(withName: variableName, scope: scope) {
      var didReplace = false
      return replaceVariableReferences(rawValue, scope: scope, didReplace: &didReplace)
    }
    return nil
  }
  
  public func transformedValueOfStyleSheetVariable(withName variableName: String, as propertyType: PropertyType, scope: StyleSheetScope = .all) -> Any? {
    if let string = stringValueOfStyleSheetVariable(withName: variableName, scope: scope) {
      return propertyType.parseAny(propertyValue: PropertyValue(propertyName: variableName, value: string))
    }
    return nil
  }
  
  public func transformedValueOfStyleSheetVariable<T>(withName variableName: String, as propertyType: TypedPropertyType<T>, scope: StyleSheetScope = .all) -> T? {
    if let string = stringValueOfStyleSheetVariable(withName: variableName, scope: scope) {
      return propertyType.parse(propertyValue: PropertyValue(propertyName: variableName, value: string))
    }
    return nil
  }
}
