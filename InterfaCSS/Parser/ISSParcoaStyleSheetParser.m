//
//  ISSParcoaStyleSheetParser.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2013-06-14.
//  Copyright (c) 2013 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSParcoaStyleSheetParser.h"

#import <Parcoa/Parcoa.h>

#import "Parcoa+ISSAdditions.h"
#import "ISSSelector.h"
#import "ISSNestedElementSelector.h"
#import "ISSSelectorChain.h"
#import "ISSPropertyDeclarations.h"
#import "ISSPropertyDeclaration.h"
#import "NSObject+ISSLogSupport.h"
#import "NSString+ISSStringAdditions.h"
#import "UIColor+ISSColorAdditions.h"
#import "ISSRectValue.h"
#import "ISSPointValue.h"
#import "ISSPseudoClass.h"
#import "InterfaCSS.h"
#import "ISSPropertyRegistry.h"
#import "ISSRuntimeIntrospectionUtils.h"
#import "ISSLayout.h"
#import "ISSRemoteFont.h"
#import "ISSDownloadableResource.h"


/* Helper functions */

static NSArray* nonNullElementArray(NSArray* array) {
    if( [array indexOfObject:[NSNull null]] != NSNotFound ) {
        NSMutableArray* cleanArray = [NSMutableArray array];
        for(id entry in array) {
            if( entry != [NSNull null] ) [cleanArray addObject:entry];
        }
        return cleanArray;
    }
    return array;
}

static id elementOrNil(NSArray* array, NSUInteger index) {
    if( index < array.count ) {
        id element = array[index];
        if( element != [NSNull null] ) {
            if( [element isKindOfClass:NSArray.class] ) return nonNullElementArray(element);
            return element;
        }
    }
    return nil;
}

static float floatAt(NSArray* array, NSUInteger index) {
    return [array[index] floatValue];
}


/* Helper classes */


/**
 * Placeholder for bad data, to support better error feedback.
 */
@interface ISSStyleSheetParserBadData : NSObject
@property (nonatomic, strong) NSString* badDataDescription;
@end
@implementation ISSStyleSheetParserBadData
+ (instancetype) badDataWithDescription:(NSString*)badDataDescription {
    ISSStyleSheetParserBadData* styleSheetParserBadData = [[self alloc] init];
    styleSheetParserBadData.badDataDescription = badDataDescription;
    return styleSheetParserBadData;
}
- (NSString*) description {
    return self.badDataDescription;
}
@end


/**
 * ISSLayoutAttributeValue class extension to make targetAttribute writable.
 */
@interface ISSLayoutAttributeValue ()
@property (nonatomic, readwrite) ISSLayoutAttribute targetAttribute;
@end

/* Flag for indicating that a size to fit should be used for an ISSLayout */
static NSObject* ISSLayoutAttributeSizeToFitFlag;


/**
 * Selector chains declaration wrapper class, to keep track of property ordering and of nested declarations
 */
@interface ISSSelectorChainsDeclaration : NSObject<NSCopying>
@property (nonatomic, strong, readonly) NSMutableArray* chains;
@property (nonatomic, strong) NSMutableArray* properties;
+ (instancetype) selectorChainsWithArray:(NSMutableArray*)chains;
@end

@implementation ISSSelectorChainsDeclaration
+ (instancetype) selectorChainsWithArray:(NSMutableArray*)chains {
    ISSSelectorChainsDeclaration* chainsDeclaration = [[ISSSelectorChainsDeclaration alloc] init];
    chainsDeclaration->_chains = chains;
    return chainsDeclaration;
}
- (instancetype) copyWithZone:(NSZone*)zone {
    ISSSelectorChainsDeclaration* chainsDeclaration = [[ISSSelectorChainsDeclaration alloc] init];
    chainsDeclaration->_chains = self.chains;
    return chainsDeclaration;
}
- (NSString*) description {
    return [NSString stringWithFormat:@"[%@ - %@]", self.chains, self.properties];
}
- (NSString*) displayDescription {
    return [[[ISSPropertyDeclarations alloc] initWithSelectorChains:self.chains andProperties:nil] displayDescription:NO];
}
- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if( [object isKindOfClass:ISSSelectorChainsDeclaration.class] ) {
        if( ISS_ISEQUAL(self.chains, [object chains]) && ISS_ISEQUAL(self.properties, [(ISSPropertyDeclarations*)object properties]) ) return YES;
    }
    return NO;
}
@end


/**
 * ISSParcoaStyleSheetParser
 */
@implementation ISSParcoaStyleSheetParser {
    // Common parsers
    ParcoaParser *dot, *hash, *semiColonSkipSpace, *comma, *openBraceSkipSpace, *closeBraceSkipSpace,
            *untilSemiColon, *propertyNameValueSeparator, *anyName, *anythingButControlChars, *anythingButControlCharsExceptColon,
            *identifier, *identifierOnlyAlphpaAndUnderscore, *quotedIdentifier, *plainNumber, *numberValue, *numberOrExpressionValue, *anyValue, *commentParser, *quotedString, *quotedStringRaw;

    NSCharacterSet* validVariableNameSet;

    NSMutableDictionary* propertyNameToProperty;
    NSMutableDictionary* typeToParser;
    ParcoaParser* enumValueParser;
    ParcoaParser* enumBitMaskValueParser;
    NSMutableDictionary* transformedValueCache;

    ParcoaParser* cssParser;
}

+ (void) initialize {
    ISSLayoutAttributeSizeToFitFlag = [[NSObject alloc] init];
}

#pragma mark - Enum property parsing

- (id) enumValueForString:(NSString*)enumString inProperty:(ISSPropertyDefinition*)p {
    enumString = [enumString lowercaseString];
    id result = p.enumValues[enumString];
    if( !result ) { // Fallback to suffix matching to support full UIKit enum name (i.e. UIViewAutoresizingFlexibleWidth instead of width)
        enumString = [enumString lowercaseString];
        for(NSString* enumName in p.enumValues.allKeys) {
            if( [enumString hasSuffix:enumName] ) return p.enumValues[enumName];
        }
        // Fallback 2 - try to convert enum string as a numeric value
        ParcoaResult* parseResult = [numberValue parse:enumString];
        if( parseResult.isOK ) result = parseResult.value;
    }
    return result;
}

- (id) parameterEnumValueForString:(NSString*)enumString inProperty:(ISSPropertyDefinition*)p {
    enumString = [enumString lowercaseString];
    id result = p.parameterEnumValues[enumString];
    if( !result ) { // Fallback to suffix matching to support full UIKit enum name (i.e. UIViewAutoresizingFlexibleWidth instead of width)
        for(NSString* enumName in p.parameterEnumValues.allKeys) {
            if( [enumString hasSuffix:enumName] ) return p.parameterEnumValues[enumName];
        }
    }
    return result;
}

- (id) transformEnumValue:(NSString*)enumValue forProperty:(ISSPropertyDefinition*)p {
    id result = [self enumValueForString:enumValue inProperty:p];
    if( !result ) [self iss_logWarning:@"Unrecognized enum value: '%@'", enumValue];
    return result;
}

- (id) transformEnumBitMaskValues:(NSArray*)enumValues forProperty:(ISSPropertyDefinition*)p {
    NSNumber* result = nil;
    for(NSString* value in enumValues) {
        id enumValue = [self enumValueForString:value inProperty:p];
        if( enumValue ) {
            NSUInteger constVal = [enumValue unsignedIntegerValue];
            if( result ) result = @([result unsignedIntegerValue] | constVal);
            else result = @(constVal);
        } else [self iss_logWarning:@"Unrecognized enum value: '%@'", value];
    }
    return result;
}


#pragma mark - Color parsing

- (NSArray*) basicColorValueParsers {
    ParcoaParser* rgb = [[Parcoa iss_parameterStringWithPrefix:@"rgb"] transform:^id(NSArray* cc) {
        UIColor* color = [UIColor magentaColor];
        if( cc.count == 3 ) {
            color = [UIColor iss_colorWithR:[cc[0] intValue] G:[cc[1] intValue] B:[cc[2] intValue]];
        }
        return color;
    } name:@"rgb"];

    ParcoaParser* rgba = [[Parcoa iss_parameterStringWithPrefix:@"rgba"] transform:^id(NSArray* cc) {
        UIColor* color = [UIColor magentaColor];
        if( cc.count == 4 ) {
            color = [UIColor iss_colorWithR:[cc[0] intValue] G:[cc[1] intValue] B:[cc[2] intValue] A:[cc[3] floatValue]];
        }
        return color;
    } name:@"rgba"];

    NSMutableCharacterSet* hexDigitsSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"aAbBcCdDeEfF"];
    [hexDigitsSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];

    ParcoaParser* hexColor = [[[Parcoa string:@"#"] keepRight:[Parcoa iss_takeUntilInSet:[hexDigitsSet invertedSet] minCount:6]] transform:^id(id value) {
        return [UIColor iss_colorWithHexString:value];
    } name:@"hex"];

    return @[rgb, rgba, hexColor];
}

- (UIColor*) parsePredefColorValue:(id)value {
    UIColor* color = [UIColor magentaColor];
    NSString* colorString = [[value iss_trimQuotes] lowercaseString];
    if( ![colorString hasSuffix:@"color"] ) colorString = [colorString stringByAppendingString:@"color"];

    SEL colorSelector = [ISSRuntimeIntrospectionUtils findSelectorWithCaseInsensitiveName:colorString inClass:UIColor.class];
    if( colorSelector ) {
        color = [UIColor performSelector:colorSelector];
    }

    return color;
}

- (ParcoaParser*) colorFunctionParser:(NSArray*)colorValueParsers preDefColorParser:(ParcoaParser*)preDefColorParser {
    ParcoaParserForward* colorFunctionParserProxy = [ParcoaParserForward forwardWithName:@"colorFunctionParserProxy" summary:@""];
    colorValueParsers = [@[colorFunctionParserProxy] arrayByAddingObjectsFromArray:colorValueParsers];
    colorValueParsers = [colorValueParsers arrayByAddingObject:preDefColorParser];

    ParcoaParser* colorFunctionParser = [[Parcoa sequential:@[identifier, [Parcoa iss_quickUnichar:'(' skipSpace:YES],
        [Parcoa choice:colorValueParsers], [Parcoa iss_quickUnichar:',' skipSpace:YES], anyName, [Parcoa iss_quickUnichar:')' skipSpace:YES]]] transform:^id(id value) {
            UIColor* color = [UIColor magentaColor];
            if( [value[2] isKindOfClass:UIColor.class] ) {
                if( [@"lighten" iss_isEqualIgnoreCase:value[0]] ) color = [value[2] iss_colorByIncreasingBrightnessBy:[value[4] floatValue]];
                else if( [@"darken" iss_isEqualIgnoreCase:value[0]] ) color = [value[2] iss_colorByIncreasingBrightnessBy:-[value[4] floatValue]];
                else if( [@"saturate" iss_isEqualIgnoreCase:value[0]] ) color = [value[2] iss_colorByIncreasingSaturationBy:[value[4] floatValue]];
                else if( [@"desaturate" iss_isEqualIgnoreCase:value[0]] ) color = [value[2] iss_colorByIncreasingSaturationBy:-[value[4] floatValue]];
                else if( [@"fadein" iss_isEqualIgnoreCase:value[0]] ) color = [value[2] iss_colorByIncreasingAlphaBy:[value[4] floatValue]];
                else if( [@"fadeout" iss_isEqualIgnoreCase:value[0]] ) color = [value[2] iss_colorByIncreasingAlphaBy:-[value[4] floatValue]];
                else color = value[2];
            }
            return color;
    } name:@"colorFunctionParser"];
    [colorFunctionParserProxy setImplementation:colorFunctionParser];

    return colorFunctionParserProxy;
}

- (NSArray*) colorCatchAllParser:(ParcoaParser*)imageParser {
    // Parses an arbitrary text string as a predefined color (i.e. redColor) or pattern image from file name - in that order
    ParcoaParser* catchAll = [anyName transform:^id(id value) {
        id color = [self parsePredefColorValue:value];
        if( !color ) {
            UIImage* image = [self imageNamed:value];
            if( image ) return [UIColor colorWithPatternImage:image];
            return [UIColor magentaColor];
        } else {
            return color;
        }
    } name:@"colorCatchAllParser"];

    // Parses well defined image value (i.e. "image(...)") as pattern image
    ParcoaParser* patternImageParser = [imageParser transform:^id(id value) {
        UIColor* color = [UIColor magentaColor];
        if( [value isKindOfClass:UIImage.class] ) color = [UIColor colorWithPatternImage:value];
        return color;
    } name:@"patternImage"];

    return @[patternImageParser, catchAll];
}


#pragma mark - Image parsing

- (ParcoaParser*) imageParsers:(ParcoaParser*)imageParser colorValueParsers:(NSArray*)colorValueParsers {
    ParcoaParser* preDefColorParser = [identifier transform:^id(id value) {
        return [self parsePredefColorValue:value];
    } name:@"preDefColorParser"];

    // Parse color functions as UIImage
    ParcoaParser* colorFunctionParser = [self colorFunctionParser:colorValueParsers preDefColorParser:preDefColorParser];
    ParcoaParser* colorFunctionAsImage = [colorFunctionParser transform:^id(id value) {
        return [value iss_asUIImage];
    } name:@"colorFunctionAsImage"];

    // Parses well defined color values (i.e. [-basicColorValueParsers])
    ParcoaParser* colorParser = [Parcoa choice:colorValueParsers];
    ParcoaParser* imageAsColor = [colorParser transform:^id(id value) {
        return [value iss_asUIImage];
    } name:@"patternImage"];

    ParcoaParser* urlImageParser = [[Parcoa iss_parameterStringWithPrefix:@"url"] transform:^id(NSArray* parameters) {
        return [ISSDownloadableResource downloadableImageWithURL:[NSURL URLWithString:[[parameters firstObject] iss_trimQuotes]]];
    } name:@"urlImage"];

    // Parses an arbitrary text string as an image from file name or pre-defined color name - in that order
    ParcoaParser* catchAll = [anythingButControlChars transform:^id(id value) {
        value = [value iss_trimQuotes];
        UIImage* image = [self imageNamed:value];
        if( !image ) {
            UIColor* color = [self parsePredefColorValue:value];
            if( color ) return [color iss_asUIImage];
            else {
                NSString* lc = [value lowercaseString];
                if ( [lc hasPrefix:@"http://"] || [lc hasPrefix:@"https://"] ) {
                    return [ISSDownloadableResource downloadableImageWithURL:[NSURL URLWithString:value]];
                } else {
                    return [NSNull null];
                }
            }
        } else {
            return image;
        }
    } name:@"imageCatchAllParser"];

    return [Parcoa choice:@[imageParser, colorFunctionAsImage, imageAsColor, urlImageParser, catchAll]];
}

- (ParcoaParser*) colorParser:(NSArray*)colorValueParsers colorCatchAllParsers:(NSArray*)colorCatchAllParsers {
    ParcoaParser* preDefColorParser = [identifier transform:^id(id value) {
        return [self parsePredefColorValue:value];
    } name:@"preDefColorParser"];

    ParcoaParser* colorFunctionParser = [self colorFunctionParser:colorValueParsers preDefColorParser:preDefColorParser];
    colorValueParsers = [@[colorFunctionParser] arrayByAddingObjectsFromArray:colorValueParsers];

    NSArray* parsers = [[@[ colorFunctionParser ] arrayByAddingObjectsFromArray:colorValueParsers] arrayByAddingObject:preDefColorParser];
    ParcoaParser* gradientInputColorParsers = [Parcoa choice:parsers];

    ParcoaParser* gradientParser = [[Parcoa iss_twoParameterFunctionParserWithName:@"gradient" leftParameterParser:gradientInputColorParsers rightParameterParser:gradientInputColorParsers] transform:^id(id value) {
        return [ISSLazyValue lazyValueWithBlock:^id(id uiObject) {
            UIColor* color = [UIColor magentaColor];
            if( [uiObject isKindOfClass:UIView.class] ) {
                CGRect frame = [uiObject frame];
                if( frame.size.height > 0 ) {
                    UIColor* color1 = value[0];
                    UIColor* color2 = value[1];
                    color = [color1 iss_topDownLinearGradientToColor:color2 height:frame.size.height];
                } else color = [UIColor clearColor];
            }
            return color;
        }];
    } name:@"gradient"];

    NSArray* finalColorParsers = [@[gradientParser] arrayByAddingObjectsFromArray:colorValueParsers];
    finalColorParsers = [finalColorParsers arrayByAddingObjectsFromArray:colorCatchAllParsers];
    return [Parcoa choice:finalColorParsers];
}


#pragma mark - Property declarations and value transform

- (ISSPropertyDeclaration*) parsePropertyDeclaration:(NSString*)propertyNameString {
    // Parse parameters
    NSArray* parameters = nil;
    NSRange parentRange = [propertyNameString rangeOfString:@"("];
    if( parentRange.location != NSNotFound ) {
        NSRange endParentRange = [propertyNameString rangeOfString:@")"];
        if( endParentRange.location != NSNotFound ) {
            NSString* paramString = [propertyNameString substringWithRange:NSMakeRange(parentRange.location+1, endParentRange.location - parentRange.location - 1)];
            parameters = [paramString componentsSeparatedByString:@","];
        }
        propertyNameString = [propertyNameString substringToIndex:parentRange.location];
    }

    // Remove any dashes from string and convert to lowercase string, before attempting to find matching ISSPropertyDeclaration
    propertyNameString = [[[propertyNameString iss_trim] stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];

    // Check for any key path in the property name
    NSString* prefixKeyPath = nil;
    NSString* fullKeyPath = nil;
    NSRange dotRange = [propertyNameString rangeOfString:@"." options:NSBackwardsSearch];
    if( dotRange.location != NSNotFound && (dotRange.location+1) < propertyNameString.length ) {
        fullKeyPath = propertyNameString;
        prefixKeyPath = [propertyNameString substringToIndex:dotRange.location];
        propertyNameString = [propertyNameString substringFromIndex:dotRange.location+1];
    }
    
    // Get ISSPropertyDefinition matching property
    ISSPropertyDefinition* property = propertyNameToProperty[propertyNameString];
    if( !property && prefixKeyPath ) property = propertyNameToProperty[fullKeyPath];
    
    // Check if this potentially is a reference to a property in a nested element of the parent element
    NSString* nestedElementKeyPath = nil;
    if( prefixKeyPath && !(property.nameIsKeyPath && [property.name iss_isEqualIgnoreCase:fullKeyPath]) ) { // Make sure key path properties (like "layer.cornerRadius") aren't treated as nested element properties
        nestedElementKeyPath = prefixKeyPath;
    }
    
    // Transform parameters enum values
    if( property.parameterEnumValues && parameters ) {
        NSMutableArray* transformedParameters = [[NSMutableArray alloc] init];
        for(NSUInteger i=0; i<parameters.count; i++) { // Transform parameters to enum values
            NSString* param = [parameters[i] iss_trim];
            if( [param iss_hasData] ) {
                id paramValue = [self parameterEnumValueForString:param inProperty:property];
                if( paramValue ) [transformedParameters addObject:paramValue];
            }
        }
        parameters = transformedParameters;
    }

    if( property ) return [[ISSPropertyDeclaration alloc] initWithProperty:property parameters:parameters nestedElementKeyPath:nestedElementKeyPath];
    else return nil;
}

- (NSString*) replaceVariableReferences:(NSString*)propertyValue {
    NSUInteger location = 0;

    while( location < propertyValue.length ) {
        // Replace any variable references
        NSRange atRange = [propertyValue rangeOfString:@"@" options:0 range:NSMakeRange(location, propertyValue.length - location)];
        if( atRange.location != NSNotFound ) {
            location = atRange.location + atRange.length;

            // @ found, get variable name
            NSRange variableNameRange = NSMakeRange(location, 0);
            for(NSUInteger i=location; i<propertyValue.length; i++) {
                if( [validVariableNameSet characterIsMember:[propertyValue characterAtIndex:i]] ) {
                    variableNameRange.length++;
                } else break;
            }

            id variableValue = nil;
            id variableName = nil;
            if( variableNameRange.length > 0 ) {
                variableName = [propertyValue substringWithRange:variableNameRange];
                variableValue = [[InterfaCSS interfaCSS] valueOfStyleSheetVariableWithName:variableName];
            }
            if( variableValue ) {
                variableValue = [variableValue iss_trimQuotes];
                variableValue = [self replaceVariableReferences:variableValue]; // Resolve nested variables

                // Replace variable occurrence in propertyValue string with variableValue string
                propertyValue = [propertyValue stringByReplacingCharactersInRange:NSMakeRange(atRange.location, variableNameRange.length+1)
                                                                       withString:variableValue];
                location += [variableValue length];
            } else {
                ISSLogWarning(@"Unrecognized property variable: %@ (property value: %@)", variableName, propertyValue);
                location += variableNameRange.length;
            }
        } else break;
    }

    return propertyValue;
}

- (id) parsePropertyValue:(NSString*)propertyValue ofType:(ISSPropertyType)type {
    ParcoaParser* valueParser = typeToParser[@(type)];
    ParcoaResult* result = [valueParser parse:propertyValue];
    if( result.isOK && result.value ) {
        return result.value;
    }
    return nil;
}

- (id) doTransformValue:(NSString*)propertyValue forProperty:(ISSPropertyDefinition*)p {
    // Enum property
    if( p.type == ISSPropertyTypeEnumType ) {
        ParcoaParser* parser;
        if( p.enumBitMaskType ) parser = enumBitMaskValueParser;
        else parser = enumValueParser;
        ParcoaResult* result = [parser parse:propertyValue];
        if( result.isOK ) {
            if( p.enumBitMaskType ) return [self transformEnumBitMaskValues:result.value forProperty:p];
            else return [self transformEnumValue:result.value forProperty:p];
        }
    }
    // Other properties
    else {
        id value = [self parsePropertyValue:propertyValue ofType:p.type];
        if( p.type == ISSPropertyTypeCGColor ) {
            value = (id)((UIColor*)value).CGColor;
        }
        return value;
    }
    return nil;
}

- (id) transformValueWithCaching:(NSString*)propertyValue forProperty:(ISSPropertyDefinition*)p {
    id transformedValue = nil;
    NSMutableDictionary* cache = nil;

    // Caching is not supported for anonymous properties
    if( !p.anonymous ) {
        cache = transformedValueCache[p.uniqueTypeDescription];
        transformedValue = cache[propertyValue];
        if ( !cache ) {
            cache = [[NSMutableDictionary alloc] init];
            transformedValueCache[p.uniqueTypeDescription] = cache;
        }
    }

    // Transform value if not already transformed (and cached)
    if( !transformedValue ) {
        transformedValue = [self doTransformValue:propertyValue forProperty:p];
        if( transformedValue ) { // Update cache with transformed value
            cache[propertyValue] = transformedValue;
        }
    }

    return transformedValue;
}

- (ISSPropertyDeclaration*) transformPropertyPair:(NSArray*)propertyPair {
    if( propertyPair[1] && [propertyPair[1] isKindOfClass:NSString.class] ) {
        NSString* propertyValue = [propertyPair[1] iss_trim];

        propertyValue = [self replaceVariableReferences:propertyValue];

        // Parse property declaration
        ISSPropertyDeclaration* decl = [self parsePropertyDeclaration:propertyPair[0]];
        if( decl ) {
            // Check for special `current` keyword
            BOOL useCurrentValue = [[propertyValue iss_trim] iss_isEqualIgnoreCase:@"current"];

            // Perform lazy transformation of property value
            if( useCurrentValue ) {
                decl.propertyValue = ISSPropertyDefinitionUseCurrentValue;
            } else {
                decl.lazyPropertyTransformationBlock = ^id(ISSPropertyDeclaration* blockDecl) {
                    return [self transformValueWithCaching:propertyValue forProperty:blockDecl.property];
                };
                decl.propertyValue = propertyValue; // Raw value
            }

            return decl;
        }
    }

    ISSPropertyDeclaration* unrecognized = [[ISSPropertyDeclaration alloc] initWithUnrecognizedProperty:propertyPair[0]];
    unrecognized.propertyValue = propertyPair[1];
    ISSLogWarning(@"Unrecognized property '%@' with value: '%@'", propertyPair[0], propertyPair[1]);
    return unrecognized;
}


#pragma mark - Methods existing mainly for testing purposes

- (UIImage*) imageNamed:(NSString*)name { // For testing purposes...
    return [UIImage imageNamed:name];
}

- (NSString*) localizedStringWithKey:(NSString*)key {
    return NSLocalizedString(key, nil);
}


#pragma mark - Misc (property) parsing related

- (NSString*) cleanedStringValue:(NSString*)string {
    return [[string iss_trimQuotes] iss_stringByReplacingUnicodeSequences];
}

- (ParcoaParser*) unrecognizedLineParser {
    return [Parcoa iss_parseLineUpToInvalidCharactersInString:@"{}"];
}

- (UIFont*) fontWithSize:(UIFont*)font size:(CGFloat)size {
    if( [UIFont.class respondsToSelector:@selector(fontWithDescriptor:size:)] ) {
        return [UIFont fontWithDescriptor:font.fontDescriptor size:size];
    } else {
        return [font fontWithSize:size]; // Doesn't seem to work right in iOS7 (for some fonts anyway...)
    }
}

- (BOOL) isRelativeValue:(NSString*)value {
    NSRange r = [value rangeOfString:@"%"];
    return r.location != NSNotFound && r.location > 0;
}

- (CGFloat) rectParamValueFromString:(NSString*)value autoValue:(CGFloat)autoValue relative:(BOOL*)relative {
    BOOL isAuto = [@"auto" iss_isEqualIgnoreCase:value] || [@"*" isEqualToString:value];
    *relative = isAuto || [self isRelativeValue:value];
    return isAuto ? autoValue : [value floatValue];
}

- (void) setRectInsetValueFromString:(NSString*)rawValue onRect:(ISSRectValue*)rectValue insetIndex:(NSUInteger)insetIndex {
    BOOL relativeInsetValue = NO;
    CGFloat insetValue = [self rectParamValueFromString:rawValue autoValue:ISSRectValueAuto relative:&relativeInsetValue];

    if( insetIndex == 0 ) [rectValue setTopInset:insetValue relative:relativeInsetValue];
    else if( insetIndex == 1 ) [rectValue setLeftInset:insetValue relative:relativeInsetValue];
    else if( insetIndex == 2 ) [rectValue setBottomInset:insetValue relative:relativeInsetValue];
    else if( insetIndex == 3 ) [rectValue setRightInset:insetValue relative:relativeInsetValue];
}

- (ISSLayoutAttributeValue*) layoutAttributeValueForElement:(id)elementId attribute:(id)rawAttribute multiplier:(id)rawMultiplier constant:(id)rawConstant {
    CGFloat multiplier = rawMultiplier ? (CGFloat)[rawMultiplier doubleValue] : 1.0f;
    CGFloat constant = (CGFloat)[rawConstant doubleValue];

    // Layout guide:
    if( [elementId iss_isEqualIgnoreCase:@"guide"] || [elementId iss_isEqualIgnoreCase:@"layoutguide"] ) {
        return [ISSLayoutAttributeValue valueRelativeToLayoutGuide:[ISSLayout layoutGuideFromString:rawAttribute] multiplier:multiplier constant:constant];
    }
    // Relative to parent (can either be specified by using parent/superview or by using a percentage value, in which case elementId is nil):
    else if( [elementId iss_isEqualIgnoreCase:@"parent"] || [elementId iss_isEqualIgnoreCase:@"superview"] || (!elementId && rawMultiplier != nil) ) {
        return [ISSLayoutAttributeValue valueRelativeToAttributeInParent:[ISSLayout attributeFromString:rawAttribute] multiplier:multiplier constant:constant];
    }
    // Relative to other view:
    else if( elementId ) {
        return [ISSLayoutAttributeValue valueRelativeToAttribute:[ISSLayout attributeFromString:rawAttribute] inElement:elementId multiplier:multiplier constant:constant];
    }
    // Constant:
    else {
        return [ISSLayoutAttributeValue constantValue:constant];
    }
}

- (ParcoaParser*) layoutAttributeValueParserForAttributeName:(NSString*)attributeName contentParser:(ParcoaParser*)contentParser {
    ISSLayoutAttribute attribute = [ISSLayout attributeFromString:attributeName];
    return [[Parcoa iss_singleParameterFunctionParserWithName:attributeName parameterParser:contentParser] transform:^id(id value) {
        ISSLayoutAttributeValue* attributeValue = value;
        attributeValue.targetAttribute = attribute;
        return attributeValue;
    } name:[NSString stringWithFormat:@"layoutAttributeValueParser(%@)", attributeName]];
}

- (void) compoundLayoutAttributeValueParser:(NSArray*)attributeNames contentParser:(ParcoaParser*)contentParser
                                                       leftAttribute:(ISSLayoutAttribute)leftAttribute rightAttribute:(ISSLayoutAttribute)rightAttribute addToParsers:(NSMutableArray*)parsers {
    [self compoundLayoutAttributeValueParser:attributeNames contentParser:contentParser leftAttribute:leftAttribute rightAttribute:rightAttribute addToParsers:parsers isSizeToFit:NO];
}

- (void) compoundLayoutAttributeValueParser:(NSArray*)attributeNames contentParser:(ParcoaParser*)layoutAttributeValueContentParser
                                                       leftAttribute:(ISSLayoutAttribute)leftAttribute rightAttribute:(ISSLayoutAttribute)rightAttribute addToParsers:(NSMutableArray*)parsers isSizeToFit:(BOOL)sizeToFit {
    for(NSString* attributeName in attributeNames) {
        ParcoaParser* parser = [[Parcoa iss_twoParameterFunctionParserWithName:attributeName leftParameterParser:layoutAttributeValueContentParser rightParameterParser:layoutAttributeValueContentParser] transform:^id(id value) {
            NSArray* values = value;
            ISSLayoutAttributeValue* attributeValueLeft = values[0];
            attributeValueLeft.targetAttribute = leftAttribute;
            ISSLayoutAttributeValue* attributeValueRight = values[1];
            attributeValueRight.targetAttribute = rightAttribute;
            if ( sizeToFit ) {
                return @[ ISSLayoutAttributeSizeToFitFlag, attributeValueLeft, attributeValueRight ];
            } else {
                return @[ attributeValueLeft, attributeValueRight ];
            }
        } name:[NSString stringWithFormat:@"layoutAttributeValueParserForCompoundAttributeName(%@)", attributeName]];

        [parsers addObject:parser];
    }
}

- (void) addLayoutAttributeValue:(id)result layout:(ISSLayout*)layout {
    if( [result isKindOfClass:NSArray.class] ) { // For compound values (i.e. "size" etc)
        for(ISSLayoutAttributeValue* attributeValue in (NSArray*)result) {
            if( attributeValue == ISSLayoutAttributeSizeToFitFlag ) {
                layout.layoutType = ISSLayoutTypeSizeToFit; // "sizeToFit" used
            } else {
                [layout setLayoutAttributeValue:attributeValue];
            }
        }
    } else { // Single attribute: (i.e. "left" etc)
        [layout setLayoutAttributeValue:result];
    }
}

- (ParcoaParser*) simpleNumericParameterStringWithOptionalPrefix:(NSString*)optionalPrefix {
    return [self simpleNumericParameterStringWithPrefix:optionalPrefix optionalPrefix:YES];
}

- (ParcoaParser*) simpleNumericParameterStringWithPrefix:(NSString*)prefix optionalPrefix:(BOOL)optionalPrefix {
    return [self simpleNumericParameterStringWithPrefixes:@[prefix] optionalPrefix:optionalPrefix];
}

- (ParcoaParser*) simpleNumericParameterStringWithPrefixes:(NSArray*)prefixes optionalPrefix:(BOOL)optionalPrefix {
    ParcoaParser* parameterStringWithPrefixParser = [[Parcoa iss_parameterStringWithPrefixes:prefixes] transform:^id(NSArray* parameters) {
        NSMutableArray* result = [NSMutableArray arrayWithCapacity:parameters.count];
        for(NSString* param in parameters) {
            [result addObject:[Parcoa iss_parseMathExpression:param]];
        }
        return result;
    } name:[NSString stringWithFormat:@"simpleNumericParameterStringWithPrefixes(%@)", prefixes]];
                                                     
    if( optionalPrefix ) {
        ParcoaParser* parameterStringParser = [Parcoa sepBy1:numberOrExpressionValue delimiter:[comma skipSurroundingSpaces]];
        return [Parcoa choice:@[parameterStringWithPrefixParser, parameterStringParser]];
    } else {
        return parameterStringWithPrefixParser;
    }
}

#pragma mark - Property parsers setup

- (ParcoaParser*) propertyParsers:(ParcoaParser*)selectorsParser {
    __weak ISSParcoaStyleSheetParser* blockSelf = self;

    propertyNameToProperty = [[NSMutableDictionary alloc] init];
    typeToParser = [[NSMutableDictionary alloc] init];

    // Build dictionary of all known property names mapped to ISSPropertyDefinitions
    ISSPropertyRegistry* registry = [InterfaCSS sharedInstance].propertyRegistry;
    NSSet* allProperties = [registry propertyDefinitions];
    for(ISSPropertyDefinition* p in allProperties) {
        for(NSString* lowerCaseAlias in p.allNames) {
            propertyNameToProperty[lowerCaseAlias] = p;
        }
    }
    
    
    /** -- String -- **/
    
    ParcoaParser* defaultStringParser = [ParcoaParser parserWithBlock:^ParcoaResult*(NSString* input) {
        return [ParcoaResult ok:[self cleanedStringValue:input] residual:nil expected:[ParcoaExpectation unsatisfiable]];
    } name:@"standardStringParser" summary:@"standardStringParser"];
    
    ParcoaParser* cleanedQuotedStringParser = [quotedString transform:^id(id input) {
        return [self cleanedStringValue:input];
    } name:@"quotedStringParser"];
    
    ParcoaParser* localizedStringParser = [[Parcoa iss_singleParameterFunctionParserWithNames:@[@"localized", @"L"] parameterParser:cleanedQuotedStringParser] transform:^id(id value) {
        return [self localizedStringWithKey:value];
    } name:@"localizedStringParser"];
    
    ParcoaParser* stringParser = [Parcoa choice:@[localizedStringParser, cleanedQuotedStringParser, defaultStringParser]];

    typeToParser[@(ISSPropertyTypeString)] = stringParser;


    /** -- BOOL -- **/
    ParcoaParser* boolValueParser = [identifier transform:^id(id value) {
        return @([value boolValue]);
    } name:@"bool"];
    typeToParser[@(ISSPropertyTypeBool)] = [Parcoa choice:@[[Parcoa iss_logicalExpressionParser], boolValueParser]];


    /** -- Number -- **/
    typeToParser[@(ISSPropertyTypeNumber)] = numberOrExpressionValue;


    /** -- AttributedString -- **/
    NSMutableDictionary* attributedStringProperties = [NSMutableDictionary dictionary];
    for(ISSPropertyDefinition* def in [[InterfaCSS interfaCSS].propertyRegistry typePropertyDefinitions:ISSPropertyTypeAttributedString]) {
        for(NSString* lowerCaseAlias in def.allNames) {
            attributedStringProperties[lowerCaseAlias] = def;
        }
    }
    ParcoaParser* attributedStringAttributesParser = [[Parcoa iss_parameterString] transform:^id(NSArray* values) {
        NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
        for(NSString* pairString in values) {
            NSArray* components = [pairString iss_trimmedSplit:@":"];
            if( components.count == 2 && [components[0] iss_hasData] && [components[1] iss_hasData] ) {
                // Get property def
                ISSPropertyDefinition* def = attributedStringProperties[[components[0] lowercaseString]];
                if( def ) {
                    // Parse value
                    id value = [blockSelf doTransformValue:components[1] forProperty:def];
                    if( value ) {
                        // Use standard method in ISSPropertyDefinition to set value (using custom setter block)
                        [def setValue:value onTarget:attributes andParameters:nil];
                    } else {
                        ISSLogWarning(@"Unknown attributed string value `%@` for property `%@`", components[1], components[0]);
                    }
                } else {
                    ISSLogWarning(@"Unknown attributed string property: `%@`", components[0]);
                }
            }
        }
        return attributes;
    } name:@"attributedStringAttributesParser"];

    ParcoaParser* quotedOrLocalizedStringParser = [Parcoa choice:@[localizedStringParser, cleanedQuotedStringParser]];
    
    ParcoaParser* singleAttributedStringParser = [[Parcoa sequential:@[ [quotedOrLocalizedStringParser skipSurroundingSpaces], attributedStringAttributesParser ]] transform:^id(NSArray* values) {
        return [[NSAttributedString alloc] initWithString:values[0] attributes:values[1]];
    } name:@"singleAttributedStringParser"];

    ParcoaParser* delimeter = [Parcoa choice:@[comma, [Parcoa spaces]]];
    ParcoaParser* attributedStringParser = [[Parcoa sepBy1:[singleAttributedStringParser skipSurroundingSpaces] delimiter:delimeter] transform:^id(NSArray* values) {
        NSMutableAttributedString* mutableAttributedString = [[NSMutableAttributedString alloc] init];
        for(NSAttributedString* attributedString in values) {
            [mutableAttributedString appendAttributedString:attributedString];
        }
        return mutableAttributedString;
    } name:@"attributedStringParser"];

    typeToParser[@(ISSPropertyTypeAttributedString)] = attributedStringParser;


    /** -- ISSLayout -- **/
    ParcoaParser* asterisk = [[Parcoa iss_quickUnichar:'*'] skipSurroundingSpaces];
    ParcoaParser* percent = [[Parcoa iss_quickUnichar:'%'] skipSurroundingSpaces];

    ParcoaParser* percentageValue = [[numberValue keepLeft:percent] transform:^id(id value) {
        return @([value doubleValue] / 100.0);
    } name:@"percentageValue"];
    ParcoaParser* multiplierValue = [Parcoa choice:@[percentageValue, numberValue]];

    ParcoaParser* multiplierLeft = [[multiplierValue keepLeft:asterisk] skipSurroundingSpaces];
    ParcoaParser* multiplierRight = [[asterisk keepRight:multiplierValue] skipSurroundingSpaces];

    ParcoaParser* additionalConstant = [numberValue skipSurroundingSpaces];
    ParcoaParser* constantOnlyValue = [numberValue skipSurroundingSpaces];

    ParcoaParser* elementAttribute = [[dot keepRight:identifierOnlyAlphpaAndUnderscore] skipSurroundingSpaces];
    ParcoaParser* elementIdWithPrefix = [[Parcoa iss_quickUnichar:'#'] keepRight:identifierOnlyAlphpaAndUnderscore];
    ParcoaParser* elementId = [Parcoa choice:@[identifierOnlyAlphpaAndUnderscore, quotedIdentifier, elementIdWithPrefix]];


    // A.attr [* 1.5] [+/- 0.5]
    ParcoaParser* layoutAttributeValueFormat1Parser = [[Parcoa sequential:@[elementId, [Parcoa optional:elementAttribute], [Parcoa optional:multiplierRight], [Parcoa optional:additionalConstant]]] transform:^id(id value) {
        return [blockSelf layoutAttributeValueForElement:elementOrNil(value, 0) attribute:elementOrNil(value, 1) multiplier:elementOrNil(value, 2) constant:elementOrNil(value, 3)];
    } name:@"relativeRectValueFormat1Parser"];
    // 1.5 * A.attr [+/- 0,5]
    ParcoaParser* layoutAttributeValueFormat2Parser = [[Parcoa sequential:@[multiplierLeft, elementId, [Parcoa optional:elementAttribute], [Parcoa optional:additionalConstant]]] transform:^id(id value) {
        return [blockSelf layoutAttributeValueForElement:elementOrNil(value, 1) attribute:elementOrNil(value, 2) multiplier:elementOrNil(value, 0) constant:elementOrNil(value, 3)];
    } name:@"relativeRectValueFormat2Parser"];

    ParcoaParser* parentPercentageValue = [percentageValue transform:^id(id value) { // TODO: Should we really have this...?
        return [blockSelf layoutAttributeValueForElement:nil attribute:nil multiplier:value constant:@(0)];
    } name:@"multiplierOrConstant"];
    ParcoaParser* constantValue = [constantOnlyValue transform:^id(id value) {
        return [blockSelf layoutAttributeValueForElement:nil attribute:nil multiplier:nil constant:value];
    } name:@"constantValue"];

    ParcoaParser* layoutAttributeValueContentParser = [Parcoa choice:@[layoutAttributeValueFormat1Parser, layoutAttributeValueFormat2Parser, parentPercentageValue, constantValue]];

    NSMutableArray* layoutAttributeValueParsers = [NSMutableArray array];
    for(NSString* attributeName in [ISSLayout attributeNames]) {
        [layoutAttributeValueParsers addObject:[self layoutAttributeValueParserForAttributeName:attributeName contentParser:layoutAttributeValueContentParser]];
    }

    // Compound attribute parsers
    {
        ParcoaParser* cp = layoutAttributeValueContentParser;
        NSMutableArray* pl =layoutAttributeValueParsers;

        [self compoundLayoutAttributeValueParser:@[ @"size" ] contentParser:cp leftAttribute:ISSLayoutAttributeWidth rightAttribute:ISSLayoutAttributeHeight addToParsers:pl];
        [self compoundLayoutAttributeValueParser:@[ @"sizeToFit" ] contentParser:cp leftAttribute:ISSLayoutAttributeWidth rightAttribute:ISSLayoutAttributeHeight addToParsers:pl isSizeToFit:YES];

        [self compoundLayoutAttributeValueParser:@[ @"leftTop", @"topLeft", @"origin" ] contentParser:cp leftAttribute:ISSLayoutAttributeLeft rightAttribute:ISSLayoutAttributeTop addToParsers:pl];
        [self compoundLayoutAttributeValueParser:@[ @"rightTop", @"topRight" ] contentParser:cp leftAttribute:ISSLayoutAttributeRight rightAttribute:ISSLayoutAttributeTop addToParsers:pl];
        [self compoundLayoutAttributeValueParser:@[ @"leftBottom", @"bottomLeft" ] contentParser:cp leftAttribute:ISSLayoutAttributeLeft rightAttribute:ISSLayoutAttributeBottom addToParsers:pl];
        [self compoundLayoutAttributeValueParser:@[ @"rightBottom", @"bottomRight" ] contentParser:cp leftAttribute:ISSLayoutAttributeRight rightAttribute:ISSLayoutAttributeBottom addToParsers:pl];
        [self compoundLayoutAttributeValueParser:@[ @"center" ] contentParser:cp leftAttribute:ISSLayoutAttributeCenterX rightAttribute:ISSLayoutAttributeCenterY addToParsers:pl];
    }

    // Parse ISSLayout
    ParcoaParser* layoutParserAttributeSeparator = [Parcoa choice:@[[dot skipSurroundingSpaces], [comma skipSurroundingSpaces], [Parcoa spaces]]];
    ParcoaParser* layoutParser = [[[Parcoa choice:layoutAttributeValueParsers] sepBy:layoutParserAttributeSeparator] transform:^id(id values) {
        ISSLayout* layout = [[ISSLayout alloc] init];
        for(id value in (NSArray*)values) {
            [self addLayoutAttributeValue:value layout:layout];
        }
        return layout;
    } name:@"layoutParser"];

    typeToParser[@(ISSPropertyTypeLayout)] = layoutParser;


    /** -- CGRect -- **/
    // Ex: rect(0, 0, 320, 480)
    // Ex: size(320, 480)
    // Ex: size(50%, 70).right(5).top(5)
    // Ex: size(50%, 70).insets(0,0,0,0)
    // Ex: parent (=parent(0,0))
    // Ex: parent(10, 10) // dx, dy - CGRectInset
    // Ex: window (=window(0,0))
    // Ex: window(10, 10) // dx, dy - CGRectInset
    ParcoaParser* parentRectValueParser = [[[Parcoa iss_stringIgnoringCase:@"parent"] or:[Parcoa iss_stringIgnoringCase:@"superview"]] transform:^id(id value) {
        return [ISSRectValue parentRect];
    } name:@"parentRect"];

    ParcoaParser* parentInsetValueParser = [[self simpleNumericParameterStringWithPrefixes:@[ @"parent", @"superview" ] optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSRectValue parentInsetRectWithSize:CGSizeMake(floatAt(c,0), floatAt(c,1))];
        else if( c.count == 4 ) return [ISSRectValue parentInsetRectWithInsets:UIEdgeInsetsMake(floatAt(c,0), floatAt(c,1), floatAt(c,2), floatAt(c,3))];
        else return [ISSRectValue zeroRect];
    } name:@"parentRect.inset"];

    ParcoaParser* windowRectValueParser = [[Parcoa iss_stringIgnoringCase:@"window"] transform:^id(id value) {
        return [ISSRectValue windowRect];
    } name:@"windowRect"];

    ParcoaParser* windowInsetValueParser = [[self simpleNumericParameterStringWithPrefix:@"window" optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSRectValue windowInsetRectWithSize:CGSizeMake(floatAt(c,0), floatAt(c,1))];
        else if( c.count == 4 ) return [ISSRectValue windowInsetRectWithInsets:UIEdgeInsetsMake(floatAt(c,0), floatAt(c,1), floatAt(c,2), floatAt(c,3))];
        else return [ISSRectValue zeroRect];
    } name:@"windowRect.inset"];

    ParcoaParser* rectValueParser = [[self simpleNumericParameterStringWithPrefix:@"rect" optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 4 ) return [ISSRectValue rectWithRect:CGRectMake(floatAt(c,0), floatAt(c,1), floatAt(c,2), floatAt(c,3))];
        else return [ISSRectValue zeroRect];
    } name:@"rect"];

    ParcoaParser* rectSizeValueParser = [[Parcoa iss_parameterStringWithPrefix:@"size"] transform:^id(NSArray* c) {
        if( c.count == 2 ) {
            BOOL relativeWidth = NO;
            CGFloat width = [self rectParamValueFromString:c[0] autoValue:ISSRectValueAuto relative:&relativeWidth];
            BOOL relativeHeight = NO;
            CGFloat height = [self rectParamValueFromString:c[1] autoValue:ISSRectValueAuto relative:&relativeHeight];
            return [ISSRectValue parentRelativeRectWithSize:CGSizeMake(width, height) relativeWidth:relativeWidth relativeHeight:relativeHeight];
        } else {
            return [ISSRectValue zeroRect];
        }
    } name:@"rectSize"];

    ParcoaParser* rectSizeToFitValueParser = [[Parcoa iss_parameterStringWithPrefix:@"sizeToFit"] transform:^id(NSArray* c) {
        if( c.count == 2 ) {
            BOOL relativeWidth = NO;
            CGFloat width = [self rectParamValueFromString:c[0] autoValue:100.0f relative:&relativeWidth]; // Auto is treated as 100% for sizeToFit
            BOOL relativeHeight = NO;
            CGFloat height = [self rectParamValueFromString:c[1] autoValue:100.0f relative:&relativeHeight]; // Auto is treated as 100% for sizeToFit
            return [ISSRectValue parentRelativeSizeToFitRectWithSize:CGSizeMake(width, height) relativeWidth:relativeWidth relativeHeight:relativeHeight];
        } else {
            return [ISSRectValue parentRelativeSizeToFitRectWithSize:CGSizeMake(100.0f, 100.0f) relativeWidth:YES relativeHeight:YES];
        }
    } name:@"rectSizeToFit"];

    ParcoaParser* insetParser = [[Parcoa sequential:@[identifier, [Parcoa iss_quickUnichar:'(' skipSpace:YES], anyName, [Parcoa iss_quickUnichar:')' skipSpace:YES]]] transform:^id(id value) {
        // Use ISSLazyValue to create a typed block container for setting the insets on the ISSRectValue (see below)
        return [ISSLazyValue lazyValueWithBlock:^id(ISSRectValue* rectValue) {
            NSInteger insetIndex = -1;
            if( [@"top" iss_isEqualIgnoreCase:value[0]] ) insetIndex = 0;
            else if( [@"left" iss_isEqualIgnoreCase:value[0]] ) insetIndex = 1;
            else if( [@"bottom" iss_isEqualIgnoreCase:value[0]] ) insetIndex = 2;
            else if( [@"right" iss_isEqualIgnoreCase:value[0]] ) insetIndex = 3;
            else ISSLogWarning(@"Unknown inset: %@", value[0]);

            if( insetIndex > -1 ) [blockSelf setRectInsetValueFromString:value[2] onRect:rectValue insetIndex:(NSUInteger)insetIndex];

            return nil;
        }];
    } name:@"insetParser"];

    ParcoaParser* insetsParser = [[Parcoa iss_parameterStringWithPrefix:@"insets"] transform:^id(NSArray* vals) {
        // Use ISSLazyValue to create a typed block container for setting the insets on the ISSRectValue (see below)
        return [ISSLazyValue lazyValueWithBlock:^id(ISSRectValue* rectValue) {
            if( vals.count == 4 ) {
                [blockSelf setRectInsetValueFromString:vals[0] onRect:rectValue insetIndex:0];
                [blockSelf setRectInsetValueFromString:vals[1] onRect:rectValue insetIndex:1];
                [blockSelf setRectInsetValueFromString:vals[2] onRect:rectValue insetIndex:2];
                [blockSelf setRectInsetValueFromString:vals[3] onRect:rectValue insetIndex:3];
            }
            return nil;
        }];
    } name:@"insets"];

    ParcoaParser* partSeparator = [[Parcoa choice:@[[Parcoa space], dot]] many1];
    ParcoaParser* relativeRectParser = [[[Parcoa choice:@[rectSizeValueParser, rectSizeToFitValueParser, insetParser, insetsParser]] sepBy:partSeparator] transform:^id(id value) {
        ISSRectValue* rectValue = [ISSRectValue zeroRect];
        if( [value isKindOfClass:[NSArray class]] ) {
            ISSRectValue* sizeValue = [ISSRectValue parentRelativeRectWithSize:CGSizeMake(ISSRectValueAuto, ISSRectValueAuto) relativeWidth:YES relativeHeight:YES];
            // Find actual size value (ISSRectValue)
            for(id element in value) {
                if( [element isKindOfClass:ISSRectValue.class] ) {
                    sizeValue = element;
                    break;
                }
            }
            // Evaluate insets
            for(id element in value) {
                if( [element isKindOfClass:ISSLazyValue.class] ) {
                    [element evaluateWithParameter:sizeValue];
                }
            }
            return sizeValue;
        }
        return rectValue;
    } name:@"relativeRectParser"];

    typeToParser[@(ISSPropertyTypeRect)] = [Parcoa choice:@[rectValueParser,
                parentInsetValueParser, parentRectValueParser,
                windowInsetValueParser, windowRectValueParser,
                relativeRectParser, rectSizeValueParser]];


    /** -- UIOffset -- **/
    ParcoaParser* offsetValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"offset"] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [NSValue valueWithUIOffset:UIOffsetMake(floatAt(c,0), floatAt(c,1))];
        else if( c.count == 1 ) return [NSValue valueWithUIOffset:UIOffsetMake(floatAt(c,0), floatAt(c,0))];
        else return [NSValue valueWithUIOffset:UIOffsetZero];
    } name:@"offset"];
    typeToParser[@(ISSPropertyTypeOffset)] = offsetValueParser;


    /** -- CGSize -- **/
    ParcoaParser* sizeValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"size"] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [NSValue valueWithCGSize:CGSizeMake(floatAt(c,0), floatAt(c,1))];
        else if( c.count == 1 ) return [NSValue valueWithCGSize:CGSizeMake(floatAt(c,0), floatAt(c,0))];
        else return [NSValue valueWithCGSize:CGSizeZero];
    } name:@"size"];
    typeToParser[@(ISSPropertyTypeSize)] = sizeValueParser;


    /** -- CGPoint -- **/
    // Ex: point(160, 240)
    // Ex: parent
    // Ex: parent(0, -100)
    // Ex: parent.relative(0, -100)
    ParcoaParser* parentCenterPointValueParser = [[[Parcoa iss_stringIgnoringCase:@"parent"] or:[Parcoa iss_stringIgnoringCase:@"superview"]] transform:^id(id value) {
        return [ISSPointValue parentCenter];
    } name:@"parentCenterPoint"];

    ParcoaParser* parentCenterRelativeValueParser = [[self simpleNumericParameterStringWithPrefixes:@[ @"parent", @"superview" ] optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSPointValue parentRelativeCenterPointWithPoint:CGPointMake(floatAt(c,0), floatAt(c,1))];
        else return [ISSPointValue zeroPoint];
    } name:@"parentCenter.relative"];

    ParcoaParser* windowCenterPointValueParser = [[Parcoa iss_stringIgnoringCase:@"window"] transform:^id(id value) {
        return [ISSPointValue windowCenter];
    } name:@"windowCenterPoint"];

    ParcoaParser* windowCenterRelativeValueParser = [[self simpleNumericParameterStringWithPrefix:@"window" optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSPointValue windowRelativeCenterPointWithPoint:CGPointMake(floatAt(c,0), floatAt(c,1))];
        else return [ISSPointValue zeroPoint];
    } name:@"windowCenter.relative"];

    ParcoaParser* pointValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"point"] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSPointValue pointWithPoint:CGPointMake(floatAt(c,0), floatAt(c,1))];
        else if( c.count == 1 ) return [ISSPointValue pointWithPoint:CGPointMake(floatAt(c,0), floatAt(c,0))];
        else return [ISSPointValue zeroPoint];
    } name:@"point"];

    typeToParser[@(ISSPropertyTypePoint)] = [Parcoa choice:@[pointValueParser,
            parentCenterRelativeValueParser, parentCenterPointValueParser,
            windowCenterRelativeValueParser, windowCenterPointValueParser]];


    /** -- UIEdgeInsets -- **/
    ParcoaParser* insetsValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"insets"] transform:^id(NSArray* c) {
        if( c.count == 4 ) return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(floatAt(c,0), floatAt(c,1), floatAt(c,2), floatAt(c,3))];
        else if( c.count == 2 ) return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(floatAt(c,0), floatAt(c,1), floatAt(c,0), floatAt(c,1))];
        else if( c.count == 1 ) return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(floatAt(c,0), floatAt(c,0), floatAt(c,0), floatAt(c,0))];
        else return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsZero];
    } name:@"insets"];
    typeToParser[@(ISSPropertyTypeEdgeInsets)] = insetsValueParser;


    /** -- UIImage (1) -- **/
    // Ex: image.png
    // Ex: image(image.png);
    // Ex: image(image.png, 1, 2);
    // Ex: image(image.png, 1, 2, 3, 4);
    ParcoaParser* imageParser = [[Parcoa iss_parameterStringWithPrefix:@"image"] transform:^id(NSArray* cc) {
            UIImage* img = nil;
            if( cc.count > 0 ) {
                NSString* imageName = [cc[0] iss_trimQuotes];
                img = [self imageNamed:imageName];
                if( cc.count == 5 ) {
                    img = [img resizableImageWithCapInsets:UIEdgeInsetsMake([cc[1] floatValue], [cc[2] floatValue], [cc[3] floatValue], [cc[4] floatValue])];
                }
#if TARGET_OS_TV == 0
                else if( cc.count == 2 ) {
                    img = [img stretchableImageWithLeftCapWidth:[cc[1] intValue] topCapHeight:[cc[2] intValue]];
                }
#endif
            }
            if( img ) return img;
            else return [NSNull null];
        } name:@"image"];


    /** -- UIColor / CGColor -- **/
    NSArray* colorCatchAllParsers = [self colorCatchAllParser:imageParser];
    NSArray* uiColorValueParsers = [self basicColorValueParsers];
    ParcoaParser* colorPropertyParser = [self colorParser:uiColorValueParsers colorCatchAllParsers:colorCatchAllParsers];
    typeToParser[@(ISSPropertyTypeColor)] = colorPropertyParser;
    typeToParser[@(ISSPropertyTypeCGColor)] = colorPropertyParser;


    /** -- UIImage (2) -- **/
    ParcoaParser* imageParsers = [self imageParsers:imageParser colorValueParsers:uiColorValueParsers];
    typeToParser[@(ISSPropertyTypeImage)] = imageParsers;


    /** -- CGAffineTransform -- **/
    // Ex: rotate(90) scale(2,2) translate(100,100);
    ParcoaParser* rotateValueParser = [[self simpleNumericParameterStringWithPrefix:@"rotate" optionalPrefix:NO] transform:^id(NSArray* values) {
            CGFloat angle = [[values firstObject] floatValue];
            angle = ((CGFloat)M_PI * angle / 180.0f);
            return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(angle)];
        } name:@"rotate"];
    ParcoaParser* scaleValueParser = [[self simpleNumericParameterStringWithPrefix:@"scale" optionalPrefix:NO] transform:^id(NSArray* c) {
            if( c.count == 2 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(floatAt(c,0), floatAt(c,1))];
            else if( c.count == 1 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(floatAt(c,0), floatAt(c,0))];
            else return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
        } name:@"scale"];
    ParcoaParser* translateValueParser = [[self simpleNumericParameterStringWithPrefix:@"translate" optionalPrefix:NO] transform:^id(NSArray* c) {
            if( c.count == 2 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation(floatAt(c,0), floatAt(c,1))];
            else if( c.count == 1 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation(floatAt(c,0), floatAt(c,0))];
            else return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
        } name:@"translate"];
    ParcoaParser* transformValuesParser = [[Parcoa many:[Parcoa choice:@[rotateValueParser, scaleValueParser, translateValueParser]]] transform:^id(id value) {
        CGAffineTransform transform = CGAffineTransformIdentity;
        if( [value isKindOfClass:[NSArray class]] ) {
            if( [value count] == 1 ) transform = [value[0] CGAffineTransformValue];
            else {
                for(NSValue* transformVal in value) {
                    transform = CGAffineTransformConcat(transform, transformVal.CGAffineTransformValue);
                }
            }
        }
        return [NSValue valueWithCGAffineTransform:transform];
    } name:@"transformValues"];
    typeToParser[@(ISSPropertyTypeTransform)] = transformValuesParser;


    /** -- UIFont -- **/
    // Ex: Helvetica 12
    // Ex: bigger(@font, 1)
    // Ex: smaller(@font, 1)
    // Ex: fontWithSize(@font, 12)
    ParcoaParser* commaOrSpace = [[Parcoa choice:@[[Parcoa space], comma]] many1];
    ParcoaParser* remoteFontValueURLParser = [[Parcoa choice:@[quotedString, anyName]] transform:^id(id input) {
        return [NSURL URLWithString:[input iss_trimQuotes]];
    } name:@"remoteFontValueURLParser"];
    ParcoaParser* remoteFontValueParser = [Parcoa iss_singleParameterFunctionParserWithName:@"url" parameterParser:remoteFontValueURLParser];
    ParcoaParser* fontValueParser = [Parcoa choice:@[remoteFontValueParser, quotedString, anyName]];

    fontValueParser = [[fontValueParser keepLeft:commaOrSpace] then:fontValueParser];
    fontValueParser = [fontValueParser transform:^id(NSArray* values) {
#if TARGET_OS_TV == 0
        CGFloat fontSize = [UIFont systemFontSize];
#else
        CGFloat fontSize = 17;
#endif
        NSString* fontName = nil;
        NSURL* remoteFontURL = nil;
        if( [values isKindOfClass:NSArray.class] ) {
            for(id value in values) {
                if( [value isKindOfClass:NSURL.class] ) {
                    remoteFontURL = value;
                    continue;
                }
                else if( ![value isKindOfClass:NSString.class] ) continue;

                NSString* stringVal = value;

                NSString* lc = [stringVal.lowercaseString iss_trim];
                if( [lc hasSuffix:@"pt"] || [lc hasSuffix:@"px"] ) {
                    lc = [lc substringToIndex:lc.length-2];
                }

                if( lc.length > 0 ) {
                    if( lc.iss_isNumeric ) {
                        fontSize = [lc floatValue];
                    } else { // If not pt, px or comma
                        if( [lc hasPrefix:@"http://"] || [lc hasPrefix:@"https://"] ) {
                            remoteFontURL = [NSURL URLWithString:[stringVal iss_trimQuotes]];
                        } else {
                            fontName = [stringVal iss_trimQuotes];
                        }
                    }
                }
            }
        }

        if( remoteFontURL ) return [ISSRemoteFont remoteFontWithURL:remoteFontURL fontSize:fontSize];
        else if( fontName ) return [UIFont fontWithName:fontName size:fontSize];
        else return [UIFont systemFontOfSize:fontSize];
    } name:@"font"];

    ParcoaParser* fontFunctionParser = [[Parcoa sequential:@[identifier, [Parcoa iss_quickUnichar:'(' skipSpace:YES],
        fontValueParser, [Parcoa iss_quickUnichar:',' skipSpace:YES], plainNumber, [Parcoa iss_quickUnichar:')' skipSpace:YES]]] transform:^id(id value) {
            if( [value[2] isKindOfClass:UIFont.class] ) {
                if( [@"larger" iss_isEqualIgnoreCase:value[0]] || [@"bigger" iss_isEqualIgnoreCase:value[0]] ) return [blockSelf fontWithSize:value[2] size:[(UIFont*)value[2] pointSize] + [value[4] floatValue]];
                else if( [@"smaller" iss_isEqualIgnoreCase:value[0]] ) return [blockSelf fontWithSize:value[2] size:[(UIFont*)value[2] pointSize] - [value[4] floatValue]];
                else if( [@"fontWithSize" iss_isEqualIgnoreCase:value[0]] ) return [blockSelf fontWithSize:value[2] size:[value[4] floatValue]];
                else return value[2];
            }
#if TARGET_OS_TV == 0
            return [UIFont systemFontOfSize:[UIFont systemFontSize]];
#else
            return [UIFont systemFontOfSize:17];
#endif
    } name:@"fontFunctionParser"];

    typeToParser[@(ISSPropertyTypeFont)] = [Parcoa choice:@[fontFunctionParser, fontValueParser]];


    /** -- Enums -- **/
    enumValueParser = [Parcoa choice:@[identifier, plainNumber]];
    enumBitMaskValueParser = [enumValueParser sepBy:commaOrSpace];


    /** -- Unrecognized line -- **/
    ParcoaParser* unrecognizedLine = [[self unrecognizedLineParser] transform:^id(id value) {
        if( [value iss_hasData] ) return [ISSStyleSheetParserBadData badDataWithDescription:[NSString stringWithFormat:@"Unrecognized property line: '%@'", [value iss_trim]]];
        else return [NSNull null];
    } name:@"unrecognizedLine"];


    /** -- Property pair -- **/
    ParcoaParser* propertyValueCombined = [[Parcoa sequential:@[quotedStringRaw, anythingButControlCharsExceptColon]] concat];
    ParcoaParser* propertyValue = [Parcoa choice:@[propertyValueCombined, quotedStringRaw, anythingButControlCharsExceptColon]];
    ParcoaParser* propertyPairParser = [[[anythingButControlChars keepLeft:propertyNameValueSeparator] then:[propertyValue keepLeft:semiColonSkipSpace]] transform:^id(id value) {
        ISSPropertyDeclaration* declaration = [blockSelf transformPropertyPair:value];
        // If this declaration contains a reference to a nested element - return a nested ruleset declaration containing the property declaration, instead of the property declaration itself
        if( declaration.nestedElementKeyPath ) {
            ISSSelector* selector = [ISSNestedElementSelector selectorWithNestedElementKeyPath:declaration.nestedElementKeyPath];
            ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[selector]];
            ISSSelectorChainsDeclaration* chains = [ISSSelectorChainsDeclaration selectorChainsWithArray:[@[chain] mutableCopy]];
            chains.properties = [@[declaration]mutableCopy];
            return chains;
        } else {
            return declaration;
        }
    } name:@"propertyPair"];


    // Create parser for unsupported nested declarations, to prevent those to interfere with current declarations
    NSMutableCharacterSet* bracesSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"{}"];
    ParcoaParser* anythingButBraces = [Parcoa iss_takeUntilInSet:bracesSet minCount:1];
    ParcoaParser* unsupportedNestedRulesetParser = [[anythingButBraces then:[anythingButBraces between:openBraceSkipSpace and:closeBraceSkipSpace]] transform:^id(id value) {
        return [ISSStyleSheetParserBadData badDataWithDescription:[NSString stringWithFormat:@"Unsupported nested ruleset: '%@'", value]];
    } name:@"unsupportedNestedRuleset"];

    // Create forward declaration for nested ruleset/declarations parser
    ParcoaParserForward* nestedRulesetParserProxy = [ParcoaParserForward forwardWithName:@"nestedRulesetParserProxy" summary:@""];

    // Property declarations
    ParcoaParser* propertyParser = [Parcoa choice:@[commentParser, propertyPairParser, nestedRulesetParserProxy, unsupportedNestedRulesetParser, unrecognizedLine]];
    propertyParser = [Parcoa iss_safeArray:[propertyParser many]];

    // Create parser for nested declarations (and unsupported nested declarations, to prevent those to interfere with current declarations)
    ParcoaParser* nestedRulesetParser = [[selectorsParser then:[propertyParser between:openBraceSkipSpace and:closeBraceSkipSpace]] transform:^id(id value) {
        ISSSelectorChainsDeclaration* selectorChainsDeclaration = value[0];
        selectorChainsDeclaration.properties = value[1];
        return selectorChainsDeclaration;
    } name:@"nestedRulesetParser"];
    [nestedRulesetParserProxy setImplementation:nestedRulesetParser];

    return propertyParser;
}


#pragma mark - Parser setup

- (id) init {
    if ( (self = [super init]) ) {

        /** Common parsers **/
        dot = [Parcoa iss_quickUnichar:'.'];
        hash = [Parcoa iss_quickUnichar:'#'];
        ParcoaParser* colon = [Parcoa iss_quickUnichar:':'];
        semiColonSkipSpace = [Parcoa iss_quickUnichar:';' skipSpace:YES];
        comma = [Parcoa iss_quickUnichar:','];
        ParcoaParser* openParen = [Parcoa iss_quickUnichar:'('];
        ParcoaParser* closeParen = [Parcoa iss_quickUnichar:')'];
        openBraceSkipSpace = [Parcoa iss_quickUnichar:'{' skipSpace:YES];
        closeBraceSkipSpace = [Parcoa iss_quickUnichar:'}' skipSpace:YES];
        untilSemiColon = [Parcoa iss_takeUntilChar:';'];
        propertyNameValueSeparator = [Parcoa iss_nameValueSeparator];

        anyName = [Parcoa iss_anythingButWhiteSpaceAndExtendedControlChars:1];
        anythingButControlChars = [Parcoa iss_anythingButBasicControlChars:1];
        anythingButControlCharsExceptColon = [Parcoa iss_anythingButBasicControlCharsExceptColon:1];
        identifier = [Parcoa iss_validIdentifierChars:1];
        identifierOnlyAlphpaAndUnderscore = [Parcoa iss_validIdentifierChars:1 onlyAlphpaAndUnderscore:YES];
        anyValue = untilSemiColon;

        plainNumber = [[Parcoa digit] concatMany1];
        ParcoaParser* fraction = [[dot then:plainNumber] concat];
        plainNumber = [[plainNumber then:[Parcoa option:fraction default:@""]] concat];
        ParcoaParser* plus = [[Parcoa iss_quickUnichar:'+'] skipSurroundingSpaces];
        ParcoaParser* minus = [[Parcoa iss_quickUnichar:'-'] skipSurroundingSpaces];
        ParcoaParser* negativeNumber = [[minus keepRight:plainNumber] transform:^id(id value) {
            return @(-[value doubleValue]);
        } name:@"negativeNumber"];
        ParcoaParser* positiveNumber = [plus keepRight:plainNumber];
        positiveNumber = [[Parcoa choice:@[positiveNumber, plainNumber]] transform:^id(id value) {
            return @([value doubleValue]);
        } name:@"positiveNumber"];
        numberValue = [Parcoa choice:@[negativeNumber, positiveNumber]];
        
        numberOrExpressionValue = [Parcoa iss_mathExpressionParser];
        
        ParcoaParser* singleQuote = [Parcoa iss_quickUnichar:'\''];
        ParcoaParser* notSingleQuote = [Parcoa iss_anythingButUnichar:'\'' escapesEnabled:YES];
        ParcoaParser* singleQuotedString = [[[singleQuote keepRight:notSingleQuote] keepLeft:singleQuote] transform:^id(id value) {
            return [NSString stringWithFormat:@"\'%@\'", value];
        } name:@"singleQuotedString"];

        ParcoaParser* doubleQuote = [Parcoa iss_quickUnichar:'\"'];
        ParcoaParser* notDoubleQuote = [Parcoa iss_anythingButUnichar:'\"' escapesEnabled:YES];
        ParcoaParser* doubleQuotedString = [[[doubleQuote keepRight:notDoubleQuote] keepLeft:doubleQuote] transform:^id(id value) {
            return [NSString stringWithFormat:@"\"%@\"", value];
        } name:@"doubleQuotedString"];

        quotedString = [Parcoa choice:@[singleQuotedString, doubleQuotedString]];
        quotedIdentifier = [[[singleQuote keepRight:identifier] keepLeft:singleQuote] or:[[doubleQuote keepRight:identifier] keepLeft:doubleQuote]];
        
        ParcoaParser* notSingleQuoteRaw = [Parcoa iss_anythingButUnichar:'\'' escapesEnabled:NO];
        ParcoaParser* singleQuotedStringRaw = [[[singleQuote keepRight:notSingleQuoteRaw] keepLeft:singleQuote] transform:^id(id value) {
            return [NSString stringWithFormat:@"\'%@\'", value];
        } name:@"singleQuotedStringRaw"];
        
        ParcoaParser* notDoubleQuoteRaw = [Parcoa iss_anythingButUnichar:'\"' escapesEnabled:NO];
        ParcoaParser* doubleQuotedStringRaw = [[[doubleQuote keepRight:notDoubleQuoteRaw] keepLeft:doubleQuote] transform:^id(id value) {
            return [NSString stringWithFormat:@"\"%@\"", value];
        } name:@"doubleQuotedStringRaw"];
        
        quotedStringRaw = [Parcoa choice:@[singleQuotedStringRaw, doubleQuotedStringRaw]];


        /** Comments **/
        commentParser = [[Parcoa iss_commentParser] transform:^id(id value) {
            ISSLogTrace(@"Comment: %@", [value iss_trim]);
            return [NSNull null];
        } name:@"commentParser"];


        /** Variables **/
        validVariableNameSet = [Parcoa iss_validIdentifierCharsSet];
        ParcoaParser* variableParser = [[[[[[Parcoa iss_quickUnichar:'@'] keepRight:identifier] skipSurroundingSpaces] keepLeft:propertyNameValueSeparator] then:[anyValue keepLeft:semiColonSkipSpace]] transform:^id(id value) {
            [[InterfaCSS interfaCSS] setValue:value[1] forStyleSheetVariableWithName:value[0]];
            return value;
        } name:@"variableParser"];


        /** Selectors **/
        // Basic selector fragment parsers:
        ParcoaParser* typeName = [Parcoa choice:@[identifier, [Parcoa iss_quickUnichar:'*']]];
        ParcoaParser* classNameSelector = [dot keepRight:identifier];
        ParcoaParser* elementIdSelector = [hash keepRight:identifier];

        // Pseudo class parsers:
        ParcoaParser* plusOrMinus = [Parcoa choice:@[ [Parcoa iss_quickUnichar:'+'], [Parcoa iss_quickUnichar:'-']]];
        ParcoaParser* pseudoClassParameterParserFull = [[Parcoa sequential:@[
                openParen, [Parcoa spaces], [Parcoa optional:plusOrMinus], [Parcoa optional:plainNumber], [Parcoa iss_quickUnichar:'n'], [Parcoa spaces],
                plusOrMinus, [Parcoa spaces], plainNumber, [Parcoa spaces], closeParen]]
        transform:^id(id value) {
            NSString* aModifier = elementOrNil(value, 2) ?: @"";
            NSString* aValue = elementOrNil(value, 3) ?: @"1";
            NSInteger a = [[aModifier stringByAppendingString:aValue] integerValue];
            NSString* bModifier = elementOrNil(value, 6) ?: @"";
            NSString* bValue = elementOrNil(value, 8);
            NSInteger b = [[bModifier stringByAppendingString:bValue] integerValue];
            return @[@(a), @(b)];
        } name:@"pseudoClassParameterFull"];
        ParcoaParser* pseudoClassParameterParserAN = [[Parcoa sequential:@[
                openParen, [Parcoa spaces], [Parcoa optional:plusOrMinus], [Parcoa optional:plainNumber], [Parcoa iss_quickUnichar:'n'], [Parcoa spaces], closeParen]]
        transform:^id(id value) {
            NSString* aModifier = elementOrNil(value, 2) ?: @"";
            NSString* aValue = elementOrNil(value, 3) ?: @"1";
            NSInteger a = [[aModifier stringByAppendingString:aValue] integerValue];
            return @[@(a), @0];
        } name:@"pseudoClassParameterAN"];
        ParcoaParser* pseudoClassParameterParserEven = [[Parcoa sequential:@[
                openParen, [Parcoa spaces], [Parcoa iss_stringIgnoringCase:@"even"], [Parcoa spaces], closeParen]]
        transform:^id(id value) {
            return @[@2, @0];
        } name:@"pseudoClassParameterEven"];
        ParcoaParser* pseudoClassParameterParserOdd = [[Parcoa sequential:@[
                openParen, [Parcoa spaces], [Parcoa iss_stringIgnoringCase:@"odd"], [Parcoa spaces], closeParen]]
        transform:^id(id value) {
            return @[@2, @1];
        } name:@"pseudoClassParameterOdd"];
        
        ParcoaParser* structuralPseudoClassParameterParsers = [Parcoa choice:@[pseudoClassParameterParserFull, pseudoClassParameterParserAN, pseudoClassParameterParserEven, pseudoClassParameterParserOdd]];
        ParcoaParser* pseudoClassParameterParser = [[Parcoa sequential:@[openParen, [Parcoa spaces], [Parcoa choice:@[quotedString, anyName]], [Parcoa spaces], closeParen]] transform:^id(id value) {
            return [elementOrNil(value, 2) iss_trimQuotes];
        } name:@"pseudoClassParameterParser"];

        ParcoaParser* parameterizedPseudoClassSelector = [[Parcoa sequential:@[colon, identifier, [Parcoa choice:@[structuralPseudoClassParameterParsers, pseudoClassParameterParser]]]] transform:^id(id value) {
            NSString* pseudoClassName = elementOrNil(value, 1) ?: @"";
            id pseudoClassParameters = elementOrNil(value, 2);

            @try {
                ISSPseudoClassType pseudoClassType = [ISSPseudoClass pseudoClassTypeFromString:pseudoClassName];
                
                if( [pseudoClassParameters isKindOfClass:NSArray.class] ) {
                    NSArray* p = pseudoClassParameters;
                    NSInteger a = [p[0] integerValue];
                    NSInteger b = [p[1] integerValue];
                    return [ISSPseudoClass structuralPseudoClassWithA:a b:b type:pseudoClassType];
                } else {
                    return [ISSPseudoClass pseudoClassWithType:pseudoClassType andParameter:pseudoClassParameters];
                }
            } @catch (NSException* e) {
                ISSLogWarning(@"Invalid pseudo class: %@", pseudoClassName);
                return [NSNull null];
            }
        } name:@"parameterizedPseudoClassSelector"];

        ParcoaParser* simplePseudoClassSelector = [[colon keepRight:identifier] transform:^id(id value) {
            NSString* pseudoClassName = value;
            @try {
                return [ISSPseudoClass pseudoClassWithTypeString:pseudoClassName];
            } @catch (NSException* e) {
                ISSLogWarning(@"Invalid pseudo class: %@", pseudoClassName);
                return [NSNull null];
            }
        } name:@"simplePseudoClassSelector"];

        ParcoaParser* pseudoClassSelector = [[Parcoa choice:@[ parameterizedPseudoClassSelector, simplePseudoClassSelector ]] many];


        /* Actual selectors parsers: */

        // type #id .class [:pseudo]
        ParcoaParser* typeSelector1 = [[Parcoa sequential:@[ typeName, elementIdSelector, classNameSelector, [Parcoa optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:elementOrNil(value, 0) elementId:elementOrNil(value, 1) styleClass:elementOrNil(value, 2) pseudoClasses:elementOrNil(value, 3)];
            return selector ?: [NSNull null];
        } name:@"typeSelector1"];

        // type #id [:pseudo]
        ParcoaParser* typeSelector2 = [[Parcoa sequential:@[ typeName, elementIdSelector, [Parcoa optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:elementOrNil(value, 0) elementId:elementOrNil(value, 1) pseudoClasses:elementOrNil(value, 2)];
            return selector ?: [NSNull null];
        } name:@"typeSelector2"];

        // type .class [:pseudo]
        ParcoaParser* typeSelector3 = [[Parcoa sequential:@[ typeName, classNameSelector, [Parcoa optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:elementOrNil(value, 0) styleClass:elementOrNil(value, 1) pseudoClasses:elementOrNil(value, 2)];
            return selector ?: [NSNull null];
        } name:@"typeSelector3"];

        // type [:pseudo]
        ParcoaParser* typeSelector4 = [[Parcoa sequential:@[ typeName, [Parcoa optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:elementOrNil(value, 0) styleClass:nil pseudoClasses:elementOrNil(value, 1)];
            return selector ?: [NSNull null];
        } name:@"typeSelector4"];

        // #id .class [:pseudo]
        ParcoaParser* elementSelector1 = [[Parcoa sequential:@[ elementIdSelector, classNameSelector, [Parcoa optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:nil elementId:elementOrNil(value, 0) styleClass:elementOrNil(value, 1) pseudoClasses:elementOrNil(value, 2)];
            return selector ?: [NSNull null];
        } name:@"elementSelector1"];

        // #id [:pseudo]
        ParcoaParser* elementSelector2 = [[Parcoa sequential:@[ elementIdSelector, [Parcoa optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:nil elementId:elementOrNil(value, 0) styleClass:nil pseudoClasses:elementOrNil(value, 1)];
            return selector ?: [NSNull null];
        } name:@"elementSelector2"];

        // .class [:pseudo]
        ParcoaParser* classSelector = [[Parcoa sequential:@[ classNameSelector, [Parcoa optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:nil styleClass:elementOrNil(value, 0) pseudoClasses:elementOrNil(value, 1)];
            return selector ?: [NSNull null];
        } name:@"classSelector"];

        ParcoaParser* simpleSelector = [Parcoa choice:@[typeSelector1, typeSelector2, typeSelector3, typeSelector4, elementSelector1, elementSelector2, classSelector]];


        // Selector combinator parsers:
        ParcoaParser* descendantCombinator = [[[Parcoa space] many1] transform:^id(id value) {
            return @(ISSSelectorCombinatorDescendant);
        } name:@"descendantCombinator"];
        ParcoaParser* childCombinator = [[Parcoa iss_quickUnichar:'>' skipSpace:YES] transform:^id(id value) {
            return @(ISSSelectorCombinatorChild);
        } name:@"childCombinator"];
        ParcoaParser* adjacentSiblingCombinator = [[Parcoa iss_quickUnichar:'+' skipSpace:YES] transform:^id(id value) {
            return @(ISSSelectorCombinatorAdjacentSibling);
        } name:@"adjacentSiblingCombinator"];
        ParcoaParser* generalSiblingCombinator = [[Parcoa iss_quickUnichar:'~' skipSpace:YES] transform:^id(id value) {
            return @(ISSSelectorCombinatorGeneralSibling);
        } name:@"generalSiblingCombinator"];
        ParcoaParser* combinators = [Parcoa choice:@[generalSiblingCombinator, adjacentSiblingCombinator, childCombinator, descendantCombinator]];

        // Selector chain parsers:
        ParcoaParser* selectorChain = [[simpleSelector sepBy1Keep:combinators] transform:^id(id value) {
            id result = [ISSSelectorChain selectorChainWithComponents:value];
            if( !result ) {
                return [ISSStyleSheetParserBadData badDataWithDescription:[NSString stringWithFormat:@"Invalid selector chain: %@", value]];
            }
            else return result;
        } name:@"selectorChain"];

        ParcoaParser* selectorsChainsDeclaration = [[[selectorChain skipSurroundingSpaces] sepBy1:comma] transform:^id(id value) {
            if( ![value isKindOfClass:NSArray.class] ) value = @[value];
            return [ISSSelectorChainsDeclaration selectorChainsWithArray:value];
        } name:@"selectorsChainsDeclaration"];

        /** Properties **/
        transformedValueCache = [[NSMutableDictionary alloc] init];
        ParcoaParser* propertyDeclarations = [self propertyParsers:selectorsChainsDeclaration];

        /** Ruleset **/
        ParcoaParser* rulesetParser = [[selectorsChainsDeclaration then:[propertyDeclarations between:openBraceSkipSpace and:closeBraceSkipSpace]] transform:^id(id value) {
            ISSSelectorChainsDeclaration* selectorChainsDeclaration = value[0];
            selectorChainsDeclaration.properties = value[1];
            return selectorChainsDeclaration;
        } name:@"rulesetParser"];


        /** Unrecognized content **/
        ParcoaParser* unrecognizedContent = [[self unrecognizedLineParser] transform:^id(id value) {
            if( [value iss_hasData] ) return [ISSStyleSheetParserBadData badDataWithDescription:[NSString stringWithFormat:@"Unrecognized content: '%@'", [value iss_trim]]];
            else return [NSNull null];
        } name:@"unrecognizedContent"];

        cssParser = [[Parcoa choice:@[commentParser, variableParser, rulesetParser, unrecognizedContent]] many];
    }
    return self;
}


#pragma mark - Property declaration processing (setup of nested declarations)

- (void) processProperties:(NSMutableArray*)properties withSelectorChains:(NSArray*)_selectorChains andAddToDeclarations:(NSMutableArray*)declarations {
    NSMutableArray* nestedDeclarations = [[NSMutableArray alloc] init];
    // Make sure selector chains are valid
    NSArray* selectorChains = [_selectorChains filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings) {
        return [evaluatedObject isKindOfClass:ISSSelectorChain.class];
    }]];
    
    if( selectorChains.count ) {
        NSMutableArray* propertyDeclarations = [[NSMutableArray alloc] init];
        for(id entry in properties) {
            ISSSelectorChainsDeclaration* selectorChainsDeclaration = [entry isKindOfClass:ISSSelectorChainsDeclaration.class] ? entry : nil;

            // Bad data:
            if( [entry isKindOfClass:ISSStyleSheetParserBadData.class] ) {
                ISSLogWarning(@"Warning! %@ - in declaration: %@", entry, [[[ISSPropertyDeclarations alloc] initWithSelectorChains:selectorChains andProperties:nil] displayDescription:NO]);
            }
            // Nested property declaration (ISSSelectorChainsDeclaration):
            else if( selectorChainsDeclaration ) {
                // Construct new selector chains by appending selector to parent selector chains
                NSMutableArray* nestedSelectorChains = [[NSMutableArray alloc] init];
                for(ISSSelectorChain* selectorChain in selectorChainsDeclaration.chains) {
                    for(ISSSelectorChain* parentChain in selectorChains) {
                        if( [selectorChain isKindOfClass:ISSSelectorChain.class] ) {
                            [nestedSelectorChains addObject:[parentChain selectorChainByAddingDescendantSelectorChain:selectorChain]];
                        }
                    }
                }

                [nestedDeclarations addObject:@[selectorChainsDeclaration.properties, nestedSelectorChains]];
            }
            // ISSPropertyDeclaration
            else {
                [propertyDeclarations addObject:entry];
            }
        }

        // Add declaration
        [declarations addObject:[[ISSPropertyDeclarations alloc] initWithSelectorChains:selectorChains andProperties:propertyDeclarations]];

        // Process nested declarations
        for(NSArray* declarationPair in nestedDeclarations) {
            [self processProperties:declarationPair[0] withSelectorChains:declarationPair[1] andAddToDeclarations:declarations];
        }
    } else {
        ISSLogWarning(@"No valid selector chains in declaration (count before validation: %d) - properties: %@", _selectorChains.count, properties);
    }
}


#pragma mark - ISSStyleSheet interface

- (NSMutableArray*) parse:(NSString*)styleSheetData {
    ParcoaResult* result = [styleSheetData iss_hasData] ? [cssParser parse:styleSheetData] : nil;
    if( result.isOK ) {
        NSMutableArray* declarations = [NSMutableArray array];

        ISSSelectorChainsDeclaration* lastElement = nil;
        for(id element in result.value) {

            // Valid declaration:
            if( [element isKindOfClass:[ISSSelectorChainsDeclaration class]] ) {
                ISSSelectorChainsDeclaration* selectorChainsDeclaration = element;
                [self processProperties:selectorChainsDeclaration.properties withSelectorChains:selectorChainsDeclaration.chains andAddToDeclarations:declarations];
                lastElement = element;
            }
            // Bad data:
            else if( [element isKindOfClass:ISSStyleSheetParserBadData.class] ) {
                if( lastElement ) {
                    ISSLogWarning(@"Warning! %@ - near %@", element, [lastElement displayDescription]);
                } else {
                    ISSLogWarning(@"Warning! %@ - near beginning of file", element);
                }
            }
        }

        ISSLogTrace(@"Parse result: \n%@", declarations);
        return declarations;
    } else {
        if( [styleSheetData iss_hasData] ) ISSLogWarning(@"Error parsing stylesheet: %@", result);
        else ISSLogWarning(@"Empty/nil stylesheet data!");
        return nil;
    }
}

- (id) transformValue:(NSString*)value asPropertyType:(ISSPropertyType)propertyType {
    return [self transformValue:value asPropertyType:propertyType replaceVariableReferences:YES];
}

- (id) transformValue:(NSString*)value asPropertyType:(ISSPropertyType)propertyType replaceVariableReferences:(BOOL)replaceVariableReferences {
    if( propertyType != ISSPropertyTypeEnumType ) {
        if( replaceVariableReferences ) value = [self replaceVariableReferences:value];
        ISSPropertyDefinition* fauxDef = [[ISSPropertyDefinition alloc] initAnonymousPropertyDefinitionWithType:propertyType];
        return [self doTransformValue:value forProperty:fauxDef];
    } else {
        ISSLogWarning(@"Enum property type not allowed in %s", __PRETTY_FUNCTION__);
        return nil;
    }
}

- (id) transformValue:(NSString*)value forPropertyDefinition:(ISSPropertyDefinition*)propertyDefinition {
    return [self transformValue:value forPropertyDefinition:propertyDefinition replaceVariableReferences:YES];
}

- (id) transformValue:(NSString*)value forPropertyDefinition:(ISSPropertyDefinition*)propertyDefinition replaceVariableReferences:(BOOL)replaceVariableReferences {
    if( replaceVariableReferences ) value = [self replaceVariableReferences:value];
    return [self transformValueWithCaching:value forProperty:propertyDefinition];
}

@end
