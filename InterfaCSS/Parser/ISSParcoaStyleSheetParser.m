//
//  ISSParcoaStyleSheetParser.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2013-06-14.
//  Copyright (c) 2013 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSParcoaStyleSheetParser.h"

#import <objc/runtime.h>
#import "Parcoa.h"

#import "Parcoa+ISSAdditions.h"
#import "ISSSelector.h"
#import "ISSSelectorChain.h"
#import "ISSPropertyDeclarations.h"
#import "ISSPropertyDeclaration.h"
#import "ISSPropertyDefinition.h"
#import "NSObject+ISSLogSupport.h"
#import "NSString+ISSStringAdditions.h"
#import "UIColor+ISSColorAdditions.h"
#import "ISSRectValue.h"
#import "ISSPointValue.h"
#import "ISSLazyValue.h"


typedef void (^RectInsetBlock)(ISSRectValue* rectValue);


@implementation ISSParcoaStyleSheetParser {
    // Common parsers
    ParcoaParser *dot, *semiColonSkipSpace, *comma, *openBraceSkipSpace, *closeBraceSkipSpace,
            *untilSemiColon, *propertyNameValueSeparator, *anyName, *anythingButControlChars,
            *identifier, *number, *anyValue, *quotedString, *commentParser;

    NSCharacterSet* validVariableNameSet;
    NSMutableDictionary* variables;

    NSMutableDictionary* propertyNameToProperty;
    NSMutableDictionary* typeToParser;
    ParcoaParser* enumValueParser;
    ParcoaParser* enumBitMaskValueParser;
    NSMutableDictionary* transformedValueCache;

    ParcoaParser* cssParser;
}


#pragma mark - Utils


- (BOOL) isRelativeValue:(NSString*)value {
    NSRange r = [value rangeOfString:@"%"];
    return r.location != NSNotFound && r.location > 0;
}

- (ParcoaParser*) unrecognizedLineParser {
    return [Parcoa parseLineUpToInvalidCharactersInString:@"{}"];
}


#pragma mark - Creation

- (id) transformEnumValue:(NSString*)enumValue forProperty:(ISSPropertyDefinition*)p {
    id result = p.enumValues[[enumValue lowercaseString]];
    if( !result ) [self ISSLogDebug:@"Warning! Unrecognized enum value: '%@'", enumValue];
    return result;
}

- (id) transformEnumBitMaskValues:(NSArray*)enumValues forProperty:(ISSPropertyDefinition*)p {
    NSNumber* result = nil;
    for(NSString* value in enumValues) {
        id enumValue = p.enumValues[[value lowercaseString]];
        if( enumValue ) {
            NSUInteger constVal = [enumValue unsignedIntegerValue];
            if( result ) result = @([result unsignedIntegerValue] | constVal);
            else result = @(constVal);
        } else [self ISSLogDebug:@"Warning! Unrecognized enum value: '%@'", value];
    }
    return result;
}

- (NSArray*) basicColorValueParsers:(BOOL)cgColor {
    ParcoaParser* rgb = [[Parcoa parameterStringWithPrefix:@"rgb"] transform:^id(id value) {
        NSArray* cc = [(NSString*)value trimmedSplit:@","];
        UIColor* color;
        if( cc.count == 3 ) {
            color = [UIColor colorWithR:[cc[0] intValue] G:[cc[1] intValue] B:[cc[2] intValue]];
        } else color = [UIColor magentaColor];
        if( cgColor ) return (id)color.CGColor;
        else return color;
    } name:@"rgb"];

    ParcoaParser* rgba = [[Parcoa parameterStringWithPrefix:@"rgba"] transform:^id(id value) {
        NSArray* cc = [(NSString*)value trimmedSplit:@","];
        UIColor* color;
        if( cc.count == 4 ) {
            color = [UIColor colorWithR:[cc[0] intValue] G:[cc[1] intValue] B:[cc[2] intValue] A:[cc[3] floatValue]];
        } else color = [UIColor magentaColor];
        if( cgColor ) return (id)color.CGColor;
        else return color;
    } name:@"rgba"];

    NSMutableCharacterSet* hexDigitsSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"aAbBcCdDeEfF"];
    [hexDigitsSet formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];

    ParcoaParser* hexColor = [[[Parcoa string:@"#"] keepRight:[Parcoa takeUntilInSet:[hexDigitsSet invertedSet] minCount:6]] transform:^id(id value) {
        UIColor* color = [UIColor colorWithHexString:value];
        if( cgColor ) return (id)color.CGColor;
        else return color;
    } name:@"hex"];

    ParcoaParser* preDefColor = [[Parcoa takeUntilInSet:[[NSCharacterSet letterCharacterSet] invertedSet] minCount:1] transform:^id(id value) {
        UIColor* color = [UIColor magentaColor];
        NSString* colorString = [value lowercaseString];
        if( ![colorString hasSuffix:@"color"] ) colorString = [colorString stringByAppendingString:@"color"];

        unsigned int c = 0;
        Method* methods = class_copyMethodList(object_getClass([UIColor class]), &c);
        for(int i=0; i<c; i++) {
            NSString* selectorName = [[NSString alloc] initWithCString:sel_getName(method_getName(methods[i])) encoding:NSUTF8StringEncoding];
            if( [colorString isEqualIgnoreCase:selectorName] ) {
                color = [UIColor performSelector:NSSelectorFromString(selectorName)];
                break;
            }
        }

        if( cgColor ) return (id)color.CGColor;
        else return color;
    } name:@"preDefColor"];

    return @[rgb, rgba, hexColor, preDefColor];
}

- (ParcoaParser*) colorParser:(BOOL)cgColor variables:(NSDictionary*)variables colorValueParsers:(NSArray*)colorValueParsers imageParser:(ParcoaParser*)imageParser {
    ParcoaParser* patternImageParser = [imageParser transform:^id(id value) {
        if( [value isKindOfClass:UIImage.class] ) return [UIColor colorWithPatternImage:value];
        else return [UIColor magentaColor];
    } name:@"patternImage"];

    ParcoaParser* gradientParser = [[Parcoa twoParameterFunctionParserWithName:@"gradient" leftParameterParser:[Parcoa choice:colorValueParsers] rightParameterParser:[Parcoa choice:colorValueParsers]] transform:^id(id value) {
        return [[ISSLazyValue alloc] initWithLazyEvaluationBlock:^id(id uiObject) {
            if( [uiObject isKindOfClass:UIView.class] ) {
                CGRect frame = [uiObject frame];
                if( frame.size.height > 0 ) {
                    UIColor* color1 = value[0];
                    UIColor* color2 = value[1];
                    return [color1 topDownLinearGradientToColor:color2 height:frame.size.height];
                } else return [UIColor clearColor];
            } else return [UIColor magentaColor];
        }];
    } name:@"gradient"];

    ParcoaParser* colorFunctionParser = [[Parcoa sequential:@[identifier, [Parcoa quickUnichar:'(' skipSpace:YES],
        [Parcoa choice:colorValueParsers], [Parcoa quickUnichar:',' skipSpace:YES], anyName, [Parcoa quickUnichar:')' skipSpace:YES]]] transform:^id(id value) {
            if( [value[2] isKindOfClass:UIColor.class] ) {
                if( [@"lighten" isEqualIgnoreCase:value[0]] ) return [value[2] colorByIncreasingBrightnessBy:[value[4] floatValue]];
                else if( [@"darken" isEqualIgnoreCase:value[0]] ) return [value[2] colorByIncreasingBrightnessBy:-[value[4] floatValue]];
                else if( [@"saturate" isEqualIgnoreCase:value[0]] ) return [value[2] colorByIncreasingSaturationBy:[value[4] floatValue]];
                else if( [@"desaturate" isEqualIgnoreCase:value[0]] ) return [value[2] colorByIncreasingSaturationBy:-[value[4] floatValue]];
                else if( [@"fadein" isEqualIgnoreCase:value[0]] ) return [value[2] colorByIncreasingAlphaBy:[value[4] floatValue]];
                else if( [@"fadeout" isEqualIgnoreCase:value[0]] ) return [value[2] colorByIncreasingAlphaBy:-[value[4] floatValue]];
                else return value[2];
            }
            return [UIColor magentaColor];
    } name:@"colorFunctionParser"];

    colorValueParsers = [@[patternImageParser, gradientParser, colorFunctionParser] arrayByAddingObjectsFromArray:colorValueParsers];

    return [Parcoa choice:colorValueParsers];
}

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

    // Remove any dashes from string, before attempting to find matching ISSPropertyDeclaration
    propertyNameString = [[[propertyNameString trim] stringByReplacingOccurrencesOfString:@"-" withString:@""] lowercaseString];

    // Parse prefix
    NSString* prefix = nil;
    NSRange dotRange = [propertyNameString rangeOfString:@"." options:NSBackwardsSearch];
    if( dotRange.location != NSNotFound && (dotRange.location+1) < propertyNameString.length ) {
        prefix = [propertyNameString substringToIndex:dotRange.location];
        propertyNameString = [propertyNameString substringFromIndex:dotRange.location+1];
    }

    ISSPropertyDefinition* property = propertyNameToProperty[propertyNameString];
    if( !property && prefix ) property = propertyNameToProperty[[NSString stringWithFormat:@"%@.%@", prefix, propertyNameString]];

    // Transform parameters
    if( property && parameters ) {
        NSMutableArray* transformedParameters = [[NSMutableArray alloc] init];
        for(NSUInteger i=0; i<parameters.count; i++) { // Transform parameters to enum values
            NSString* param = [[parameters[i] trim] lowercaseString];
            if( [param hasData] ) {
                id paramValue = property.parameterEnumValues[param];
                if( paramValue ) [transformedParameters addObject:paramValue];
            }
        }
        parameters = transformedParameters;
    }

    if( property ) return [[ISSPropertyDeclaration alloc] initWithProperty:property parameters:parameters prefix:prefix];
    else return nil;
}

- (NSString*) replaceVariableReferences:(NSString*)propertyValue {
    NSUInteger location = 0;

    while( location < propertyValue.length ) {
        // Replace any variable references
        NSRange atRange = [propertyValue rangeOfString:@"@" options:0 range:NSMakeRange(location, propertyValue.length - location)];
        if( atRange.location != NSNotFound ) {
            location += atRange.location + atRange.length;

            // @ found, get variable name
            NSRange variableNameRange = NSMakeRange(location, 0);
            for(NSUInteger i=location; i<propertyValue.length; i++) {
                if( [validVariableNameSet characterIsMember:[propertyValue characterAtIndex:i]] ) {
                    variableNameRange.length++;
                } else break;
            }

            id variableValue = nil;
            if( variableNameRange.length > 0 ) {
                id variableName = [propertyValue substringWithRange:variableNameRange];
                variableValue = variables[variableName];
            }
            if( variableValue ) {
                // Replace variable occurrence in propertyValue string with variableValue string
                propertyValue = [propertyValue stringByReplacingCharactersInRange:NSMakeRange(atRange.location, variableNameRange.length+1)
                                                                       withString:variableValue];
                location += [variableValue length];
            } else {
                ISSLogWarning(@"Unrecognized property variable: %@", propertyValue);
                location += variableNameRange.length;
            }
        } else break;
    }

    return propertyValue;
}

- (UIFont*) fontWithSize:(UIFont*)font size:(CGFloat)size {
    if( [UIFont.class respondsToSelector:@selector(fontWithDescriptor:size:)] ) {
        return [UIFont fontWithDescriptor:font.fontDescriptor size:size];
    } else {
        return [font fontWithSize:size]; // Doesn't seem to work right in iOS7 (for some fonts anyway...)
    }
}

- (NSArray*) transformPropertyPair:(NSArray*)propertyPair {
    if( propertyPair[1] && [propertyPair[1] isKindOfClass:NSString.class] ) {
        NSString* propertyValue = [propertyPair[1] trim];

        propertyValue = [self replaceVariableReferences:propertyValue];

        // Parse property value
        ISSPropertyDeclaration* decl = [self parsePropertyDeclaration:propertyPair[0]];
        if( decl ) {
            ISSPropertyDefinition* p = decl.property;
            NSMutableDictionary* cache = transformedValueCache[@(p.type)];
            id transformedValue = cache[propertyValue];
            if( !cache ) {
                cache = [[NSMutableDictionary alloc] init];
                transformedValueCache[@(p.type)] = cache;
            }

            // Already transformed value
            if( transformedValue ) {
                return @[decl, transformedValue];
            }
            // Enum property
            else if( p.type == ISStyleSheetPropertyTypeEnumType ) {
                ParcoaParser* parser;
                if( p.enumBitMaskType ) parser = enumBitMaskValueParser;
                else parser = enumValueParser;
                ParcoaResult* result = [parser parse:propertyValue];
                if( result.isOK ) {
                    if( p.enumBitMaskType ) transformedValue = [self transformEnumBitMaskValues:result.value forProperty:p];
                    else transformedValue = [self transformEnumValue:result.value forProperty:p];
                    if( transformedValue ) { // Update cache with transformed value
                        cache[propertyValue] = transformedValue;
                        return @[decl, transformedValue];
                    }
                }
            }
            // Other properties
            else {
                ParcoaParser* valueParser = typeToParser[@(p.type)];
                ParcoaResult* result = [valueParser parse:propertyValue];
                if( result.isOK && result.value ) {
                    if( propertyValue ) { // Update cache with transformed value
                        cache[propertyValue] = result.value;
                    }
                    return @[decl, result.value];
                }
            }
        }
    }

    ISSPropertyDeclaration* unrecognized = [[ISSPropertyDeclaration alloc] initWithUnrecognizedProperty:propertyPair[0]];
    ISSLogWarning(@"Unrecognized property '%@' with value: '%@'", propertyPair[0], propertyPair[1]);
    return @[unrecognized, propertyPair[1]];
}

- (UIImage*) imageNamed:(NSString*)name { // For testing purposes...
    return [UIImage imageNamed:name];
}

- (ParcoaParser*) propertyParsers:(ParcoaParser*)selectorsParser {
    propertyNameToProperty = [[NSMutableDictionary alloc] init];
    typeToParser = [[NSMutableDictionary alloc] init];

    // Build dictionary of all known property names mapped to ISSPropertyDefinitions
    NSSet* allProperties = [ISSPropertyDefinition propertyDefinitions];
    for(ISSPropertyDefinition* p in allProperties) {
        for(NSString* alias in p.allNames) {
            propertyNameToProperty[[alias lowercaseString]] = p;
        }
    }


    // String
    ParcoaParser* stringValueParser = [Parcoa choice:@[quotedString, anyName]];
    typeToParser[@(ISStyleSheetPropertyTypeString)] = stringValueParser;


    // BOOL
    ParcoaParser* boolValueParser = [identifier transform:^id(id value) {
        return [NSNumber numberWithBool:[value boolValue]];
    } name:@"bool"];
    typeToParser[@(ISStyleSheetPropertyTypeBool)] = boolValueParser;


    // Number
    ParcoaParser* numberValueParser = [number transform:^id(id value) {
        return [NSNumber numberWithFloat:[value floatValue]];
    } name:@"number"];
    typeToParser[@(ISStyleSheetPropertyTypeNumber)] = numberValueParser;


    // CGRect
    // Ex: rect(0, 0, 320, 480)
    // Ex: size(320, 480)
    // Ex: size(50%, 70).right(5).top(5)     // TODO: min(50, *).max(500, *)
    // Ex: parent (=parent(0,0))
    // Ex: parent(10, 10) // dx, dy - CGRectInset
    // Ex: window (=window(0,0))
    // Ex: window(10, 10) // dx, dy - CGRectInset
    ParcoaParser* parentRectValueParser = [[[Parcoa stringIgnoringCase:@"parent"] or:[Parcoa stringIgnoringCase:@"superview"]] transform:^id(id value) {
        return [ISSRectValue parentRect];
    } name:@"parentRect"];

    ParcoaValueTransform parentInsetTransform = ^id(id value) {
        NSArray* c = [value trimmedSplit:@","];
        if( c.count == 2 ) return [ISSRectValue parentInsetRectWithSize:CGSizeMake([c[0] floatValue], [c[1] floatValue])];
        else if( c.count == 4 ) return [ISSRectValue parentInsetRectWithInsets:UIEdgeInsetsMake([c[0] floatValue], [c[1] floatValue], [c[2] floatValue], [c[3] floatValue])];
        else return [ISSRectValue zeroRect];
    };
    ParcoaParser* parentInsetValueParser = [[Parcoa parameterStringWithPrefixes:@[@"parent", @"superview"]] transform:parentInsetTransform name:@"parentRect.inset"];

    ParcoaParser* windowRectValueParser = [[Parcoa stringIgnoringCase:@"window"] transform:^id(id value) {
        return [ISSRectValue windowRect];
    } name:@"windowRect"];

    ParcoaValueTransform windowInsetTransform = ^id(id value) {
        NSArray* c = [value trimmedSplit:@","];
        if( c.count == 2 ) return [ISSRectValue windowInsetRectWithSize:CGSizeMake([c[0] floatValue], [c[1] floatValue])];
        else if( c.count == 4 ) return [ISSRectValue windowInsetRectWithInsets:UIEdgeInsetsMake([c[0] floatValue], [c[1] floatValue], [c[2] floatValue], [c[3] floatValue])];
        else return [ISSRectValue zeroRect];
    };
    ParcoaParser* windowInsetValueParser = [[Parcoa parameterStringWithPrefix:@"window"] transform:windowInsetTransform name:@"windowRect.inset"];

    ParcoaParser* rectValueParser = [[Parcoa parameterStringWithPrefix:@"rect"] transform:^id(id value) {
        NSArray* c = [value trimmedSplit:@","];
        if( c.count == 4 ) return [ISSRectValue rectWithRect:CGRectMake([c[0] floatValue], [c[1] floatValue], [c[2] floatValue], [c[3] floatValue])];
        else return [ISSRectValue zeroRect];
    } name:@"rect"];

    ParcoaParser* rectSizeValueParser = [[Parcoa parameterStringWithPrefix:@"size"] transform:^id(id value) {
        NSArray* c = [value trimmedSplit:@","];
        if( c.count == 2 ) {
            BOOL autoWidth = [@"auto" isEqualIgnoreCase:c[0]];
            CGFloat width = autoWidth ? ISSRectValueAuto : [c[0] floatValue];
            BOOL relativeWidth = autoWidth ? YES : [self isRelativeValue:c[0]];
            BOOL autoHeight = [@"auto" isEqualIgnoreCase:c[1]];
            CGFloat height = autoHeight ? ISSRectValueAuto : [c[1] floatValue];
            BOOL relativeHeight = autoHeight ? YES : [self isRelativeValue:c[1]];
            return [ISSRectValue parentRelativeRectWithSize:CGSizeMake(width, height) relativeWidth:relativeWidth relativeHeight:relativeHeight];
        } else {
            return [ISSRectValue zeroRect];
        }
    } name:@"rectSize"];

    ParcoaParser* insetParser = [[Parcoa sequential:@[identifier, [Parcoa quickUnichar:'(' skipSpace:YES], anyName, [Parcoa quickUnichar:')' skipSpace:YES]]] transform:^id(id value) {
        return ^(ISSRectValue* rectValue) {
            if( [@"left" isEqualIgnoreCase:value[0]] ) [rectValue setLeftInset:[value[2] floatValue] relative:[self isRelativeValue:value[2]]];
            else if( [@"right" isEqualIgnoreCase:value[0]] ) [rectValue setRightInset:[value[2] floatValue] relative:[self isRelativeValue:value[2]]];
            else if( [@"top" isEqualIgnoreCase:value[0]] ) [rectValue setTopInset:[value[2] floatValue] relative:[self isRelativeValue:value[2]]];
            else if( [@"bottom" isEqualIgnoreCase:value[0]] ) [rectValue setBottomInset:[value[2] floatValue] relative:[self isRelativeValue:value[2]]];
            else ISSLogWarning(@"Unknown inset: %@", value[0]);
        };
    } name:@"insetParser"];

    ParcoaParser* partSeparator = [[Parcoa choice:@[[Parcoa space], dot]] many1];
    ParcoaParser* relativeRectParser = [[[Parcoa choice:@[rectSizeValueParser, insetParser]] sepBy:partSeparator] transform:^id(id value) {
        ISSRectValue* rectValue = [ISSRectValue zeroRect];
        if( [value isKindOfClass:[NSArray class]] ) {
            ISSRectValue* sizeValue = [ISSRectValue parentRelativeRectWithSize:CGSizeMake(ISSRectValueAuto, ISSRectValueAuto) relativeWidth:YES relativeHeight:YES];
            for(id element in value) {
                if( [element isKindOfClass:ISSRectValue.class] ) {
                    sizeValue = element;
                    break;
                }
            }
            for(id element in value) {
                if( ![element isKindOfClass:ISSRectValue.class] ) { // i.e. RectInsetBlock // TODO: Improve this "type" check
                    RectInsetBlock block = element;
                    block(sizeValue);
                }
            }
            return sizeValue;
        }
        return rectValue;
    } name:@"relativeRectParser"];

    typeToParser[@(ISStyleSheetPropertyTypeRect)] = [Parcoa choice:@[rectValueParser,
                parentInsetValueParser, parentRectValueParser,
                windowInsetValueParser, windowRectValueParser,
                relativeRectParser, rectSizeValueParser]];


    // UIOffset
    ParcoaParser* offsetValueParser = [[Parcoa parameterStringWithPrefix:@"offset"] transform:^id(id value) {
        NSArray* c = [(NSString*)value trimmedSplit:@","];
        if( c.count == 2 ) {
            return [NSValue valueWithUIOffset:UIOffsetMake([c[0] floatValue], [c[1] floatValue])];
        } else return [NSValue valueWithUIOffset:UIOffsetZero];
    } name:@"offset"];
    typeToParser[@(ISStyleSheetPropertyTypeOffset)] = offsetValueParser;


    // CGSize
    ParcoaParser* sizeValueParser = [[Parcoa parameterStringWithPrefix:@"size"] transform:^id(id value) {
        NSArray* c = [(NSString*)value trimmedSplit:@","];
        if( c.count == 2 ) {
            return [NSValue valueWithCGSize:CGSizeMake([c[0] floatValue], [c[1] floatValue])];
        } else return [NSValue valueWithCGSize:CGSizeZero];
    } name:@"size"];
    typeToParser[@(ISStyleSheetPropertyTypeSize)] = sizeValueParser;


    // CGPoint
    // Ex: point(160, 240)
    // Ex: parent
    // Ex: parent(0, -100)
    // Ex: parent.relative(0, -100)
    ParcoaParser* parentCenterPointValueParser = [[[Parcoa stringIgnoringCase:@"parent"] or:[Parcoa stringIgnoringCase:@"superview"]] transform:^id(id value) {
        return [ISSPointValue parentCenter];
    } name:@"parentCenterPoint"];

    ParcoaValueTransform parentCenterRelativeTransform = ^id(id value) {
        NSArray* c = [value trimmedSplit:@","];
        if( c.count == 2 ) return [ISSPointValue parentRelativeCenterPointWithPoint:CGPointMake([c[0] floatValue], [c[1] floatValue])];
        else return [ISSPointValue zeroPoint];
    };
    ParcoaParser* parentCenterRelativeValueParser = [[Parcoa parameterStringWithPrefixes:@[@"parent", @"superview"]] transform:parentCenterRelativeTransform name:@"parentCenter.relative"];

    ParcoaParser* windowCenterPointValueParser = [[Parcoa stringIgnoringCase:@"window"] transform:^id(id value) {
        return [ISSPointValue windowCenter];
    } name:@"windowCenterPoint"];

    ParcoaValueTransform windowCenterRelativeTransform = ^id(id value) {
        NSArray* c = [value trimmedSplit:@","];
        if( c.count == 2 ) return [ISSPointValue windowRelativeCenterPointWithPoint:CGPointMake([c[0] floatValue], [c[1] floatValue])];
        else return [ISSPointValue zeroPoint];
    };
    ParcoaParser* windowCenterRelativeValueParser = [[Parcoa parameterStringWithPrefix:@"window"] transform:windowCenterRelativeTransform name:@"windowCenter.relative"];

    ParcoaParser* pointValueParser = [[Parcoa parameterStringWithPrefix:@"point"] transform:^id(id value) {
        NSArray* c = [(NSString*)value trimmedSplit:@","];
        if( c.count == 2 ) return [ISSPointValue pointWithPoint:CGPointMake([c[0] floatValue], [c[1] floatValue])];
        else return [ISSPointValue zeroPoint];
    } name:@"point"];

    typeToParser[@(ISStyleSheetPropertyTypePoint)] = [Parcoa choice:@[pointValueParser,
            parentCenterRelativeValueParser, parentCenterPointValueParser,
            windowCenterRelativeValueParser, windowCenterPointValueParser]];


    // UIEdgeInsets
    ParcoaParser* insetsValueParser = [[Parcoa parameterStringWithPrefix:@"insets"] transform:^id(id value) {
        NSArray* c = [(NSString*)value trimmedSplit:@","];
        if( c.count == 4 ) {
            return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake([c[0] floatValue], [c[1] floatValue], [c[2] floatValue], [c[3] floatValue])];
        } else return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsZero];
    } name:@"insets"];
    typeToParser[@(ISStyleSheetPropertyTypeEdgeInsets)] = insetsValueParser;


    // UIImage (1)
    // Ex: image.png
    // Ex: image(image.png);
    // Ex: image(image.png, 1, 2);
    // Ex: image(image.png, 1, 2, 3, 4);
    ParcoaParser* simpleImageParser = [[Parcoa choice:@[quotedString, [Parcoa sequential:@[identifier, dot, identifier]]]] transform:^id(id value) {
        UIImage* img;
        if( [value isKindOfClass:NSArray.class] ) img = [self imageNamed:[value componentsJoinedByString:@""]];
        else img = [self imageNamed:value];
        if( img ) return img;
        else return [NSNull null];
    } name:@"simpleImage"];
    ParcoaParser* imageParser = [[Parcoa parameterStringWithPrefix:@"image"] transform:^id(id value) {
            NSArray* cc = [(NSString*)value trimmedSplit:@","];
            UIImage* img = nil;
            if( cc.count > 0 ) {
                NSString* imageName = [cc[0] trimQuotes];
                img = [self imageNamed:imageName];
                if( cc.count == 5 ) {
                    img = [img resizableImageWithCapInsets:UIEdgeInsetsMake([cc[1] floatValue], [cc[2] floatValue], [cc[3] floatValue], [cc[4] floatValue])];
                } else if( cc.count == 2 ) {
                    img = [img stretchableImageWithLeftCapWidth:[cc[1] intValue] topCapHeight:[cc[2] intValue]];
                }
            }
            if( img ) return img;
            else return [NSNull null];
        } name:@"image"];
    imageParser = [Parcoa choice:@[imageParser, simpleImageParser]];


    // UIColor
    NSArray* uiColorValueParsers = [self basicColorValueParsers:NO];
    ParcoaParser* colorPropertyParser = [self colorParser:NO variables:variables colorValueParsers:uiColorValueParsers imageParser:imageParser];
    typeToParser[@(ISStyleSheetPropertyTypeColor)] = colorPropertyParser;

    // CGColor
    NSArray* cgColorValueParsers = [self basicColorValueParsers:YES];
    ParcoaParser* cgColorPropertyParser = [self colorParser:YES variables:variables colorValueParsers:cgColorValueParsers imageParser:imageParser];
    typeToParser[@(ISStyleSheetPropertyTypeCGColor)] = cgColorPropertyParser;


    // UIImage (2)
    ParcoaParser* imageWithColorParser = [[Parcoa choice:uiColorValueParsers] transform:^id(id value) {
        return [value asUIImage];
    } name:@"imageWithColor"];
    ParcoaParser* imageParsers = [Parcoa choice:@[imageParser, imageWithColorParser]];
    typeToParser[@(ISStyleSheetPropertyTypeImage)] = imageParsers;


    // CGAffineTransform
    // Ex: rotate(90) scale(2,2) translate(100,100);
    ParcoaParser* rotateValueParser = [[Parcoa parameterStringWithPrefix:@"rotate"] transform:^id(id value) {
            CGFloat angle = [value floatValue];
            angle = ((CGFloat)M_PI * angle / 180.0f);
            return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(angle)];
        } name:@"rotate"];
    ParcoaParser* scaleValueParser = [[Parcoa parameterStringWithPrefix:@"scale"] transform:^id(id value) {
            NSArray* c = [(NSString*)value trimmedSplit:@","];
            if( c.count == 2 ) {
                return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale([c[0] floatValue], [c[1] floatValue])];
            } else return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
        } name:@"scale"];
    ParcoaParser* translateValueParser = [[Parcoa parameterStringWithPrefix:@"translate"] transform:^id(id value) {
        NSArray* c = [(NSString*)value trimmedSplit:@","];
        if( c.count == 2 ) {
            return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation([c[0] floatValue], [c[1] floatValue])];
        } else return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
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
    typeToParser[@(ISStyleSheetPropertyTypeTransform)] = transformValuesParser;


    // UIFont
    // Ex: Helvetica 12
    // Ex: bigger(@font, 1)
    // Ex: smaller(@font, 1)
    // Ex: fontWithSize(@font, 12)
    ParcoaParser* commaOrSpace = [[Parcoa choice:@[[Parcoa space], comma]] many1];
    ParcoaParser* fontValueParser = [Parcoa choice:@[quotedString, anyName]];
    fontValueParser = [[fontValueParser keepLeft:commaOrSpace] then:fontValueParser];
    fontValueParser = [fontValueParser transform:^id(id value) {
        CGFloat fontSize = [UIFont systemFontSize];
        NSString* fontName = nil;
        if( [value isKindOfClass:[NSArray class]] ) {
            for(NSString* stringVal in value) {
                NSString* lc = [stringVal.lowercaseString trim];
                if( [lc hasSuffix:@"pt"] || [lc hasSuffix:@"px"] ) {
                    lc = [lc substringToIndex:lc.length-2];
                }

                if( lc.length > 0 ) {
                    if( lc.isNumeric ) {
                        fontSize = [lc floatValue];
                    } else { // If not pt, px or comma
                        fontName = stringVal;
                    }
                }
            }
        }

        if( fontName ) return [UIFont fontWithName:fontName size:fontSize];
        else return [UIFont systemFontOfSize:fontSize];
    } name:@"font"];

    ParcoaParser* fontFunctionParser = [[Parcoa sequential:@[identifier, [Parcoa quickUnichar:'(' skipSpace:YES],
        fontValueParser, [Parcoa quickUnichar:',' skipSpace:YES], number, [Parcoa quickUnichar:')' skipSpace:YES]]] transform:^id(id value) {
            if( [value[2] isKindOfClass:UIFont.class] ) {
                if( [@"bigger" isEqualIgnoreCase:value[0]] ) return [self fontWithSize:value[2] size:[(UIFont*)value[2] pointSize] + [value[4] floatValue]];
                else if( [@"smaller" isEqualIgnoreCase:value[0]] ) return [self fontWithSize:value[2] size:[(UIFont*)value[2] pointSize] - [value[4] floatValue]];
                else if( [@"fontWithSize" isEqualIgnoreCase:value[0]] ) return [self fontWithSize:value[2] size:[value[4] floatValue]];
                else return value[2];
            }
            return [UIFont systemFontOfSize:[UIFont systemFontSize]];
    } name:@"fontFunctionParser"];

    typeToParser[@(ISStyleSheetPropertyTypeFont)] = [Parcoa choice:@[fontFunctionParser, fontValueParser]];


    // Enums
    enumValueParser = identifier;
    enumBitMaskValueParser = [identifier sepBy:commaOrSpace];

    
    // Unrecognized line
    ParcoaParser* unrecognizedLine = [[self unrecognizedLineParser] transform:^id(id value) {
        if( [value hasData] ) ISSLogWarning(@"Unrecognized property line: '%@'", [value trim]);
        return [NSNull null];
    } name:@"unrecognizedLine"];
    

    // Property pair
    ParcoaParser* propertyPairParser = [[[anythingButControlChars keepLeft:propertyNameValueSeparator] then:[anythingButControlChars keepLeft:semiColonSkipSpace]] transform:^id(id value) {
        return [self transformPropertyPair:value];
    } name:@"propertyPair"];


    // Create parser for unsupported nested declarations, to prevent those to interfere with current declarations
    NSMutableCharacterSet* bracesSet = [NSMutableCharacterSet characterSetWithCharactersInString:@"{}"];
    ParcoaParser* anythingButBraces = [Parcoa takeUntilInSet:bracesSet minCount:1];
    ParcoaParser* unsupportedNestedRulesetParser = [[anythingButBraces then:[anythingButBraces between:openBraceSkipSpace and:closeBraceSkipSpace]] transform:^id(id value) {
        ISSLogWarning(@"Unsupported nested ruleset: '%@'", value);
        return [NSNull null];
    } name:@"unsupportedNestedRuleset"];

    // Create forward declaration for nested ruleset/declarations parser
    ParcoaParserForward* nestedRulesetParserProxy = [ParcoaParserForward forwardWithName:@"nestedRulesetParserProxy" summary:@""];

    // Property declarations
    ParcoaParser* propertyParser = [Parcoa choice:@[commentParser, propertyPairParser, nestedRulesetParserProxy, unsupportedNestedRulesetParser, unrecognizedLine]];
    propertyParser = [Parcoa safeDictionary:[propertyParser many]];

    // Create parser for nested declarations (and unsupported nested declarations, to prevent those to interfere with current declarations)
    ParcoaParser* nestedRulesetParser = [selectorsParser then:[propertyParser between:openBraceSkipSpace and:closeBraceSkipSpace]];
    [nestedRulesetParserProxy setImplementation:nestedRulesetParser];

    return propertyParser;
}


#pragma mark - Creation


- (id) init {
    if ( (self = [super init]) ) {
        // Common parsers
        dot = [Parcoa quickUnichar:'.'];
        semiColonSkipSpace = [Parcoa quickUnichar:';' skipSpace:YES];
        comma = [Parcoa quickUnichar:','];
        openBraceSkipSpace = [Parcoa quickUnichar:'{' skipSpace:YES];
        closeBraceSkipSpace = [Parcoa quickUnichar:'}' skipSpace:YES];
        untilSemiColon = [Parcoa takeUntilChar:';'];
        propertyNameValueSeparator = [Parcoa nameValueSeparator];

        anyName = [Parcoa anythingButWhiteSpaceAndControlChars:1];
        anythingButControlChars = [Parcoa anythingButBasicControlChars:1];
        identifier = [Parcoa validIdentifierChars:1];
        anyValue = untilSemiColon;

        number = [[Parcoa digit] concatMany1];
        ParcoaParser* fraction = [[dot then:number] concat];
        number = [[number then:[Parcoa option:fraction default:@""]] concat];

        ParcoaParser* quote = [Parcoa oneOf:@"'\""];
        ParcoaParser* notQuote = [Parcoa noneOf:@"'\""];
        quotedString = [[quote keepRight:[notQuote concatMany]] keepLeft:quote];

        // Comments
        commentParser = [[Parcoa commentParser] transform:^id(id value) {
            ISSLogDebug(@"Comment: %@", [value trim]);
            return [NSNull null];
        } name:@"commentParser"];

        // Variables
        validVariableNameSet = [Parcoa validIdentifierCharsSet];
        variables = [NSMutableDictionary dictionary];
        ParcoaParser* variableParser = [[[[[[Parcoa quickUnichar:'@'] keepRight:[identifier concatMany1]] skipSurroundingSpaces] keepLeft:propertyNameValueSeparator] then:[anyValue keepLeft:semiColonSkipSpace]] transform:^id(id value) {
            [variables setObject:value[1] forKey:value[0]];
            return value;
        } name:@"variableParser"];

        // Selectors
        ParcoaParser* typeName = [Parcoa choice:@[identifier, [Parcoa quickUnichar:'*']]];
        ParcoaParser* typeSelector = [typeName transform:^id(id value) {
            return [[ISSSelector alloc] initWithType:value class:nil];
        } name:@"typeSelector"];

        ParcoaParser* classSelector = [[dot keepRight:identifier] transform:^id(id value) {
            return [[ISSSelector alloc] initWithType:nil class:value];
        } name:@"classSelector"];

        ParcoaParser* typeAndClassSelector = [[Parcoa sequential:@[typeName, dot, identifier]] transform:^id(id value) {
            NSArray* elements = value;
            return [[ISSSelector alloc] initWithType:elements[0] class:elements[2]];
        } name:@"typeAndClassSelector"];

        ParcoaParser* simpleSelector = [Parcoa choice:@[typeAndClassSelector, classSelector, typeSelector]];

        ParcoaParser* selectorChain = [[simpleSelector sepBy1:[[Parcoa space] many1]] transform:^id(id value) {
            return [[ISSSelectorChain alloc] initWithComponents:value];
        } name:@"selectorChain"];

        ParcoaParser* selectors = [[selectorChain skipSurroundingSpaces] sepBy1:comma];

        // Properties
        transformedValueCache = [[NSMutableDictionary alloc] init];
        ParcoaParser* propertyDeclarations = [self propertyParsers:selectors];

        ParcoaParser* rulesetParser = [[selectors then:[propertyDeclarations between:openBraceSkipSpace and:closeBraceSkipSpace]] dictionaryWithKeys:@[@"selectors", @"declarations"]];

         // Unrecognized content
        ParcoaParser* unrecognizedContent = [[self unrecognizedLineParser] transform:^id(id value) {
            if( [value hasData] ) ISSLogWarning(@"Warning! Unrecognized content: '%@'", [value trim]);
            return [NSNull null];
        } name:@"unrecognizedContent"];

        cssParser = [[Parcoa choice:@[commentParser, variableParser, rulesetParser, unrecognizedContent]] many];
    }
    return self;
}

- (void) processProperties:(NSMutableDictionary*)properties withSelectorChains:(NSArray*)selectorChains andAddToDeclarations:(NSMutableArray*)declarations {
    NSMutableArray* nestedDeclarations = [[NSMutableArray alloc] init];

    for(id key in properties.allKeys) {
        if( [key isKindOfClass:NSArray.class] ) {
            // Remove mapping for nested selector chains in properties
            //ISSSelector* selector = key;
            NSMutableDictionary* nestedProperties = properties[key];
            [properties removeObjectForKey:key];

            // Construct new selector chains by appending selector to parent selector chains
            NSMutableArray* nestedSelectorChains = [[NSMutableArray alloc] init];
            for(ISSSelectorChain* selectorChain in key) {
                for(ISSSelectorChain* parentChain in selectorChains) {
                    [nestedSelectorChains addObject:[parentChain selectorChainByAddingSelectorChain:selectorChain]];
                }
            }

            [nestedDeclarations addObject:@[nestedProperties, nestedSelectorChains]];
        }
    }

    // Add declaration
    [declarations addObject:[[ISSPropertyDeclarations alloc] initWithSelectorChains:selectorChains andProperties:properties]];

    // Process nested declarations
    for(NSArray* declarationPair in nestedDeclarations) {
        [self processProperties:declarationPair[0] withSelectorChains:declarationPair[1] andAddToDeclarations:declarations];
    }
}

- (NSMutableArray*) parse:(NSString*)styleSheetData {
    NSTimeInterval t = [NSDate timeIntervalSinceReferenceDate];

    [variables removeAllObjects];

    ParcoaResult* result = [styleSheetData hasData] ? [cssParser parse:styleSheetData] : nil;
    if( result.isOK ) {
        ISSLogDebug(@"Done parsing stylesheet in %g seconds", ([NSDate timeIntervalSinceReferenceDate] - t));
        NSMutableArray* declarations = [NSMutableArray array];

        for(id element in result.value) {
            if( [element isKindOfClass:[NSDictionary class]] ) {
                NSDictionary* declaration = (NSDictionary*)element;

                NSMutableDictionary* properties = declaration[@"declarations"];
                NSArray* selectorChains = declaration[@"selectors"];

                [self processProperties:properties withSelectorChains:selectorChains andAddToDeclarations:declarations];
            }
        }

        ISSLogTrace(@"Parse result: \n%@", declarations);
        return declarations;
    } else {
        if( [styleSheetData hasData] ) ISSLogWarning(@"Error parsing stylesheet: %@", result);
        else ISSLogWarning(@"Empty/nil stylesheet data!");
        return nil;
    }
}

@end
