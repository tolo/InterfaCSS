//
//  ISSDefaultStyleSheetParser.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSDefaultStyleSheetParser.h"

#import "ISSParser.h"
#import "ISSParser+CSS.h"
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


@interface ISSDeclarationExtension: NSObject
@property (nonatomic, strong, readonly) ISSSelectorChain* extendedDeclaration;
@end
@implementation ISSDeclarationExtension
+ (instancetype) extensionOfDeclaration:(ISSSelectorChain*)extendedDeclaration {
    ISSDeclarationExtension* extensionOfDeclaration = [[ISSDeclarationExtension alloc] init];
    extensionOfDeclaration->_extendedDeclaration = extendedDeclaration;
    return extensionOfDeclaration;
}
@end


/**
 * ISSDefaultStyleSheetParser
 */
@implementation ISSDefaultStyleSheetParser {
    // Common parsers
    ISSParser* dot;
    ISSParser* hash;
    ISSParser* comma;
    ISSParser* openBraceSkipSpace;
    ISSParser* closeBraceSkipSpace;
    ISSParser* identifier;
    ISSParser* anyName;
    ISSParser* anythingButControlChars;
    ISSParser* plainNumber;
    ISSParser* numberValue;
    ISSParser* numberOrExpressionValue;
    ISSParser* quotedString;
    ISSParser* quotedIdentifier;

    NSCharacterSet* validVariableNameSet;

    NSMutableDictionary* propertyNameToProperty;
    NSMutableDictionary* typeToParser;
    ISSParser* enumValueParser;
    ISSParser* enumBitMaskValueParser;
    NSMutableDictionary* transformedValueCache;

    ISSParser* cssParser;
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
        ISSParserStatus status = {};
        id parseResult = [numberValue parse:enumString status:&status];
        if( status.match ) result = parseResult;
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
    ISSParser* rgb = [[ISSParser iss_parameterStringWithPrefix:@"rgb"] transform:^id(NSArray* cc) {
        UIColor* color = [UIColor magentaColor];
        if( cc.count == 3 ) {
            color = [UIColor iss_colorWithR:[cc[0] intValue] G:[cc[1] intValue] B:[cc[2] intValue]];
        }
        return color;
    } name:@"rgb"];

    ISSParser* rgba = [[ISSParser iss_parameterStringWithPrefix:@"rgba"] transform:^id(NSArray* cc) {
        UIColor* color = [UIColor magentaColor];
        if( cc.count == 4 ) {
            color = [UIColor iss_colorWithR:[cc[0] intValue] G:[cc[1] intValue] B:[cc[2] intValue] A:[cc[3] floatValue]];
        }
        return color;
    } name:@"rgba"];

    NSMutableCharacterSet* hexDigitsSetMutable = [NSMutableCharacterSet characterSetWithCharactersInString:@"aAbBcCdDeEfF"];
    [hexDigitsSetMutable formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    NSCharacterSet* hexDigitsSet = [hexDigitsSetMutable copy];

    ISSParser* hexColor = [[[ISSParser unichar:'#'] keepRight:[ISSParser takeWhileInSet:hexDigitsSet minCount:3]] transform:^id(id value) {
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

- (ISSParser*) colorFunctionParser:(NSArray*)colorValueParsers preDefColorParser:(ISSParser*)preDefColorParser {
    ISSParserWrapper* colorFunctionParserProxy = [[ISSParserWrapper alloc] init];
    colorValueParsers = [@[colorFunctionParserProxy] arrayByAddingObjectsFromArray:colorValueParsers];
    colorValueParsers = [colorValueParsers arrayByAddingObject:preDefColorParser];

    ISSParser* colorFunctionParser = [[ISSParser sequential:@[identifier, [ISSParser unichar:'(' skipSpaces:YES],
        [ISSParser choice:colorValueParsers], [ISSParser unichar:',' skipSpaces:YES], anyName, [ISSParser unichar:')' skipSpaces:YES]]] transform:^id(id value) {
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
    colorFunctionParserProxy.wrappedParser = colorFunctionParser;

    return colorFunctionParserProxy;
}

- (NSArray*) colorCatchAllParser:(ISSParser*)imageParser {
    // Parses an arbitrary text string as a predefined color (i.e. redColor) or pattern image from file name - in that order
    ISSParser* catchAll = [anyName transform:^id(id value) {
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
    ISSParser* patternImageParser = [imageParser transform:^id(id value) {
        UIColor* color = [UIColor magentaColor];
        if( [value isKindOfClass:UIImage.class] ) color = [UIColor colorWithPatternImage:value];
        return color;
    } name:@"patternImage"];

    return @[patternImageParser, catchAll];
}


#pragma mark - Image parsing

- (ISSParser*) imageParsers:(ISSParser*)imageParser colorValueParsers:(NSArray*)colorValueParsers {
    ISSParser* preDefColorParser = [identifier transform:^id(id value) {
        return [self parsePredefColorValue:value];
    } name:@"preDefColorParser"];

    // Parse color functions as UIImage
    ISSParser* colorFunctionParser = [self colorFunctionParser:colorValueParsers preDefColorParser:preDefColorParser];
    ISSParser* colorFunctionAsImage = [colorFunctionParser transform:^id(id value) {
        return [value iss_asUIImage];
    } name:@"colorFunctionAsImage"];

    // Parses well defined color values (i.e. [-basicColorValueParsers])
    ISSParser* colorParser = [ISSParser choice:colorValueParsers];
    ISSParser* imageAsColor = [colorParser transform:^id(id value) {
        return [value iss_asUIImage];
    } name:@"patternImage"];

    ISSParser* urlImageParser = [[ISSParser iss_parameterStringWithPrefix:@"url"] transform:^id(NSArray* parameters) {
        return [ISSDownloadableResource downloadableImageWithURL:[NSURL URLWithString:[[parameters firstObject] iss_trimQuotes]]];
    } name:@"urlImage"];

    // Parses an arbitrary text string as an image from file name or pre-defined color name - in that order
    ISSParser* catchAll = [anythingButControlChars transform:^id(id value) {
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

    return [ISSParser choice:@[imageParser, colorFunctionAsImage, imageAsColor, urlImageParser, catchAll]];
}

- (ISSParser*) colorParser:(NSArray*)colorValueParsers colorCatchAllParsers:(NSArray*)colorCatchAllParsers {
    ISSParser* preDefColorParser = [identifier transform:^id(id value) {
        return [self parsePredefColorValue:value];
    } name:@"preDefcolorParser"];

    ISSParser* colorFunctionParser = [self colorFunctionParser:colorValueParsers preDefColorParser:preDefColorParser];
    colorValueParsers = [@[colorFunctionParser] arrayByAddingObjectsFromArray:colorValueParsers];

    NSArray* parsers = [[@[ colorFunctionParser ] arrayByAddingObjectsFromArray:colorValueParsers] arrayByAddingObject:preDefColorParser];
    ISSParser* gradientInputColorParsers = [ISSParser choice:parsers];

    ISSParser* gradientParser = [[ISSParser iss_twoParameterFunctionParserWithName:@"gradient" leftParameterParser:gradientInputColorParsers rightParameterParser:gradientInputColorParsers] transform:^id(id value) {
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
    return [ISSParser choice:finalColorParsers];
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
    ISSParser* valueParser = typeToParser[@(type)];

    ISSParserStatus status = {};
    id parseResult = [valueParser parse:propertyValue status:&status];
    if( status.match ) return parseResult;

    return nil;
}

- (id) doTransformValue:(NSString*)propertyValue forProperty:(ISSPropertyDefinition*)p {
    // Enum property
    if( p.type == ISSPropertyTypeEnumType ) {
        ISSParser* parser;
        if( p.enumBitMaskType ) parser = enumBitMaskValueParser;
        else parser = enumValueParser;

        ISSParserStatus status = {};
        id parseResult = [parser parse:propertyValue status:&status];
        if( status.match ) {
            if( p.enumBitMaskType ) return [self transformEnumBitMaskValues:parseResult forProperty:p];
            else return [self transformEnumValue:parseResult forProperty:p];
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
        NSString* propertyValue = propertyPair[1];

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

- (ISSParser*) unrecognizedLineParser {
    return [ISSParser iss_parseLineUpToInvalidCharactersInString:@"{}"];
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

- (ISSParser*) layoutAttributeValueParserForAttributeName:(NSString*)attributeName contentParser:(ISSParser*)contentParser {
    ISSLayoutAttribute attribute = [ISSLayout attributeFromString:attributeName];
    return [[ISSParser iss_singleParameterFunctionParserWithName:attributeName parameterParser:contentParser] transform:^id(id value) {
        ISSLayoutAttributeValue* attributeValue = value;
        attributeValue.targetAttribute = attribute;
        return attributeValue;
    } name:[NSString stringWithFormat:@"layoutAttributeValueParser(%@)", attributeName]];
}

- (void) compoundLayoutAttributeValueParser:(NSArray*)attributeNames contentParser:(ISSParser*)contentParser
                                                       leftAttribute:(ISSLayoutAttribute)leftAttribute rightAttribute:(ISSLayoutAttribute)rightAttribute addToParsers:(NSMutableArray*)parsers {
    [self compoundLayoutAttributeValueParser:attributeNames contentParser:contentParser leftAttribute:leftAttribute rightAttribute:rightAttribute addToParsers:parsers isSizeToFit:NO];
}

- (void) compoundLayoutAttributeValueParser:(NSArray*)attributeNames contentParser:(ISSParser*)layoutAttributeValueContentParser
                                                       leftAttribute:(ISSLayoutAttribute)leftAttribute rightAttribute:(ISSLayoutAttribute)rightAttribute addToParsers:(NSMutableArray*)parsers isSizeToFit:(BOOL)sizeToFit {
    for(NSString* attributeName in attributeNames) {
        ISSParser* parser = [[ISSParser iss_twoParameterFunctionParserWithName:attributeName leftParameterParser:layoutAttributeValueContentParser rightParameterParser:layoutAttributeValueContentParser] transform:^id(id value) {
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

- (ISSParser*) simpleNumericParameterStringWithOptionalPrefix:(NSString*)optionalPrefix {
    return [self simpleNumericParameterStringWithPrefix:optionalPrefix optionalPrefix:YES];
}

- (ISSParser*) simpleNumericParameterStringWithPrefix:(NSString*)prefix optionalPrefix:(BOOL)optionalPrefix {
    return [self simpleNumericParameterStringWithPrefixes:@[prefix] optionalPrefix:optionalPrefix];
}

- (ISSParser*) simpleNumericParameterStringWithPrefixes:(NSArray*)prefixes optionalPrefix:(BOOL)optionalPrefix {
    ISSParser* parameterStringWithPrefixParser = [[ISSParser iss_parameterStringWithPrefixes:prefixes] transform:^id(NSArray* parameters) {
        NSMutableArray* result = [NSMutableArray arrayWithCapacity:parameters.count];
        for(NSString* param in parameters) {
            [result addObject:[ISSParser iss_parseMathExpression:param] ?: [NSNull null]];
        }
        return result;
    } name:[NSString stringWithFormat:@"simpleNumericParameterStringWithPrefixes(%@)", prefixes]];
                                                     
    if( optionalPrefix ) {
        ISSParser* parameterStringParser = [numberOrExpressionValue sepBy1:[comma skipSurroundingSpaces]];
        return [ISSParser choice:@[parameterStringWithPrefixParser, parameterStringParser]];
    } else {
        return parameterStringWithPrefixParser;
    }
}


#pragma mark - Property parsers setup

- (ISSParser*) propertyParsers:(ISSParser*)selectorsChainsDeclarations commentParser:(ISSParser*)commentParser selectorChainParser:(ISSParser*)selectorChainParser {
    __weak ISSDefaultStyleSheetParser* blockSelf = self;

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
    
    
    /** Common property parsers **/
    ISSParser* identifierOnlyAlphpaAndUnderscore = [ISSParser iss_validIdentifierChars:1 onlyAlphpaAndUnderscore:YES];
    
    
    /** -- String -- **/
    
    ISSParser* defaultStringParser = [ISSParser parserWithBlock:^id(NSString* input, ISSParserStatus* status) {
        status->match = YES;
        return [self cleanedStringValue:input];
    } andName:@"defaultStringParser"];
    
    ISSParser* cleanedQuotedStringParser = [quotedString transform:^id(id input) {
        return [self cleanedStringValue:input];
    } name:@"quotedStringParser"];
    
    ISSParser* localizedStringParser = [[ISSParser iss_singleParameterFunctionParserWithNames:@[@"localized", @"L"] parameterParser:cleanedQuotedStringParser] transform:^id(id value) {
        return [self localizedStringWithKey:value];
    } name:@"localizedStringParser"];
    
    ISSParser* stringParser = [ISSParser choice:@[localizedStringParser, cleanedQuotedStringParser, defaultStringParser]];

    typeToParser[@(ISSPropertyTypeString)] = stringParser;


    /** -- BOOL -- **/
    ISSParser* boolValueParser = [identifier transform:^id(id value) {
        return @([value boolValue]);
    } name:@"bool"];
    typeToParser[@(ISSPropertyTypeBool)] = [ISSParser choice:@[[ISSParser iss_logicalExpressionParser], boolValueParser]];


    /** -- Number -- **/
    typeToParser[@(ISSPropertyTypeNumber)] = numberOrExpressionValue;


    /** -- AttributedString -- **/
    NSMutableDictionary* attributedStringProperties = [NSMutableDictionary dictionary];
    for(ISSPropertyDefinition* def in [[InterfaCSS interfaCSS].propertyRegistry typePropertyDefinitions:ISSPropertyTypeAttributedString]) {
        for(NSString* lowerCaseAlias in def.allNames) {
            attributedStringProperties[lowerCaseAlias] = def;
        }
    }
    ISSParser* attributedStringAttributesParser = [[ISSParser iss_parameterString] transform:^id(NSArray* values) {
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

    ISSParser* quotedOrLocalizedStringParser = [ISSParser choice:@[localizedStringParser, cleanedQuotedStringParser]];
    
    ISSParser* singleAttributedStringParser = [[ISSParser sequential:@[ [quotedOrLocalizedStringParser skipSurroundingSpaces], attributedStringAttributesParser ]] transform:^id(NSArray* values) {
        return [[NSAttributedString alloc] initWithString:values[0] attributes:values[1]];
    } name:@"singleAttributedStringParser"];

    ISSParser* delimeter = [ISSParser choice:@[comma, [ISSParser spaces]]];
    ISSParser* attributedStringParser = [[[singleAttributedStringParser skipSurroundingSpaces] sepBy1:delimeter] transform:^id(NSArray* values) {
        NSMutableAttributedString* mutableAttributedString = [[NSMutableAttributedString alloc] init];
        for(NSAttributedString* attributedString in values) {
            [mutableAttributedString appendAttributedString:attributedString];
        }
        return mutableAttributedString;
    } name:@"attributedStringParser"];

    typeToParser[@(ISSPropertyTypeAttributedString)] = attributedStringParser;


    /** -- ISSLayout -- **/
    ISSParser* asterisk = [ISSParser unichar:'*' skipSpaces:YES];
    ISSParser* percent = [ISSParser unichar:'%' skipSpaces:YES];

    ISSParser* percentageValue = [[numberValue keepLeft:percent] transform:^id(id value) {
        return @([value doubleValue] / 100.0);
    } name:@"percentageValue"];
    ISSParser* multiplierValue = [ISSParser choice:@[percentageValue, numberValue]];

    ISSParser* multiplierLeft = [[multiplierValue keepLeft:asterisk] skipSurroundingSpaces];
    ISSParser* multiplierRight = [[asterisk keepRight:multiplierValue] skipSurroundingSpaces];

    ISSParser* additionalConstant = [numberValue skipSurroundingSpaces];
    ISSParser* constantOnlyValue = [numberValue skipSurroundingSpaces];

    ISSParser* elementAttribute = [[dot keepRight:identifierOnlyAlphpaAndUnderscore] skipSurroundingSpaces];
    ISSParser* elementIdWithPrefix = [[ISSParser unichar:'#'] keepRight:identifierOnlyAlphpaAndUnderscore];
    ISSParser* elementId = [ISSParser choice:@[identifierOnlyAlphpaAndUnderscore, quotedIdentifier, elementIdWithPrefix]];


    // A.attr [* 1.5] [+/- 0.5]
    ISSParser* layoutAttributeValueFormat1Parser = [[ISSParser sequential:@[elementId, [ISSParser optional:elementAttribute], [ISSParser optional:multiplierRight], [ISSParser optional:additionalConstant]]] transform:^id(id value) {
        return [blockSelf layoutAttributeValueForElement:elementOrNil(value, 0) attribute:elementOrNil(value, 1) multiplier:elementOrNil(value, 2) constant:elementOrNil(value, 3)];
    } name:@"relativeRectValueFormat1Parser"];
    // 1.5 * A.attr [+/- 0,5]
    ISSParser* layoutAttributeValueFormat2Parser = [[ISSParser sequential:@[multiplierLeft, elementId, [ISSParser optional:elementAttribute], [ISSParser optional:additionalConstant]]] transform:^id(id value) {
        return [blockSelf layoutAttributeValueForElement:elementOrNil(value, 1) attribute:elementOrNil(value, 2) multiplier:elementOrNil(value, 0) constant:elementOrNil(value, 3)];
    } name:@"relativeRectValueFormat2Parser"];

    ISSParser* parentPercentageValue = [percentageValue transform:^id(id value) { // TODO: Should we really have this...?
        return [blockSelf layoutAttributeValueForElement:nil attribute:nil multiplier:value constant:@(0)];
    } name:@"multiplierOrConstant"];
    ISSParser* constantValue = [constantOnlyValue transform:^id(id value) {
        return [blockSelf layoutAttributeValueForElement:nil attribute:nil multiplier:nil constant:value];
    } name:@"constantValue"];

    ISSParser* layoutAttributeValueContentParser = [ISSParser choice:@[layoutAttributeValueFormat1Parser, layoutAttributeValueFormat2Parser, parentPercentageValue, constantValue]];

    NSMutableArray* layoutAttributeValueParsers = [NSMutableArray array];
    for(NSString* attributeName in [ISSLayout attributeNames]) {
        [layoutAttributeValueParsers addObject:[self layoutAttributeValueParserForAttributeName:attributeName contentParser:layoutAttributeValueContentParser]];
    }

    // Compound attribute parsers
    {
        ISSParser* cp = layoutAttributeValueContentParser;
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
    ISSParser* layoutParserAttributeSeparator = [ISSParser choice:@[[dot skipSurroundingSpaces], [comma skipSurroundingSpaces], [ISSParser spaces]]];
    ISSParser* layoutParser = [[[ISSParser choice:layoutAttributeValueParsers] sepBy:layoutParserAttributeSeparator] transform:^id(id values) {
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
    ISSParser* parentRectValueParser = [[[ISSParser stringEQIgnoringCase:@"parent"] parserOr:[ISSParser stringEQIgnoringCase:@"superview"]] transform:^id(id value) {
        return [ISSRectValue parentRect];
    } name:@"parentRect"];

    ISSParser* parentInsetValueParser = [[self simpleNumericParameterStringWithPrefixes:@[ @"parent", @"superview" ] optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSRectValue parentInsetRectWithSize:CGSizeMake(floatAt(c,0), floatAt(c,1))];
        else if( c.count == 4 ) return [ISSRectValue parentInsetRectWithInsets:UIEdgeInsetsMake(floatAt(c,0), floatAt(c,1), floatAt(c,2), floatAt(c,3))];
        else return [ISSRectValue zeroRect];
    } name:@"parentRect.inset"];

    ISSParser* windowRectValueParser = [[ISSParser stringEQIgnoringCase:@"window"] transform:^id(id value) {
        return [ISSRectValue windowRect];
    } name:@"windowRect"];

    ISSParser* windowInsetValueParser = [[self simpleNumericParameterStringWithPrefix:@"window" optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSRectValue windowInsetRectWithSize:CGSizeMake(floatAt(c,0), floatAt(c,1))];
        else if( c.count == 4 ) return [ISSRectValue windowInsetRectWithInsets:UIEdgeInsetsMake(floatAt(c,0), floatAt(c,1), floatAt(c,2), floatAt(c,3))];
        else return [ISSRectValue zeroRect];
    } name:@"windowRect.inset"];

    ISSParser* rectValueParser = [[self simpleNumericParameterStringWithPrefix:@"rect" optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 4 ) return [ISSRectValue rectWithRect:CGRectMake(floatAt(c,0), floatAt(c,1), floatAt(c,2), floatAt(c,3))];
        else return [ISSRectValue zeroRect];
    } name:@"rect"];

    ISSParser* rectSizeValueParser = [[ISSParser iss_parameterStringWithPrefix:@"size"] transform:^id(NSArray* c) {
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

    ISSParser* rectSizeToFitValueParser = [[ISSParser iss_parameterStringWithPrefix:@"sizeToFit"] transform:^id(NSArray* c) {
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

    ISSParser* insetParser = [[ISSParser sequential:@[identifier, [ISSParser unichar:'(' skipSpaces:YES], anyName, [ISSParser unichar:')' skipSpaces:YES]]] transform:^id(id value) {
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

    ISSParser* insetsParser = [[ISSParser iss_parameterStringWithPrefix:@"insets"] transform:^id(NSArray* vals) {
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

    ISSParser* partSeparator = [[ISSParser choice:@[[ISSParser space], dot]] many1];
    ISSParser* relativeRectParser = [[[ISSParser choice:@[rectSizeValueParser, rectSizeToFitValueParser, insetParser, insetsParser]] sepBy:partSeparator] transform:^id(id value) {
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

    typeToParser[@(ISSPropertyTypeRect)] = [ISSParser choice:@[rectValueParser,
                parentInsetValueParser, parentRectValueParser,
                windowInsetValueParser, windowRectValueParser,
                relativeRectParser, rectSizeValueParser]];


    /** -- UIOffset -- **/
    ISSParser* offsetValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"offset"] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [NSValue valueWithUIOffset:UIOffsetMake(floatAt(c,0), floatAt(c,1))];
        else if( c.count == 1 ) return [NSValue valueWithUIOffset:UIOffsetMake(floatAt(c,0), floatAt(c,0))];
        else return [NSValue valueWithUIOffset:UIOffsetZero];
    } name:@"offset"];
    typeToParser[@(ISSPropertyTypeOffset)] = offsetValueParser;


    /** -- CGSize -- **/
    ISSParser* sizeValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"size"] transform:^id(NSArray* c) {
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
    ISSParser* parentCenterPointValueParser = [[[ISSParser stringEQIgnoringCase:@"parent"] parserOr:[ISSParser stringEQIgnoringCase:@"superview"]] transform:^id(id value) {
        return [ISSPointValue parentCenter];
    } name:@"parentCenterPoint"];

    ISSParser* parentCenterRelativeValueParser = [[self simpleNumericParameterStringWithPrefixes:@[ @"parent", @"superview" ] optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSPointValue parentRelativeCenterPointWithPoint:CGPointMake(floatAt(c,0), floatAt(c,1))];
        else return [ISSPointValue zeroPoint];
    } name:@"parentCenter.relative"];

    ISSParser* windowCenterPointValueParser = [[ISSParser stringEQIgnoringCase:@"window"] transform:^id(id value) {
        return [ISSPointValue windowCenter];
    } name:@"windowCenterPoint"];

    ISSParser* windowCenterRelativeValueParser = [[self simpleNumericParameterStringWithPrefix:@"window" optionalPrefix:NO] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSPointValue windowRelativeCenterPointWithPoint:CGPointMake(floatAt(c,0), floatAt(c,1))];
        else return [ISSPointValue zeroPoint];
    } name:@"windowCenter.relative"];

    ISSParser* pointValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"point"] transform:^id(NSArray* c) {
        if( c.count == 2 ) return [ISSPointValue pointWithPoint:CGPointMake(floatAt(c,0), floatAt(c,1))];
        else if( c.count == 1 ) return [ISSPointValue pointWithPoint:CGPointMake(floatAt(c,0), floatAt(c,0))];
        else return [ISSPointValue zeroPoint];
    } name:@"point"];

    typeToParser[@(ISSPropertyTypePoint)] = [ISSParser choice:@[pointValueParser,
            parentCenterRelativeValueParser, parentCenterPointValueParser,
            windowCenterRelativeValueParser, windowCenterPointValueParser]];


    /** -- UIEdgeInsets -- **/
    ISSParser* insetsValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"insets"] transform:^id(NSArray* c) {
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
    ISSParser* imageParser = [[ISSParser iss_parameterStringWithPrefix:@"image"] transform:^id(NSArray* cc) {
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
    ISSParser* colorPropertyParser = [self colorParser:uiColorValueParsers colorCatchAllParsers:colorCatchAllParsers];
    typeToParser[@(ISSPropertyTypeColor)] = colorPropertyParser;
    typeToParser[@(ISSPropertyTypeCGColor)] = colorPropertyParser;


    /** -- UIImage (2) -- **/
    ISSParser* imageParsers = [self imageParsers:imageParser colorValueParsers:uiColorValueParsers];
    typeToParser[@(ISSPropertyTypeImage)] = imageParsers;


    /** -- CGAffineTransform -- **/
    // Ex: rotate(90) scale(2,2) translate(100,100);
    ISSParser* rotateValueParser = [[self simpleNumericParameterStringWithPrefix:@"rotate" optionalPrefix:NO] transform:^id(NSArray* values) {
            CGFloat angle = [[values firstObject] floatValue];
            angle = ((CGFloat)M_PI * angle / 180.0f);
            return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(angle)];
        } name:@"rotate"];
    ISSParser* scaleValueParser = [[self simpleNumericParameterStringWithPrefix:@"scale" optionalPrefix:NO] transform:^id(NSArray* c) {
            if( c.count == 2 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(floatAt(c,0), floatAt(c,1))];
            else if( c.count == 1 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(floatAt(c,0), floatAt(c,0))];
            else return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
        } name:@"scale"];
    ISSParser* translateValueParser = [[self simpleNumericParameterStringWithPrefix:@"translate" optionalPrefix:NO] transform:^id(NSArray* c) {
            if( c.count == 2 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation(floatAt(c,0), floatAt(c,1))];
            else if( c.count == 1 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation(floatAt(c,0), floatAt(c,0))];
            else return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
        } name:@"translate"];
    ISSParser* transformValuesParser = [[[ISSParser choice:@[rotateValueParser, scaleValueParser, translateValueParser]] many] transform:^id(id value) {
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
    ISSParser* commaOrSpace = [[ISSParser choice:@[[ISSParser space], comma]] many1];
    ISSParser* remoteFontValueURLParser = [[ISSParser choice:@[quotedString, anyName]] transform:^id(id input) {
        return [NSURL URLWithString:[input iss_trimQuotes]];
    } name:@"remoteFontValueURLParser"];
    ISSParser* remoteFontValueParser = [ISSParser iss_singleParameterFunctionParserWithName:@"url" parameterParser:remoteFontValueURLParser];
    ISSParser* fontValueParser = [ISSParser choice:@[remoteFontValueParser, quotedString, anyName]];

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

    ISSParser* fontFunctionParser = [[ISSParser sequential:@[identifier, [ISSParser unichar:'(' skipSpaces:YES],
        fontValueParser, [ISSParser unichar:',' skipSpaces:YES], plainNumber, [ISSParser unichar:')' skipSpaces:YES]]] transform:^id(id value) {
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

    typeToParser[@(ISSPropertyTypeFont)] = [ISSParser choice:@[fontFunctionParser, fontValueParser]];


    /** -- Enums -- **/
    enumValueParser = [ISSParser choice:@[identifier, plainNumber]];
    enumBitMaskValueParser = [enumValueParser sepBy:commaOrSpace];


    /** -- Unrecognized line -- **/
    ISSParser* unrecognizedLine = [[self unrecognizedLineParser] transform:^id(id value) {
        if( [value iss_hasData] ) return [ISSStyleSheetParserBadData badDataWithDescription:[NSString stringWithFormat:@"Unrecognized property line: '%@'", [value iss_trim]]];
        else return [NSNull null];
    } name:@"unrecognizedLine"];


    /** -- Property pair -- **/
    ISSParser* propertyPairParser = [[ISSParser iss_propertyPairParser:NO] transform:^id(id value) {
        ISSPropertyDeclaration* declaration = [blockSelf transformPropertyPair:value];
        // If this declaration contains a reference to a nested element - return a nested ruleset declaration containing the property declaration, instead of the property declaration itself
        if( declaration.nestedElementKeyPath ) {
            ISSSelector* nestedElementSelector = [ISSNestedElementSelector selectorWithNestedElementKeyPath:declaration.nestedElementKeyPath];
            ISSSelectorChain* chain = [ISSSelectorChain selectorChainWithComponents:@[nestedElementSelector]];
            ISSSelectorChainsDeclaration* chains = [ISSSelectorChainsDeclaration selectorChainsWithArray:[@[chain] mutableCopy]];
            chains.properties = [@[declaration] mutableCopy];
            return chains;
        } else {
            return declaration;
        }
    } name:@"propertyPair"];


    /** -- Extension/Inheritance -- **/
    ISSParser* extendDeclarationParser = [[ISSParser sequential:@[[ISSParser stringEQIgnoringCase:@"@extend"], [ISSParser spaces], selectorChainParser, [ISSParser unichar:';' skipSpaces:YES]]] transform:^id(id value) {
        ISSSelectorChain* selectorChain = elementOrNil(value, 2);
        return [ISSDeclarationExtension extensionOfDeclaration:selectorChain];
    } name:@"pseudoClassParameterParser"];


        
    // Create parser for unsupported nested declarations, to prevent those to interfere with current declarations
    NSCharacterSet* bracesSet = [NSCharacterSet characterSetWithCharactersInString:@"{}"];
    ISSParser* anythingButBraces = [ISSParser takeUntilInSet:bracesSet minCount:1];
    ISSParser* unsupportedNestedRulesetParser = [[anythingButBraces then:[anythingButBraces between:openBraceSkipSpace and:closeBraceSkipSpace]] transform:^id(id value) {
        return [ISSStyleSheetParserBadData badDataWithDescription:[NSString stringWithFormat:@"Unsupported nested ruleset: '%@'", value]];
    } name:@"unsupportedNestedRuleset"];

        
    // Create forward declaration for nested ruleset/declarations parser
    ISSParserWrapper* nestedRulesetParserProxy = [[ISSParserWrapper alloc] init];

    // Property declarations
    ISSParser* propertyParser = [ISSParser choice:@[commentParser, propertyPairParser, nestedRulesetParserProxy, extendDeclarationParser, unsupportedNestedRulesetParser, unrecognizedLine]];
    propertyParser = [propertyParser manyActualValues];
    
    // Create parser for nested declarations
    ISSParser* nestedRulesetParser = [self rulesetParserWithContentParser:propertyParser selectorsChainsDeclarations:selectorsChainsDeclarations];

    nestedRulesetParserProxy.wrappedParser = nestedRulesetParser;

    return propertyParser;
}

- (ISSParser*) rulesetParserWithContentParser:(ISSParser*)rulesetContentParser selectorsChainsDeclarations:(ISSParser*)selectorsChainsDeclarations {
    return [[selectorsChainsDeclarations then:[rulesetContentParser between:openBraceSkipSpace and:closeBraceSkipSpace]] transform:^id(id value) {
        ISSSelectorChainsDeclaration* selectorChainsDeclaration = value[0];
        selectorChainsDeclaration.properties = value[1];
        return selectorChainsDeclaration;
    } name:@"rulesetParser"];
}


#pragma mark - Parser setup

- (id) init {
    if ( (self = [super init]) ) {
        
        /** Common parsers **/
        dot = [ISSParser unichar:'.'];
        hash = [ISSParser unichar:'#'];
        comma = [ISSParser unichar:','];
        openBraceSkipSpace = [ISSParser unichar:'{' skipSpaces:YES];
        closeBraceSkipSpace = [ISSParser unichar:'}' skipSpaces:YES];
        
        identifier = [ISSParser iss_validIdentifierChars:1];
        anyName = [ISSParser iss_anythingButWhiteSpaceAndExtendedControlChars:1];
        anythingButControlChars = [ISSParser iss_anythingButBasicControlChars:1];
        
        plainNumber = [[ISSParser digit] concatMany1];
        ISSParser* fraction = [[dot then:plainNumber] concat];
        plainNumber = [[plainNumber then:[ISSParser optional:fraction defaultValue:@""]] concat];
        
        ISSParser* plus = [ISSParser unichar:'+' skipSpaces:YES];
        ISSParser* minus = [ISSParser unichar:'-' skipSpaces:YES];
        ISSParser* negativeNumber = [[minus keepRight:plainNumber] transform:^id(id value) {
            return @(-[value doubleValue]);
        } name:@"negativeNumber"];
        ISSParser* positiveNumber = [plus keepRight:plainNumber];
        positiveNumber = [[ISSParser choice:@[positiveNumber, plainNumber]] transform:^id(id value) {
            return @([value doubleValue]);
        } name:@"positiveNumber"];
        numberValue = [ISSParser choice:@[negativeNumber, positiveNumber]];
        
        numberOrExpressionValue = [ISSParser iss_mathExpressionParser];
        
        ISSParser* singleQuote = [ISSParser unichar:'\''];
        ISSParser* notSingleQuote = [ISSParser stringWithEscapesUpToUnichar:'\''];
        ISSParser* singleQuotedString = [[[singleQuote keepRight:notSingleQuote] keepLeft:singleQuote] transform:^id(id value) {
            return [NSString stringWithFormat:@"\'%@\'", value];
        } name:@"singleQuotedString"];
        
        ISSParser* doubleQuote = [ISSParser unichar:'\"'];
        ISSParser* notDoubleQuote = [ISSParser stringWithEscapesUpToUnichar:'\"'];
        ISSParser* doubleQuotedString = [[[doubleQuote keepRight:notDoubleQuote] keepLeft:doubleQuote] transform:^id(id value) {
            return [NSString stringWithFormat:@"\"%@\"", value];
        } name:@"doubleQuotedString"];
        
        quotedString = [ISSParser choice:@[singleQuotedString, doubleQuotedString]];
        quotedIdentifier = [[[singleQuote keepRight:identifier] keepLeft:singleQuote] parserOr:[[doubleQuote keepRight:identifier] keepLeft:doubleQuote]];
        
        
        
        /** Ruleset parser setup **/
        ISSParser* colon = [ISSParser unichar:':'];
        ISSParser* openParen = [ISSParser unichar:'('];
        ISSParser* closeParen = [ISSParser unichar:')'];


        /** Comments **/
        ISSParser* commentParser = [[ISSParser iss_commentParser] transform:^id(id value) {
            ISSLogTrace(@"Comment: %@", [value iss_trim]);
            return [NSNull null];
        } name:@"commentParser"];


        /** Variables **/
        validVariableNameSet = [ISSParser iss_validIdentifierCharsSet];
        ISSParser* variableParser = [[ISSParser iss_propertyPairParser:YES] transform:^id(id value) {
            [[InterfaCSS interfaCSS] setValue:value[1] forStyleSheetVariableWithName:value[0]];
            return [NSNull null];
        } name:@"variableParser"];


        /** Selectors **/
        // Basic selector fragment parsers:
        ISSParser* typeName = [ISSParser choice:@[identifier, [ISSParser unichar:'*']]];
        ISSParser* classNamesSelector = [[dot keepRight:identifier] many1];
        ISSParser* elementIdSelector = [hash keepRight:identifier];

        // Pseudo class parsers:
        ISSParser* plusOrMinus = [ISSParser choice:@[ [ISSParser unichar:'+'], [ISSParser unichar:'-']]];
        ISSParser* pseudoClassParameterParserFull = [[ISSParser sequential:@[
                openParen, [ISSParser spaces], [ISSParser optional:plusOrMinus], [ISSParser optional:plainNumber], [ISSParser unichar:'n'], [ISSParser spaces],
                plusOrMinus, [ISSParser spaces], plainNumber, [ISSParser spaces], closeParen]]
        transform:^id(id value) {
            NSString* aModifier = elementOrNil(value, 2) ?: @"";
            NSString* aValue = elementOrNil(value, 3) ?: @"1";
            NSInteger a = [[aModifier stringByAppendingString:aValue] integerValue];
            NSString* bModifier = elementOrNil(value, 6) ?: @"";
            NSString* bValue = elementOrNil(value, 8);
            NSInteger b = [[bModifier stringByAppendingString:bValue] integerValue];
            return @[@(a), @(b)];
        } name:@"pseudoClassParameterFull"];
        ISSParser* pseudoClassParameterParserAN = [[ISSParser sequential:@[
                openParen, [ISSParser spaces], [ISSParser optional:plusOrMinus], [ISSParser optional:plainNumber], [ISSParser unichar:'n'], [ISSParser spaces], closeParen]]
        transform:^id(id value) {
            NSString* aModifier = elementOrNil(value, 2) ?: @"";
            NSString* aValue = elementOrNil(value, 3) ?: @"1";
            NSInteger a = [[aModifier stringByAppendingString:aValue] integerValue];
            return @[@(a), @0];
        } name:@"pseudoClassParameterAN"];
        ISSParser* pseudoClassParameterParserEven = [[ISSParser sequential:@[
                openParen, [ISSParser spaces], [ISSParser stringEQIgnoringCase:@"even"], [ISSParser spaces], closeParen]]
        transform:^id(id value) {
            return @[@2, @0];
        } name:@"pseudoClassParameterEven"];
        ISSParser* pseudoClassParameterParserOdd = [[ISSParser sequential:@[
                openParen, [ISSParser spaces], [ISSParser stringEQIgnoringCase:@"odd"], [ISSParser spaces], closeParen]]
        transform:^id(id value) {
            return @[@2, @1];
        } name:@"pseudoClassParameterOdd"];
        
        ISSParser* structuralPseudoClassParameterParsers = [ISSParser choice:@[pseudoClassParameterParserFull, pseudoClassParameterParserAN, pseudoClassParameterParserEven, pseudoClassParameterParserOdd]];
        ISSParser* pseudoClassParameterParser = [[ISSParser sequential:@[openParen, [ISSParser spaces], [ISSParser choice:@[quotedString, anyName]], [ISSParser spaces], closeParen]] transform:^id(id value) {
            return [elementOrNil(value, 2) iss_trimQuotes];
        } name:@"pseudoClassParameterParser"];

        ISSParser* parameterizedPseudoClassSelector = [[ISSParser sequential:@[colon, identifier, [ISSParser choice:@[structuralPseudoClassParameterParsers, pseudoClassParameterParser]]]] transform:^id(id value) {
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

        ISSParser* simplePseudoClassSelector = [[colon keepRight:identifier] transform:^id(id value) {
            NSString* pseudoClassName = value;
            @try {
                return [ISSPseudoClass pseudoClassWithTypeString:pseudoClassName];
            } @catch (NSException* e) {
                ISSLogWarning(@"Invalid pseudo class: %@", pseudoClassName);
                return [NSNull null];
            }
        } name:@"simplePseudoClassSelector"];

        ISSParser* pseudoClassSelector = [[ISSParser choice:@[ parameterizedPseudoClassSelector, simplePseudoClassSelector ]] many];


        /* Actual selectors parsers: */

        // type #id .class [:pseudo]
        ISSParser* typeSelector1 = [[ISSParser sequential:@[ typeName, elementIdSelector, classNamesSelector, [ISSParser optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:elementOrNil(value, 0) elementId:elementOrNil(value, 1) styleClasses:elementOrNil(value, 2) pseudoClasses:elementOrNil(value, 3)];
            return selector ?: [NSNull null];
        } name:@"typeSelector1"];

        // type #id [:pseudo]
        ISSParser* typeSelector2 = [[ISSParser sequential:@[ typeName, elementIdSelector, [ISSParser optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:elementOrNil(value, 0) elementId:elementOrNil(value, 1) pseudoClasses:elementOrNil(value, 2)];
            return selector ?: [NSNull null];
        } name:@"typeSelector2"];

        // type .class [:pseudo]
        ISSParser* typeSelector3 = [[ISSParser sequential:@[ typeName, classNamesSelector, [ISSParser optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:elementOrNil(value, 0) styleClasses:elementOrNil(value, 1) pseudoClasses:elementOrNil(value, 2)];
            return selector ?: [NSNull null];
        } name:@"typeSelector3"];

        // type [:pseudo]
        ISSParser* typeSelector4 = [[ISSParser sequential:@[ typeName, [ISSParser optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:elementOrNil(value, 0) styleClass:nil pseudoClasses:elementOrNil(value, 1)];
            return selector ?: [NSNull null];
        } name:@"typeSelector4"];

        // #id .class [:pseudo]
        ISSParser* elementSelector1 = [[ISSParser sequential:@[ elementIdSelector, classNamesSelector, [ISSParser optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:nil elementId:elementOrNil(value, 0) styleClasses:elementOrNil(value, 1) pseudoClasses:elementOrNil(value, 2)];
            return selector ?: [NSNull null];
        } name:@"elementSelector1"];

        // #id [:pseudo]
        ISSParser* elementSelector2 = [[ISSParser sequential:@[ elementIdSelector, [ISSParser optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:nil elementId:elementOrNil(value, 0) styleClass:nil pseudoClasses:elementOrNil(value, 1)];
            return selector ?: [NSNull null];
        } name:@"elementSelector2"];

        // .class [:pseudo]
        ISSParser* classSelector = [[ISSParser sequential:@[ classNamesSelector, [ISSParser optional:pseudoClassSelector] ]] transform:^id(id value) {
            ISSSelector* selector = [ISSSelector selectorWithType:nil styleClasses:elementOrNil(value, 0) pseudoClasses:elementOrNil(value, 1)];
            return selector ?: [NSNull null];
        } name:@"classSelector"];

        ISSParser* simpleSelector = [ISSParser choice:@[typeSelector1, typeSelector2, typeSelector3, typeSelector4, elementSelector1, elementSelector2, classSelector]];


        // Selector combinator parsers:
        ISSParser* descendantCombinator = [[[ISSParser space] many1] transform:^id(id value) {
            return @(ISSSelectorCombinatorDescendant);
        } name:@"descendantCombinator"];
        ISSParser* childCombinator = [[ISSParser unichar:'>' skipSpaces:YES] transform:^id(id value) {
            return @(ISSSelectorCombinatorChild);
        } name:@"childCombinator"];
        ISSParser* adjacentSiblingCombinator = [[ISSParser unichar:'+' skipSpaces:YES] transform:^id(id value) {
            return @(ISSSelectorCombinatorAdjacentSibling);
        } name:@"adjacentSiblingCombinator"];
        ISSParser* generalSiblingCombinator = [[ISSParser unichar:'~' skipSpaces:YES] transform:^id(id value) {
            return @(ISSSelectorCombinatorGeneralSibling);
        } name:@"generalSiblingCombinator"];
        ISSParser* combinators = [ISSParser choice:@[generalSiblingCombinator, adjacentSiblingCombinator, childCombinator, descendantCombinator]];

        
        // Selector chain parsers:
        ISSParser* selectorChain = [[simpleSelector sepBy1Keep:combinators] transform:^id(NSArray* value) {
            id result = [ISSSelectorChain selectorChainWithComponents:value];
            if( !result ) {
                return [ISSStyleSheetParserBadData badDataWithDescription:[NSString stringWithFormat:@"Invalid selector chain: %@", [value componentsJoinedByString:@" "]]];
            }
            else return result;
        } name:@"selectorChain"];
        
        ISSParser* selectorsChainsDeclarations = [[[selectorChain skipSurroundingSpaces] sepBy1:comma] transform:^id(id value) {
            if( ![value isKindOfClass:NSArray.class] ) value = @[value];
            return [ISSSelectorChainsDeclaration selectorChainsWithArray:value];
        } name:@"selectorsChainsDeclaration"];
        

        /** Properties **/
        transformedValueCache = [[NSMutableDictionary alloc] init];
        ISSParser* propertyDeclarations = [self propertyParsers:selectorsChainsDeclarations commentParser:commentParser selectorChainParser:selectorChain];

        
        /** Ruleset **/
        ISSParser* rulesetParser = [self rulesetParserWithContentParser:propertyDeclarations selectorsChainsDeclarations:selectorsChainsDeclarations];


        /** Unrecognized content **/
        ISSParser* unrecognizedContent = [[self unrecognizedLineParser] transform:^id(id value) {
            if( [value iss_hasData] ) return [ISSStyleSheetParserBadData badDataWithDescription:[NSString stringWithFormat:@"Unrecognized content: '%@'", [value iss_trim]]];
            else return [NSNull null];
        } name:@"unrecognizedContent"];

        cssParser = [[ISSParser choice:@[commentParser, variableParser, rulesetParser, unrecognizedContent]] manyActualValues];
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
        ISSSelectorChain* extendedDeclarationSelectorChain = nil;

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
            // ISSDeclarationExtension
            else if( [entry isKindOfClass:ISSDeclarationExtension.class] ) {
                extendedDeclarationSelectorChain = ((ISSDeclarationExtension*)entry).extendedDeclaration;
            }
            // ISSPropertyDeclaration
            else {
                [propertyDeclarations addObject:entry];
            }
        }

        // Add declaration
        [declarations addObject:[[ISSPropertyDeclarations alloc] initWithSelectorChains:selectorChains andProperties:propertyDeclarations extendedDeclarationSelectorChain:extendedDeclarationSelectorChain]];

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
    ISSParserStatus status = {};
    id result = [styleSheetData iss_hasData] ? [cssParser parse:styleSheetData status:&status] : nil;
    if( status.match ) {
        NSMutableArray* declarations = [NSMutableArray array];
        ISSSelectorChainsDeclaration* lastElement = nil;
        
        for(id element in result) {
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
