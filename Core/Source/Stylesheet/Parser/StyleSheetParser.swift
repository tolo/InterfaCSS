//
//  StyleSheetParser.swift
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

import Foundation
import Parsicle


private typealias P = AnyParsicle
private let S = StyleSheetParserSyntax.shared
private let spaces = S.spacesIgnored


extension StyleSheetParser {
  func char(_ char: Character, skipSpaces: Bool = false) -> StringParsicle { return S.char(char, skipSpaces: skipSpaces) }
  func charIgnore<Result>(_ char: Character, skipSpaces: Bool = false) -> Parsicle<Result> { return S.charIgnore(char, skipSpaces: skipSpaces) }
  func string(_ string: String) -> StringParsicle { return S.string(string) }
}

public class StyleSheetParser: NSObject {
  
  var cssParser: Parsicle<[CSSContent]>!
  var variableParser: Parsicle<Void>!
  var selectorsChainsParser: Parsicle<ParsedRuleset>!
  var simpleSelectorChainComponent: Parsicle<SelectorChainComponent>!
  private var standalonePropertyPairParser: Parsicle<PropertyValue>!
  private var standalonePropertyPairsParser: Parsicle<[PropertyValue]>!
  weak var styleSheetManager: StyleSheetManager!
  
  override init() {
    super.init()
    
    //* Ruleset parser setup *
    let colon = char(":")
    let openParenIgnored: StringParsicle = char("(").ignore()
    let closeParenIgnored: StringParsicle = char(")").ignore()
    //* Comments *
    let commentParser = S.comment.map {
      //            ISSLogTrace("Comment: %@", value.trim()) // TODO: Use Logger?
      return $0
    }
    
    //* Variables *
    variableParser = S.propertyPairParser(true).map { (pair, context) -> Void in
      if let context = context.userInfo as? StyleSheetParsingContext {
        context.variables[pair[0]] = pair[1]
      }
    }
    
    //* Selectors *
    // Basic selector fragment parsers:
    let typeName = P.choice([S.identifier, char("*")])
    let classNamesSelector = S.dot.keepRight(S.identifier).many()
    let elementIdSelector = S.hashSymbol.keepRight(S.identifier)
    
    // Pseudo class parsers:
    let plusOrMinus = P.choice([char("+"), char("-")])
    let optionalPlusOrMinus = P.optional(plusOrMinus, defaultValue: "")
    let optionalNumber = P.optional(S.plainNumber, defaultValue: "1")
    let pseudoClassParameterParserFull = P.sequential([openParenIgnored, spaces,
                                                       optionalPlusOrMinus, optionalNumber, charIgnore("n"),
                                                       spaces, plusOrMinus, spaces, S.plainNumber, spaces, closeParenIgnored])
      .map { (values: [String]) -> (Int, Int) in
        let a = Int(values[0] +  values[1]) ?? 1 // a modifier + value
        let b = Int(values[2] + values[3]) ?? 0 // b modifier + value
        return (a, b)
    }
    let pseudoClassParameterParserAN = P.sequential([openParenIgnored, spaces,
                                                     P.optional(plusOrMinus), P.optional(S.plainNumber), charIgnore("n"), spaces, closeParenIgnored])
      .map { (values: [String]) -> (Int, Int) in
        return (Int(values[0] +  values[1]) ?? 1, 0) // a modifier + value
    }
    let pseudoClassParameterParserEven = P.sequential([openParenIgnored, spaces, P.string("even"), spaces, closeParenIgnored])
      .map { _ in (2, 0) }
    let pseudoClassParameterParserOdd = P.sequential([openParenIgnored, spaces, P.string("odd"), spaces, closeParenIgnored])
      .map { _ in (2, 1) }
    let structuralPseudoClassParameterParsers = P.choice([pseudoClassParameterParserFull, pseudoClassParameterParserAN, pseudoClassParameterParserEven, pseudoClassParameterParserOdd])
    let pseudoClassParameterParser = P.sequential([openParenIgnored, spaces,
                                                   P.choice([S.quotedString, S.anyName]), spaces, closeParenIgnored])
      .map { $0[0].trimQuotes() }
    let parameterizedPseudoClassSelector = P.sequential([colon.ignore(), S.identifier.asAny(),
                                                         P.choice([structuralPseudoClassParameterParsers.asAny(), pseudoClassParameterParser.asAny()])])
      .map { [unowned self] (values: [Any]) -> PseudoClass? in
        return createPseudoClass(values, styleSheetManager: self.styleSheetManager)
    }
    let simplePseudoClassSelector = colon.keepRight(S.identifier).map { [unowned self] type -> PseudoClass? in
      return createPseudoClass([type], styleSheetManager: self.styleSheetManager)
      //                let pseudoClassType = self.styleSheetManager?.pseudoClassType(from: type) ?? .unknown
      //                return self.styleSheetManager?.createPseudoClass(withParameter: nil, type: pseudoClassType)
    }
    let pseudoClassSelector = P.choice([parameterizedPseudoClassSelector, simplePseudoClassSelector]).many()
    
    
    // Actual selectors parsers:
    // type #id .class [:pseudo]
    let typeSelector1 = P.sequential([typeName.asAny(), elementIdSelector.asAny(), classNamesSelector.asAny(), P.optional(pseudoClassSelector).asAny()]).map { [unowned self] (values: [Any]) in
      createSelector(values[0], elementId: values[1], classNames: values[2], pseudoClasses: values.count > 3 ? values[3] : nil, styleSheetManager: self.styleSheetManager)
    }
    // type #id [:pseudo]
    let typeSelector2 = P.sequential([typeName.asAny(), elementIdSelector.asAny(), P.optional(pseudoClassSelector).asAny()]).map { [unowned self] (values: [Any]) in
      createSelector(values[0], elementId: values[1], classNames: nil, pseudoClasses: values.count > 2 ? values[2] : nil, styleSheetManager: self.styleSheetManager)
    }
    // type .class [:pseudo]
    let typeSelector3 = P.sequential([typeName.asAny(), classNamesSelector.asAny(), P.optional(pseudoClassSelector).asAny()]).map { [unowned self] (values: [Any]) -> Selector? in
      createSelector(values[0], elementId: nil, classNames: values[1], pseudoClasses: values.count > 2 ? values[2] : nil, styleSheetManager: self.styleSheetManager)
    }
    // type [:pseudo]
    let typeSelector4 = P.sequential([typeName.asAny(), P.optional(pseudoClassSelector).asAny()]).map { [unowned self] (values: [Any]) in
      createSelector(values[0], elementId: nil, classNames: nil, pseudoClasses: values.count > 1 ? values[1] : nil, styleSheetManager: self.styleSheetManager)
    }
    // #id .class [:pseudo]
    let elementSelector1 = P.sequential([elementIdSelector.asAny(), classNamesSelector.asAny(), P.optional(pseudoClassSelector).asAny()]).map { [unowned self] (values: [Any]) in
      createSelector(nil, elementId: values[0], classNames: values[1], pseudoClasses: values.count > 2 ? values[2] : nil, styleSheetManager: self.styleSheetManager)
    }
    // #id [:pseudo]
    let elementSelector2 = P.sequential([elementIdSelector.asAny(), P.optional(pseudoClassSelector).asAny()]).map { [unowned self] (values: [Any]) in
      createSelector(nil, elementId: values[0], classNames: nil, pseudoClasses: values.count > 1 ? values[1] : nil, styleSheetManager: self.styleSheetManager)
    }
    // .class [:pseudo]
    let classSelector = P.sequential([classNamesSelector.asAny(), P.optional(pseudoClassSelector).asAny()]).map { [unowned self] (values: [Any]) in
      createSelector(nil, elementId: nil, classNames: values[0], pseudoClasses: values.count > 1 ? values[1] : nil, styleSheetManager: self.styleSheetManager)
    }
    simpleSelectorChainComponent = P.choice([typeSelector1, typeSelector2, typeSelector3, typeSelector4,
                                             elementSelector1, elementSelector2, classSelector]).map { SelectorChainComponent.selector($0) }
    
    // Selector combinator parsers:
    let descendantCombinator = P.space().many().map { _ in SelectorChainComponent.combinator(.descendant) }
    let childCombinator = P.char(">", skipSpaces: true).map { _ in SelectorChainComponent.combinator(.child) }
    let adjacentSiblingCombinator = P.char("+", skipSpaces: true).map { _ in SelectorChainComponent.combinator(.sibling) }
    let generalSiblingCombinator = P.char("~", skipSpaces: true).map { _ in SelectorChainComponent.combinator(.generalSibling) }
    let combinators = P.choice([generalSiblingCombinator, adjacentSiblingCombinator, childCombinator, descendantCombinator ])
    
    // Selector chain parsers:
    let selectorChain = simpleSelectorChainComponent.sepByKeep(combinators).map { values -> ParsedSelectorChain in
      if let chain = SelectorChain(components: values) {
        return ParsedSelectorChain.selectorChain(chain: chain)
      } else {
        return ParsedSelectorChain.badData(badData: "Invalid selector chain: \(values.map({ String(describing: $0) }).joined(separator: " "))") // TODO: Is this logged?
      }
    }
    
    selectorsChainsParser = selectorChain.skipSurroundingSpaces().sepBy(S.comma).map { values in
      return ParsedRuleset(withSelectorChains: values)
    }
    
    /** Properties **/
    let propertyDeclarations = self.propertyParser(selectorsChainsParser, commentParser: commentParser, selectorChainParser: selectorChain)
    
    /** Ruleset **/
    let rulesetParser = self.rulesetParser(withContentParser: propertyDeclarations, selectorsChainsDeclarations: selectorsChainsParser)
    
    /** Unrecognized content **/
    let unrecognizedContent = unrecognizedLineParser().map { string -> CSSContent in
      return .unrecognizedContent("Unrecognized content: '\(string.trim())'")
    }
    let cssParserCommentParser = commentParser.map { CSSContent.comment($0) }
    let cssParserVariable = variableParser.map { CSSContent.variable }
    let cssParserRuleset = rulesetParser.map { CSSContent.ruleset($0) }
    cssParser = P.choice([cssParserCommentParser, cssParserVariable, cssParserRuleset, unrecognizedContent]).many()
    
    standalonePropertyPairParser = S.propertyPairParser(false).map { [unowned self] value in
      let propertyComponents = self.transformPropertyPair(value)
      return PropertyValue(propertyName: propertyComponents.propertyName, value: propertyComponents.value, rawParameters: propertyComponents.rawParameters)
    }
    standalonePropertyPairsParser = standalonePropertyPairParser.sepBy(P.charSpaced(";"))
  }
  
  /**
   * Parses the specified stylesheet data and returns an object (`StyleSheetContent`) containing the parsed rulesets and variables.
   */
  public func parse(_ styleSheetData: String) -> StyleSheetContent? {
    guard styleSheetData.hasData() else {
      debugPrint("Empty/nil stylesheet data!") // TODO: ISSLogWarning ...or debug?
      return nil
    }
    let parsingContext = StyleSheetParsingContext()
    let parseResult = cssParser.parse(styleSheetData, userInfo: parsingContext)
    if parseResult.match, let result = parseResult.value {
      var rulesets: [Ruleset] = []
      var lastElement: ParsedRuleset? = nil
      for element in result {
        switch element {
          case .ruleset(let rulesetDeclaration):
            processProperties(rulesetDeclaration.parsedProperties, withSelectorChains: rulesetDeclaration.parsedChains, andAddToRulesets: &rulesets)
            lastElement = rulesetDeclaration
          case .unrecognizedContent(let badData):
            if let lastElement = lastElement {
              logError(.stylesheets, "Warning! \(badData) - near \(lastElement.description)")
            } else {
              logError(.stylesheets, "Warning! \(badData) - near beginning of file")
          }
          default: break
        }
      }
      //            ISSLogTrace("Parse result: \n%@", rulesets) // TODO: ISSLogTrace
      return StyleSheetContent(rulesets: rulesets, variables: parsingContext.variables)
    } else {
      debugPrint("Error parsing stylesheet") // TODO: ISSLogWarning ...or debug?
      return nil
    }
  }
  
  /**
   * Parses a property value of the specified type from a string. Any variable references in `value` will be replaced with their corresponding values.
   */
//  public func parsePropertyValue(_ value: String, as type: PropertyType) -> Any? {
//    return propertyParser.parsePropertyValue(value, of: type)
//  }
  
  public func parsePropertyNameValuePair(_ nameAndValue: String) -> PropertyValue? {
    let parseResult = standalonePropertyPairParser.parse(nameAndValue)
    return parseResult.match ? parseResult.value : nil
  }
  
  public func parsePropertyNameValuePairs(_ propertyPairsString: String) -> [PropertyValue]? {
    let parseResult = standalonePropertyPairsParser.parse(propertyPairsString)
    return parseResult.match ? parseResult.value : nil
  }
  
  // MARK: - Property declarations and value transform
  private func transformPropertyPair(_ propertyPair: [String]) -> TransformedPropertyPair {
    var propertyNameString = propertyPair[0]
    let propertyValue = propertyPair[1].trim()
    var parameters: [String]? = nil
    
    // Extract parameters
    // TODO: Remove this?
    if let parametersRange = propertyNameString.range(of: "__") {
      let parameterString = propertyNameString[parametersRange.upperBound...]
      parameters = parameterString.components(separatedBy: "_")
      propertyNameString = String(propertyNameString[..<parametersRange.lowerBound])
    }
    
    // Normalize property name - i.e. remove any dashes from string and convert to lowercase string
    propertyNameString = Property.normalizeName(propertyNameString.trim())
    // Check for any key path in the property name
    var prefixKeyPath: String? = nil
    let dotRange = propertyNameString.rangeOf(".", options: .backwards)
    if let dotRange = dotRange, dotRange.upperBound < propertyNameString.endIndex {
      prefixKeyPath = String(propertyNameString[..<dotRange.lowerBound])
      propertyNameString = String(propertyNameString[dotRange.upperBound...])
    }
    
    // Check for special `current` keyword
    if propertyValue.trim() ==⇧ "current" {
      return (propertyNameString, prefixKeyPath, .currentValue, parameters)
    } else {
      return (propertyNameString, prefixKeyPath, .value(rawValue: propertyValue), parameters)
    }
  }
  
  // MARK: - Additional parser setup
  
  func unrecognizedLineParser() -> StringParsicle {
    return S.parseLineUpToInvalidCharacters(in: "{}")
  }
  
  private func rulesetParser(withContentParser rulesetContentParser: Parsicle<[ParsedRulesetContent]>, selectorsChainsDeclarations: Parsicle<ParsedRuleset>) -> Parsicle<ParsedRuleset> {
    return selectorsChainsDeclarations.asAny().then(rulesetContentParser.asAny().between(S.openBraceSkipSpace, and: S.closeBraceSkipSpace)).map { values in
      guard let ruleset = values[0] as? ParsedRuleset, let content = values[1] as? [ParsedRulesetContent] else { return nil }
      ruleset.parsedProperties = content
      return ruleset
    }
  }
  
  private func propertyParser(_ selectorsChainsDeclarations: Parsicle<ParsedRuleset>, commentParser: StringParsicle, selectorChainParser: Parsicle<ParsedSelectorChain>) -> Parsicle<[ParsedRulesetContent]> {
    //* -- Unrecognized line -- *
    let unrecognizedLine = unrecognizedLineParser().map { string in
      return "Unrecognized property line: '\(string.trim())'"
    }
    
    //* -- Property pair -- *
    let propertyPairParser = S.propertyPairParser(false).map { [unowned self] value -> ParsedRulesetContent in
      let propertyValue = self.transformPropertyPair(value)
//      if let _ = propertyValue.prefixKeyPath {
//        return .prefixedProperty(propertyValue)
//      } else {
        return .propertyDeclaration(PropertyValue(propertyName: propertyValue.propertyName, value: propertyValue.value, rawParameters: propertyValue.rawParameters))
//      }
    }
    
    //* -- Extension/Inheritance -- *
    let optionalColon = char(":").skipSurroundingSpaces().optional()
    let extendDeclarationParser = P.sequential([
      string("@extend").or(string("@extends")).ignore(), optionalColon.ignore(), P.spaces().ignore(),
      selectorChainParser, charIgnore(";", skipSpaces: true)
    ]).map { (value: [ParsedSelectorChain]) -> RulesetExtension? in
      if let chain = value[0].selectorChain {
        return RulesetExtension(chain)
      } else {
        return nil
      }
    }
    
    // Create parser for unsupported nested declarations, to prevent those to interfere with current declarations
    let bracesSet = CharacterSet(charactersIn: "{}")
    let anythingButBraces = P.take(untilIn: bracesSet, minCount: 1)
    let unsupportedNestedRulesetParser = anythingButBraces.then(anythingButBraces.between(S.openBraceSkipSpace, and: S.closeBraceSkipSpace)).map { value in
      return "Unsupported nested ruleset: '\(String(describing: value))'"
    }
    
    // Create forward declaration for nested ruleset/declarations parser
    let nestedRulesetParserProxy = DelegatingParsicle<ParsedRuleset>()
    
    // Property declarations
    let rulesetContent: Parsicle<[ParsedRulesetContent]> = P.choice([
      commentParser.map { .comment($0) }, propertyPairParser, nestedRulesetParserProxy.map { .nestedRuleset($0) },
      extendDeclarationParser.map { .extendedDeclaration($0) }, unsupportedNestedRulesetParser.map { .unsupportedNestedRuleset($0) }, unrecognizedLine.map { .unrecognizedContent($0) }
    ]).many()
    
    // Create parser for nested declarations
    let nestedRulesetParser = rulesetParser(withContentParser: rulesetContent, selectorsChainsDeclarations: selectorsChainsDeclarations)
    nestedRulesetParserProxy.delegate = nestedRulesetParser
    
    return rulesetContent
  }
  
  
  // MARK: - Property declaration processing (setup of nested declarations)
  
  private func processProperties(_ properties: [ParsedRulesetContent], withSelectorChains parsedSelectorChains: [ParsedSelectorChain], andAddToRulesets rulesets: inout [Ruleset]) {
    var nestedDeclarations: [(properties: [ParsedRulesetContent], chains: [ParsedSelectorChain])] = []
    
    let selectorChains = parsedSelectorChains.compactMap { $0.selectorChain } // TODO: Log error for invalid selector chains here?
    
    if selectorChains.count != 0 {
      var propertyValues: [PropertyValue] = []
      var extendedDeclarationSelectorChain: SelectorChain? = nil
      for entry in properties {
        switch entry {
          case .unsupportedNestedRuleset(let description), .unrecognizedContent(let description):
            let rulsetDescription = Ruleset(selectorChains: selectorChains, andProperties: []).debugDescription
            print("Warning! \(description) - in ruleset: \(rulsetDescription)") // TODO: ISSLogWarning
          
//          case .prefixedProperty(let propertyValue):
//            let prefixKeyPath = propertyValue.prefixKeyPath!
//            let nestedElementSelectorChain = SelectorChain(selector: .nestedElement(nestedElementKeyPath: prefixKeyPath))
//            // Construct new selector chains by appending selector to parent selector chains
//            var nestedSelectorChains: [ParsedSelectorChain] = []
//            for parentChain in selectorChains {
//              nestedSelectorChains.append(.selectorChain(chain: parentChain.addingDescendantSelectorChain(nestedElementSelectorChain)))
//            }
//            nestedDeclarations.append(([.propertyDeclaration(PropertyValue(propertyName: propertyValue.propertyName, value: propertyValue.value, rawParameters: propertyValue.rawParameters))], nestedSelectorChains))
//
//            // Also add property value with prefix, in case it matches any explicitly defined prefixed (virtual) property
//            propertyValues.append(PropertyValue(propertyName: propertyValue.propertyName, /*prefixKeyPath: prefixKeyPath,*/ value: propertyValue.value, rawParameters: propertyValue.rawParameters))
          
          case .nestedRuleset(let ruleset):
            // TODO: Log error for invalid nested selector chains here?
            // Construct new selector chains by appending selector to parent selector chains
            var nestedSelectorChains: [ParsedSelectorChain] = []
            for nestedSelectorChain in ruleset.chains {
              for parentChain in selectorChains {
                nestedSelectorChains.append(.selectorChain(chain: parentChain.addingDescendantSelectorChain(nestedSelectorChain)))
              }
            }
            nestedDeclarations.append((ruleset.parsedProperties, nestedSelectorChains))
          
          // Add placeholder property value for registration of nested element key path:
          // TODO: Remove
          //                    if let nestedElementKeyPath = ruleset.nestedElementKeyPath {
          //                      propertyValues.append(PropertyValue(propertyKeyPathToRegister: nestedElementKeyPath))
          //                    }
          
          case .extendedDeclaration(let extendedDeclaration):
            extendedDeclarationSelectorChain = extendedDeclaration.extendedSelectorChain
          
          case .propertyDeclaration(let propertyValue):
            propertyValues.append(propertyValue)
          
          case .comment: break
        }
      }
      
      // Add ruleset
      rulesets.append(Ruleset(selectorChains: selectorChains, andProperties: propertyValues, extendedDeclarationSelectorChain: extendedDeclarationSelectorChain))
      
      // Process nested rulesets
      for declarationPair in nestedDeclarations {
        processProperties(declarationPair.properties, withSelectorChains: declarationPair.chains, andAddToRulesets: &rulesets)
      }
    } else {
      print("No valid selector chains in declaration (count before validation: \(parsedSelectorChains.count) - properties: \(properties)") // TODO: ISSLogWarning?
    }
  }
}
