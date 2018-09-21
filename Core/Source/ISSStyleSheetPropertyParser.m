//
//  ISSStyleSheetPropertyParser.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSStyleSheetPropertyParser.h"

#import "ISSStyleSheetParser+Protected.h"
#import "ISSStyleSheetParser+Support.h"

#import "ISSParser.h"
#import "ISSPropertyDefinition.h"
#import "ISSPropertyDeclaration.h"
#import "ISSNestedElementSelector.h"
#import "ISSSelectorChain.h"
#import "ISSRuntimeIntrospectionUtils.h"
#import "ISSDownloadableResource.h"
#import "ISSRemoteFont.h"

#import "NSObject+ISSLogSupport.h"
#import "UIColor+ISSAdditions.h"
#import "NSString+ISSAdditions.h"
#import "NSArray+ISSAdditions.h"

#import "ISSMacros.h"


#pragma mark - ISSAttributedStringAttribute

@interface ISSAttributedStringAttribute: NSObject

@property (nonatomic, strong, readonly) NSString* attributeName;
@property (nonatomic, strong, readonly) ISSPropertyType propertyType;
@property (nonatomic, strong, readonly, nullable) ISSPropertyEnumValueMapping* enumMapping;

@end


#pragma mark - ISSAttributedStringAttribute

@implementation ISSAttributedStringAttribute

- (instancetype) init:(NSString*)attributeName propertyType:(ISSPropertyType)propertyType {
    if ( self = [super init] ) {
        _attributeName = attributeName;
        _propertyType = propertyType;
        _enumMapping = nil;
    }
    return self;
}

- (instancetype) init:(NSString*)attributeName enumMapping:(ISSPropertyEnumValueMapping*)enumMapping {
    if ( self = [super init] ) {
        _attributeName = attributeName;
        _propertyType = ISSPropertyTypeEnumType;
        _enumMapping = enumMapping;
    }
    return self;
}

@end


#pragma mark - ISSStyleSheetPropertyParser

@interface ISSStyleSheetPropertyParser ()

@property (nonatomic, strong, readonly) NSMutableDictionary* typeToParser;

@property (nonatomic, strong, readonly) NSDictionary* attributedStringProperties;

@end


@implementation ISSStyleSheetPropertyParser

- (instancetype) init {
    if ( self = [super init] ) {
        _typeToParser = [NSMutableDictionary dictionary];
        
        NSMutableDictionary* attrs = [NSMutableDictionary dictionary];
        
        // Attributed string support:
        NSDictionary* underlineStyleEnums = @{@"none" : @(NSUnderlineStyleNone), @"stylenone" : @(NSUnderlineStyleNone), @"single" : @(NSUnderlineStyleSingle), @"stylesingle" : @(NSUnderlineStyleSingle),
                                              @"double" : @(NSUnderlineStyleDouble), @"styledouble" : @(NSUnderlineStyleDouble), @"thick" : @(NSUnderlineStyleThick), @"stylethick" : @(NSUnderlineStyleThick),
                                              @"dash" : @(NSUnderlinePatternDash), @"patterndash" : @(NSUnderlinePatternDash), @"dot" : @(NSUnderlinePatternDot), @"patterndot" : @(NSUnderlinePatternDot),
                                              @"dashDot" : @(NSUnderlinePatternDashDot), @"patterndashDot" : @(NSUnderlinePatternDashDot), @"dashdotdot" : @(NSUnderlinePatternDashDotDot), @"patterndashdotdot" : @(NSUnderlinePatternDashDotDot),
                                              @"solid" : @(NSUnderlinePatternSolid), @"patternsolid" : @(NSUnderlinePatternSolid)};
        
        ISSPropertyBitMaskEnumValueMapping* underlineStyleMapping = [[ISSPropertyBitMaskEnumValueMapping alloc] initWithEnumValues:underlineStyleEnums enumBaseName:@"NSUnderlineStyle" defaultValue:@(NSUnderlineStyleNone)];
        
        attrs[@"backgroundcolor"] = [[ISSAttributedStringAttribute alloc] init:NSBackgroundColorAttributeName propertyType:ISSPropertyTypeColor];
        attrs[@"baselineoffset"] = [[ISSAttributedStringAttribute alloc] init:NSBaselineOffsetAttributeName propertyType:ISSPropertyTypeNumber];
        attrs[@"expansion"] = [[ISSAttributedStringAttribute alloc] init:NSExpansionAttributeName propertyType:ISSPropertyTypeNumber];
        attrs[@"font"] = [[ISSAttributedStringAttribute alloc] init:NSFontAttributeName propertyType:ISSPropertyTypeFont];
        attrs[@"foregroundcolor"] = [[ISSAttributedStringAttribute alloc] init:NSForegroundColorAttributeName propertyType:ISSPropertyTypeColor];
        attrs[@"kern"] = [[ISSAttributedStringAttribute alloc] init:NSKernAttributeName propertyType:ISSPropertyTypeNumber];
        attrs[@"ligature"] = [[ISSAttributedStringAttribute alloc] init:NSLigatureAttributeName propertyType:ISSPropertyTypeNumber];
        attrs[@"obliqueness"] = [[ISSAttributedStringAttribute alloc] init:NSObliquenessAttributeName propertyType:ISSPropertyTypeNumber];
        attrs[@"shadowcolor"] = [[ISSAttributedStringAttribute alloc] init:NSShadowAttributeName propertyType:ISSPropertyTypeColor];
        attrs[@"shadowoffset"] = [[ISSAttributedStringAttribute alloc] init:NSShadowAttributeName propertyType:ISSPropertyTypeSize];
        attrs[@"strikethroughcolor"] = [[ISSAttributedStringAttribute alloc] init:NSStrikethroughColorAttributeName propertyType:ISSPropertyTypeColor];
        attrs[@"strikethroughstyle"] = [[ISSAttributedStringAttribute alloc] init:NSStrikethroughStyleAttributeName enumMapping:underlineStyleMapping];
        attrs[@"strokecolor"] = [[ISSAttributedStringAttribute alloc] init:NSStrokeColorAttributeName propertyType:ISSPropertyTypeColor];
        attrs[@"strokewidth"] = [[ISSAttributedStringAttribute alloc] init:NSStrokeWidthAttributeName propertyType:ISSPropertyTypeNumber];
        attrs[@"underlinecolor"] = [[ISSAttributedStringAttribute alloc] init:NSUnderlineColorAttributeName propertyType:ISSPropertyTypeColor];
        attrs[@"underlinestyle"] = [[ISSAttributedStringAttribute alloc] init:NSUnderlineStyleAttributeName enumMapping:underlineStyleMapping];
        // TODO: NSTextEffectAttributeName
        
        attrs[@"color"] = attrs[@"foregroundcolor"];
        
        _attributedStringProperties = [attrs copy];
    }
    return self;
}

- (void) setupPropertyParsersWith:(ISSStyleSheetParser*)styleSheetParser {
    _styleSheetParser = styleSheetParser;
    
    __weak ISSStyleSheetPropertyParser* blockSelf = self;
    
    
    // Property parser setup:
    
    /** -- String -- **/
    ISSParser* defaultStringParser = [ISSParser parserWithBlock:^id(NSString* input, ISSParserStatus* status) {
        status->match = YES;
        return [self cleanedStringValue:input];
    } andName:@"defaultStringParser"];
    
    ISSParser* cleanedQuotedStringParser = [styleSheetParser.quotedString transform:^id(id input, void* context) {
        return [self cleanedStringValue:input];
    } name:@"quotedStringParser"];
    
    ISSParser* localizedStringParser = [[styleSheetParser singleParameterFunctionParserWithNames:@[@"localized", @"L"] parameterParser:cleanedQuotedStringParser] transform:^id(id value, void* context) {
        return [self localizedStringWithKey:value];
    } name:@"localizedStringParser"];
    
    ISSParser* stringParser = [ISSParser choice:@[localizedStringParser, cleanedQuotedStringParser, defaultStringParser]];
    
    _typeToParser[ISSPropertyTypeString] = stringParser;
    
    
    /** -- BOOL -- **/
    ISSParser* boolValueParser = [self.styleSheetParser.identifier transform:^id(id value, void* context) {
        return @([value boolValue]);
    } name:@"bool"];
    _typeToParser[ISSPropertyTypeBool] = [ISSParser choice:@[[self.styleSheetParser logicalExpressionParser], boolValueParser]];
    
    
    /** -- Number -- **/
    _typeToParser[ISSPropertyTypeNumber] = self.styleSheetParser.numberOrExpressionValue;
    
    
    /** -- AttributedString -- **/
    ISSParser* attributedStringAttributesParser = [[self.styleSheetParser parameterString] transform:^id(NSArray* values, void* context) {
        NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
        for(NSString* pairString in values) {
            NSArray* components = [pairString iss_trimmedSplit:@":"];
            if( components.count == 2 && [components[0] iss_hasData] && [components[1] iss_hasData] ) {
                // Get property def
                BOOL valueSet = [self setValue:components[1] forKey:components[0] inAttributedStringAttributes:attributes];
                if( !valueSet ) {
                    ISSLogWarning(@"Unknown attributed string value `%@` for property `%@`", components[1], components[0]);
                }
            }
        }
        return attributes;
    } name:@"attributedStringAttributesParser"];
    
    ISSParser* quotedOrLocalizedStringParser = [ISSParser choice:@[localizedStringParser, cleanedQuotedStringParser]];
    
    ISSParser* singleAttributedStringParser = [[ISSParser sequential:@[ [quotedOrLocalizedStringParser skipSurroundingSpaces], attributedStringAttributesParser ]] transform:^id(NSArray* values, void* context) {
        return [[NSAttributedString alloc] initWithString:values[0] attributes:values[1]];
    } name:@"singleAttributedStringParser"];
    
    ISSParser* delimeter = [ISSParser choice:@[self.styleSheetParser.comma, [ISSParser spaces]]];
    ISSParser* attributedStringParser = [[[singleAttributedStringParser skipSurroundingSpaces] sepBy1:delimeter] transform:^id(NSArray* values, void* context) {
        NSMutableAttributedString* mutableAttributedString = [[NSMutableAttributedString alloc] init];
        for(NSAttributedString* attributedString in values) {
            [mutableAttributedString appendAttributedString:attributedString];
        }
        return mutableAttributedString;
    } name:@"attributedStringParser"];
    
    _typeToParser[ISSPropertyTypeAttributedString] = attributedStringParser;
    
    
    /** -- Text attributes -- **/
    _typeToParser[ISSPropertyTypeTextAttributes] = attributedStringAttributesParser; // Reusing attributed string attributes parser
    
    
    /** -- CGRect -- **/
    ISSParser* rectValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"rect"] transform:^id(NSArray* c, void* context) {
        CGRect rect = CGRectZero;
        if( c.count == 4 ) rect = CGRectMake(iss_floatAt(c,0), iss_floatAt(c,1), iss_floatAt(c,2), iss_floatAt(c,3));
        return [NSValue valueWithCGRect:rect];
    } name:@"rect"];
    ISSParser* cgRectFromStringParser = [cleanedQuotedStringParser transform:^id _Nonnull(id  _Nonnull value, void* context) {
        return [NSValue valueWithCGRect:CGRectFromString(value)];
    }];
    _typeToParser[ISSPropertyTypeRect] = [ISSParser choice:@[rectValueParser, cgRectFromStringParser]];
    
    
    /** -- UIOffset -- **/
    ISSParser* offsetValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"offset"] transform:^id(NSArray* c, void* context) {
        UIOffset offset = UIOffsetZero;
        if( c.count == 2 ) offset = UIOffsetMake(iss_floatAt(c,0), iss_floatAt(c,1));
        else if( c.count == 1 ) offset = UIOffsetMake(iss_floatAt(c,0), iss_floatAt(c,0));
        return [NSValue valueWithUIOffset:offset];
    } name:@"offset"];
    ISSParser* uiOffsetFromParser = [cleanedQuotedStringParser transform:^id _Nonnull(id  _Nonnull value, void* context) {
        return [NSValue valueWithUIOffset:UIOffsetFromString(value)];
    }];
    _typeToParser[ISSPropertyTypeOffset] = [ISSParser choice:@[offsetValueParser, uiOffsetFromParser]];
    
    
    /** -- CGSize -- **/
    ISSParser* sizeValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"size"] transform:^id(NSArray* c, void* context) {
        CGSize size = CGSizeZero;
        if( c.count == 2 ) size = CGSizeMake(iss_floatAt(c,0), iss_floatAt(c,1));
        else if( c.count == 1 ) size = CGSizeMake(iss_floatAt(c,0), iss_floatAt(c,0));
        return [NSValue valueWithCGSize:size];
    } name:@"size"];
    ISSParser* cgSizeFromStringParser = [cleanedQuotedStringParser transform:^id _Nonnull(id  _Nonnull value, void* context) {
        return [NSValue valueWithCGSize:CGSizeFromString(value)];
    }];
    _typeToParser[ISSPropertyTypeSize] = [ISSParser choice:@[sizeValueParser, cgSizeFromStringParser]];
    
    
    /** -- CGPoint -- **/
    ISSParser* pointValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"point"] transform:^id(NSArray* c, void* context) {
        CGPoint point = CGPointZero;
        if( c.count == 2 ) point = CGPointMake(iss_floatAt(c,0), iss_floatAt(c,1));
        else if( c.count == 1 ) point = CGPointMake(iss_floatAt(c,0), iss_floatAt(c,0));
        return [NSValue valueWithCGPoint:point];
    } name:@"point"];
    ISSParser* cgPointFromStringParser = [cleanedQuotedStringParser transform:^id _Nonnull(id  _Nonnull value, void* context) {
        return [NSValue valueWithCGPoint:CGPointFromString(value)];
    }];
    _typeToParser[ISSPropertyTypePoint] = [ISSParser choice:@[pointValueParser, cgPointFromStringParser]];
    
    
    /** -- UIEdgeInsets -- **/
    ISSParser* insetsValueParser = [[self simpleNumericParameterStringWithOptionalPrefix:@"insets"] transform:^id(NSArray* c, void* context) {
        UIEdgeInsets insets = UIEdgeInsetsZero;
        if( c.count == 4 ) insets = UIEdgeInsetsMake(iss_floatAt(c,0), iss_floatAt(c,1), iss_floatAt(c,2), iss_floatAt(c,3));
        else if( c.count == 2 ) insets = UIEdgeInsetsMake(iss_floatAt(c,0), iss_floatAt(c,1), iss_floatAt(c,0), iss_floatAt(c,1));
        else if( c.count == 1 ) insets = UIEdgeInsetsMake(iss_floatAt(c,0), iss_floatAt(c,0), iss_floatAt(c,0), iss_floatAt(c,0));
        return [NSValue valueWithUIEdgeInsets:insets];
    } name:@"insets"];
    ISSParser* uiEdgeInsetsFromStringParser = [cleanedQuotedStringParser transform:^id _Nonnull(id  _Nonnull value, void* context) {
        return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsFromString(value)];
    }];
    _typeToParser[ISSPropertyTypeEdgeInsets] = [ISSParser choice:@[insetsValueParser, uiEdgeInsetsFromStringParser]];
    
    
    /** -- UIImage (1) -- **/
    // Ex: image.png
    // Ex: image(image.png);
    // Ex: image(image.png, 1, 2);
    // Ex: image(image.png, 1, 2, 3, 4);
    ISSParser* imageParser = [[self.styleSheetParser parameterStringWithPrefix:@"image"] transform:^id(NSArray* cc, void* context) {
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
    _typeToParser[ISSPropertyTypeColor] = colorPropertyParser;
    _typeToParser[ISSPropertyTypeCGColor] = [colorPropertyParser transform:^id (id value, void* context) {
        return (id)((UIColor*)value).CGColor;
    }];
    
    
    /** -- UIImage (2) -- **/
    ISSParser* imageParsers = [self imageParsers:imageParser colorValueParsers:uiColorValueParsers];
    _typeToParser[ISSPropertyTypeImage] = imageParsers;
    
    
    /** -- CGAffineTransform -- **/
    // Ex: rotate(90) scale(2,2) translate(100,100);
    ISSParser* rotateValueParser = [[self simpleNumericParameterStringWithPrefix:@"rotate" optionalPrefix:NO] transform:^id(NSArray* values, void* context) {
        CGFloat angle = [[values firstObject] floatValue];
        angle = ((CGFloat)M_PI * angle / 180.0f);
        return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeRotation(angle)];
    } name:@"rotate"];
    ISSParser* scaleValueParser = [[self simpleNumericParameterStringWithPrefix:@"scale" optionalPrefix:NO] transform:^id(NSArray* c, void* context) {
        if( c.count == 2 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(iss_floatAt(c,0), iss_floatAt(c,1))];
        else if( c.count == 1 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeScale(iss_floatAt(c,0), iss_floatAt(c,0))];
        else return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
    } name:@"scale"];
    ISSParser* translateValueParser = [[self simpleNumericParameterStringWithPrefix:@"translate" optionalPrefix:NO] transform:^id(NSArray* c, void* context) {
        if( c.count == 2 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation(iss_floatAt(c,0), iss_floatAt(c,1))];
        else if( c.count == 1 ) return [NSValue valueWithCGAffineTransform:CGAffineTransformMakeTranslation(iss_floatAt(c,0), iss_floatAt(c,0))];
        else return [NSValue valueWithCGAffineTransform:CGAffineTransformIdentity];
    } name:@"translate"];
    ISSParser* transformValuesParser = [[[ISSParser choice:@[rotateValueParser, scaleValueParser, translateValueParser]] many] transform:^id(id value, void* context) {
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
    _typeToParser[ISSPropertyTypeTransform] = transformValuesParser;
    
    
    /** -- UIFont -- **/
    // Ex: Helvetica 12
    // Ex: bigger(@font, 1)
    // Ex: smaller(@font, 1)
    // Ex: fontWithSize(@font, 12)
    ISSParser* commaOrSpace = [[ISSParser choice:@[[ISSParser space], self.styleSheetParser.comma]] many1];
    ISSParser* remoteFontValueURLParser = [[ISSParser choice:@[self.styleSheetParser.quotedString, self.styleSheetParser.anyName]] transform:^id(id input, void* context) {
        return [NSURL URLWithString:[input iss_trimQuotes]];
    } name:@"remoteFontValueURLParser"];
    ISSParser* remoteFontValueParser = [self.styleSheetParser singleParameterFunctionParserWithName:@"url" parameterParser:remoteFontValueURLParser];
    ISSParser* fontNameParser = [ISSParser choice:@[self.styleSheetParser.quotedString, self.styleSheetParser.anyName]];
    ISSParser* fontValueParser = [ISSParser choice:@[remoteFontValueParser, self.styleSheetParser.quotedString, self.styleSheetParser.anyName]];
    
    ISSParser* fontParser = [[fontNameParser keepLeft:commaOrSpace] then:fontValueParser];
    fontParser = [fontParser transform:^id(NSArray* values, void* context) {
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
                        if( [lc hasPrefix:@"http://"] || [lc hasPrefix:@"https://"] ) { // Fallback, if not url(...) format is used
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
    
    ISSParser* fontFunctionParser = [[ISSParser sequential:@[self.styleSheetParser.identifier, [ISSParser unichar:'(' skipSpaces:YES],
                                                             fontParser, [ISSParser unichar:',' skipSpaces:YES], self.styleSheetParser.plainNumber, [ISSParser unichar:')' skipSpaces:YES]]] transform:^id(id value, void* context) {
        UIFont* font = iss_elementOfTypeOrNil(value, 2, UIFont.class);
        float floatValue = [iss_elementOrNil(value, 4) floatValue];
        if( font ) {
            if( [@"larger" iss_isEqualIgnoreCase:value[0]] || [@"bigger" iss_isEqualIgnoreCase:value[0]] ) return [blockSelf fontWithSize:value[2] size:[font pointSize] + floatValue];
            else if( [@"smaller" iss_isEqualIgnoreCase:value[0]] ) return [blockSelf fontWithSize:value[2] size:[font pointSize] - floatValue];
            else if( [@"fontWithSize" iss_isEqualIgnoreCase:value[0]] ) return [blockSelf fontWithSize:value[2] size:floatValue];
            else return value[2];
        }
#if TARGET_OS_TV == 0
        return [UIFont systemFontOfSize:[UIFont systemFontSize]];
#else
        return [UIFont systemFontOfSize:17];
#endif
    } name:@"fontFunctionParser"];
    
#if ISS_OS_VERSION_MAX_ALLOWED >= 110000
    if (@available(iOS 11.0, tvOS 11.0, *)) {
        NSDictionary* textStyleMapping = @{@"body" : UIFontTextStyleBody,
                                           @"callout" : UIFontTextStyleCallout,
                                           @"caption1" : UIFontTextStyleCaption1,
                                           @"caption2" : UIFontTextStyleCaption2,
                                           @"footnote" : UIFontTextStyleFootnote,
                                           @"headline" : UIFontTextStyleHeadline,
                                           @"subheadline" : UIFontTextStyleSubheadline,
                                           @"title1" : UIFontTextStyleTitle1,
                                           @"title2" : UIFontTextStyleTitle2,
                                           @"title3" : UIFontTextStyleTitle3};
        
        ISSParser* optionalTextStyle = [ISSParser optional:[ISSParser sequential:@[[ISSParser unichar:',' skipSpaces:YES], [ISSParser choice:@[self.styleSheetParser.quotedString, self.styleSheetParser.anyName]]]]];
        
        //ISSParser* dynamicTypeFontFunctionParser = [[self.styleSheetParser parameterStringWithPrefix:@"scalableFont"] transform:^id(id value) {
        ISSParser* dynamicTypeFontFunctionParser = [[ISSParser sequential:@[self.styleSheetParser.identifier, [ISSParser unichar:'(' skipSpaces:YES],
                                                                            fontValueParser, optionalTextStyle, [ISSParser unichar:')' skipSpaces:YES]]] transform:^id(id value, void* context) {
            NSArray* values = [value iss_flattened];
            UIFont* font = iss_elementOfTypeOrNil(values, 2, UIFont.class);
            id styleRaw = iss_elementOrNil(values, 4);
            UIFontTextStyle style = styleRaw ? textStyleMapping[styleRaw] : nil;
            if ( font && style ) {
                return [[[UIFontMetrics alloc] initForTextStyle:style] scaledFontForFont:font];
            } else if( font ) {
                return [UIFontMetrics.defaultMetrics scaledFontForFont:font];
            }
            return [UIFont systemFontOfSize:17];
        } name:@"dynamicTypeFontFunctionParser"];
        
        _typeToParser[ISSPropertyTypeFont] = [ISSParser choice:@[dynamicTypeFontFunctionParser, fontFunctionParser, fontParser]];
    } else {
        _typeToParser[ISSPropertyTypeFont] = [ISSParser choice:@[fontFunctionParser, fontParser]];
    }
#else
    _typeToParser[ISSPropertyTypeFont] = [ISSParser choice:@[fontFunctionParser, fontParser]];
#endif
    
    /** -- Enums -- **/
    ISSParser* commaOrSpaceOrPipe = [[ISSParser choice:@[[ISSParser space], self.styleSheetParser.comma, [ISSParser unichar:'|']]] many1];
    
    ISSParser* enumValueParser = [ISSParser choice:@[self.styleSheetParser.identifier, cleanedQuotedStringParser, defaultStringParser]];
    _typeToParser[ISSPropertyTypeEnumType] = [[enumValueParser sepBy:commaOrSpaceOrPipe] concat:@" "];
}



- (ISSParser*) parserForPropertyType:(ISSPropertyType)propertyType {
    return self.typeToParser[propertyType];
}

- (void) setParser:(ISSParser*)parser forPropertyType:(ISSPropertyType)propertyType {
    self.typeToParser[propertyType] = parser;
}



- (id) parsePropertyValue:(NSString*)propertyValue ofType:(ISSPropertyType)type {
    ISSParser* valueParser = self.typeToParser[type];
    
    ISSParserStatus status = {};
    id parseResult = [valueParser parse:propertyValue status:&status];
    if( status.match ) return parseResult;
    
    return nil;
}


#pragma mark - Color parsing

- (NSArray*) basicColorValueParsers {
    ISSParser* rgb = [[self.styleSheetParser parameterStringWithPrefix:@"rgb"] transform:^id(NSArray* cc, void* context) {
        UIColor* color = [UIColor magentaColor];
        if( cc.count == 3 ) {
            color = [UIColor iss_colorWithR:[cc[0] intValue] G:[cc[1] intValue] B:[cc[2] intValue]];
        }
        return color;
    } name:@"rgb"];
    
    ISSParser* rgba = [[self.styleSheetParser parameterStringWithPrefix:@"rgba"] transform:^id(NSArray* cc, void* context) {
        UIColor* color = [UIColor magentaColor];
        if( cc.count == 4 ) {
            color = [UIColor iss_colorWithR:[cc[0] intValue] G:[cc[1] intValue] B:[cc[2] intValue] A:[cc[3] floatValue]];
        }
        return color;
    } name:@"rgba"];
    
    NSMutableCharacterSet* hexDigitsSetMutable = [NSMutableCharacterSet characterSetWithCharactersInString:@"aAbBcCdDeEfF"];
    [hexDigitsSetMutable formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
    NSCharacterSet* hexDigitsSet = [hexDigitsSetMutable copy];
    
    ISSParser* hexColor = [[[ISSParser unichar:'#'] keepRight:[ISSParser takeWhileInSet:hexDigitsSet minCount:3]] transform:^id(id value, void* context) {
        return [UIColor iss_colorWithHexString:value];
    } name:@"hex"];
    
    return @[rgb, rgba, hexColor];
}

- (UIColor*) parsePredefColorValue:(id)value {
    UIColor* color = [UIColor magentaColor];
    NSString* colorString = [[value iss_trimQuotes] lowercaseString];
    if( ![colorString hasSuffix:@"color"] ) colorString = [colorString stringByAppendingString:@"color"];
    
    // TODO: Consider caching
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
    
    ISSParser* colorFunctionParser = [[ISSParser sequential:@[self.styleSheetParser.identifier, [ISSParser unichar:'(' skipSpaces:YES],
                                                              [ISSParser choice:colorValueParsers], [ISSParser unichar:',' skipSpaces:YES], self.styleSheetParser.anyName, [ISSParser unichar:')' skipSpaces:YES]]] transform:^id(id value, void* context) {
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
    ISSParser* catchAll = [self.styleSheetParser.anyName transform:^id(id value, void* context) {
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
    ISSParser* patternImageParser = [imageParser transform:^id(id value, void* context) {
        UIColor* color = [UIColor magentaColor];
        if( [value isKindOfClass:UIImage.class] ) color = [UIColor colorWithPatternImage:value];
        return color;
    } name:@"patternImage"];
    
    return @[patternImageParser, catchAll];
}


#pragma mark - Image parsing

- (ISSParser*) imageParsers:(ISSParser*)imageParser colorValueParsers:(NSArray*)colorValueParsers {
    ISSParser* preDefColorParser = [self.styleSheetParser.identifier transform:^id(id value, void* context) {
        return [self parsePredefColorValue:value];
    } name:@"preDefColorParser"];
    
    // Parse color functions as UIImage
    ISSParser* colorFunctionParser = [self colorFunctionParser:colorValueParsers preDefColorParser:preDefColorParser];
    ISSParser* colorFunctionAsImage = [colorFunctionParser transform:^id(id value, void* context) {
        return [value iss_asUIImage];
    } name:@"colorFunctionAsImage"];
    
    // Parses well defined color values (i.e. [-basicColorValueParsers])
    ISSParser* colorParser = [ISSParser choice:colorValueParsers];
    ISSParser* imageAsColor = [colorParser transform:^id(id value, void* context) {
        return [value iss_asUIImage];
    } name:@"patternImage"];
    
    ISSParser* urlImageParser = [[self.styleSheetParser parameterStringWithPrefix:@"url"] transform:^id(NSArray* parameters, void* context) {
        return [ISSDownloadableResource downloadableImageWithURL:[NSURL URLWithString:[[parameters firstObject] iss_trimQuotes]]];
    } name:@"urlImage"];
    
    // Parses an arbitrary text string as an image from file name or pre-defined color name - in that order
    ISSParser* catchAll = [self.styleSheetParser.anythingButControlChars transform:^id(id value, void* context) {
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
    ISSParser* preDefColorParser = [self.styleSheetParser.identifier transform:^id(id value, void* context) {
        return [self parsePredefColorValue:value];
    } name:@"preDefcolorParser"];
    
    ISSParser* colorFunctionParser = [self colorFunctionParser:colorValueParsers preDefColorParser:preDefColorParser];
    colorValueParsers = [@[colorFunctionParser] arrayByAddingObjectsFromArray:colorValueParsers];
    
    NSArray* finalColorParsers = colorValueParsers;
    finalColorParsers = [finalColorParsers arrayByAddingObjectsFromArray:colorCatchAllParsers];
    return [ISSParser choice:finalColorParsers];
}


#pragma mark - Misc (property) parsing related

- (NSString*) cleanedStringValue:(NSString*)string {
    return [[string iss_trimQuotes] iss_stringByReplacingUnicodeSequences];
}

- (UIFont*) fontWithSize:(UIFont*)font size:(CGFloat)size {
    if( [UIFont.class respondsToSelector:@selector(fontWithDescriptor:size:)] ) {
        return [UIFont fontWithDescriptor:font.fontDescriptor size:size];
    } else {
        return [font fontWithSize:size]; // Doesn't seem to work right in iOS7 (for some fonts anyway...)
    }
}

- (ISSParser*) simpleNumericParameterStringWithOptionalPrefix:(NSString*)optionalPrefix {
    return [self simpleNumericParameterStringWithPrefix:optionalPrefix optionalPrefix:YES];
}

- (ISSParser*) simpleNumericParameterStringWithPrefix:(NSString*)prefix optionalPrefix:(BOOL)optionalPrefix {
    return [self simpleNumericParameterStringWithPrefixes:@[prefix] optionalPrefix:optionalPrefix];
}

- (ISSParser*) simpleNumericParameterStringWithPrefixes:(NSArray*)prefixes optionalPrefix:(BOOL)optionalPrefix {
    ISSParser* parameterStringWithPrefixParser = [[self.styleSheetParser parameterStringWithPrefixes:prefixes] transform:^id(NSArray* parameters, void* context) {
        NSMutableArray* result = [NSMutableArray arrayWithCapacity:parameters.count];
        for(NSString* param in parameters) {
            [result addObject:[self.styleSheetParser parseMathExpression:param] ?: [NSNull null]];
        }
        return result;
    } name:[NSString stringWithFormat:@"simpleNumericParameterStringWithPrefixes(%@)", prefixes]];
    
    if( optionalPrefix ) {
        ISSParser* parameterStringParser = [self.styleSheetParser.numberOrExpressionValue sepBy1:[self.styleSheetParser.comma skipSurroundingSpaces]];
        return [ISSParser choice:@[parameterStringWithPrefixParser, parameterStringParser]];
    } else {
        return parameterStringWithPrefixParser;
    }
}

- (BOOL) setValue:(NSString*)rawValue forKey:(NSString*)key inAttributedStringAttributes:(NSMutableDictionary*)attributes {
    NSString* lcKey = [key lowercaseString];
    ISSAttributedStringAttribute* attr = self.attributedStringProperties[lcKey];
    if( attr ) {
        id parsedValue;
        if (attr.propertyType == ISSPropertyTypeEnumType) {
            parsedValue = [attr.enumMapping enumValueFromString:rawValue];
        } else {
            //parsedValue = [self.styleSheetParser parsePropertyValue:rawValue asType:attr.propertyType replaceVariableReferences:NO]; // Note: variables already replaced at this point...
            parsedValue = [self parsePropertyValue:rawValue ofType:attr.propertyType];
        }
        if( parsedValue ) {
            if( [attr.attributeName isEqualToString:NSShadowAttributeName] ) {
                NSShadow* shadow = attributes[NSShadowAttributeName] ?: [[NSShadow alloc] init];
                if( [lcKey isEqualToString:@"shadowcolor"] ) {
                    shadow.shadowColor = parsedValue;
                } else if( [lcKey isEqualToString:@"shadowoffset"] ) {
                    shadow.shadowOffset = [parsedValue CGSizeValue];
                }
                attributes[NSShadowAttributeName] = shadow;
            } else {
                attributes[attr.attributeName] = parsedValue;
            }
            return YES;
        }
    }
    return NO;
}


#pragma mark - Methods existing mainly for testing purposes

- (UIImage*) imageNamed:(NSString*)name { // For testing purposes...
    return [UIImage imageNamed:name];
}

- (NSString*) localizedStringWithKey:(NSString*)key {
    return NSLocalizedString(key, nil);
}

@end

