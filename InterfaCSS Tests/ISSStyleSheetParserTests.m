//
//  ISSStyleSheetParserTests.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <XCTest/XCTest.h>

#import "InterfaCSS.h"
#import "ISSStyleSheetParser.h"
#import "ISSPropertyDeclarations.h"
#import "ISSPropertyDeclaration.h"
#import "ISSPropertyDefinition.h"
#import "ISSSelectorChain.h"
#import "ISSSelector.h"
#import "ISSPointValue.h"
#import "ISSRectValue.h"
#import "UIColor+ISSColorAdditions.h"
#import "ISSDefaultStyleSheetParser.h"
#import "ISSLayout.h"
#import "ISSUIElementDetails.h"
#import "ISSParser.h"
#import "ISSParser+CSS.h"


@interface ISSDefaultStyleSheetTestParser : ISSDefaultStyleSheetParser
@end
@implementation ISSDefaultStyleSheetTestParser

- (UIImage*) imageNamed:(NSString*)name {
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:name ofType:nil];
    return [UIImage imageWithContentsOfFile:path];
}

- (NSString*) localizedStringWithKey:(NSString*)key {
    return [NSString stringWithFormat:@"%@.localized", key];
}

@end


static ISSDefaultStyleSheetTestParser* defaultParser;


@interface ISSStyleSheetParserTests : XCTestCase

@end


@implementation ISSStyleSheetParserTests {
    id<ISSStyleSheetParser> parser;
}

+ (void) setUp {
    [super setUp];
    
    defaultParser = [[ISSDefaultStyleSheetTestParser alloc] init];
}

- (void) setUp {
    [super setUp];
    parser = defaultParser;
}


#pragma mark - Utils

- (NSArray*) parseStyleSheet:(NSString*)name {
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:name ofType:@"css"];
    NSString* styleSheetData = [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];
    return [parser parse:styleSheetData];
}

- (NSArray*) getAllPropertyDeclarationsForStyleClass:(NSString*)styleClass inStyleSheet:(NSString*)stylesheet {
    NSArray* result = [self parseStyleSheet:stylesheet];
    
    NSMutableArray* declarations = [NSMutableArray array];
    for (ISSPropertyDeclarations* d in result) {
        if( [[[d.selectorChains[0] selectorComponents][0] styleClass] isEqualToString:styleClass] ) {
            [declarations addObject:d];
        }
    }
    return declarations;
}

- (ISSPropertyDeclarations*) getPropertyDeclarationsForStyleClass:(NSString*)styleClass inStyleSheet:(NSString*)stylesheet {
    return [[self getAllPropertyDeclarationsForStyleClass:styleClass inStyleSheet:stylesheet] firstObject];
}

- (NSArray*) getPropertyValuesWithNames:(NSArray*)names fromDeclarations:(ISSPropertyDeclarations*)declarations getDeclarations:(BOOL)getDeclarations {
    NSMutableArray* values = [NSMutableArray array];
    
    for(NSString* name in names) {
        id value = nil;
        for(ISSPropertyDeclaration* d in declarations.properties) {
            NSString* propertyName = d.property.name;
            if( d.nestedElementKeyPath && ![d.nestedElementKeyPath isEqualToString:@"layer"] ) {
                propertyName = [[d.nestedElementKeyPath stringByAppendingString:@"."] stringByAppendingString:propertyName];
            }
            
            if( [propertyName iss_isEqualIgnoreCase:name] || [d.property.allNames containsObject:[name lowercaseString]] ) {
                if( getDeclarations ) value = d;
                else {
                    [d transformValueIfNeeded];
                    value = d.propertyValue;
                }
            }
        }
        
        if( value ) [values addObject:value];
    }
    
    return values;
}

- (NSArray*) getPropertyValuesWithNames:(NSArray*)names fromStyleClass:(NSString*)styleClass getDeclarations:(BOOL)getDeclarations {
    ISSPropertyDeclarations* declarations = [self getPropertyDeclarationsForStyleClass:[styleClass lowercaseString] inStyleSheet:@"styleSheetPropertyValues"];
    
    return [self getPropertyValuesWithNames:names fromDeclarations:declarations getDeclarations:getDeclarations];
}

- (NSArray*) getPropertyValuesWithNames:(NSArray*)names fromStyleClass:(NSString*)styleClass {
    return [self getPropertyValuesWithNames:names fromStyleClass:styleClass getDeclarations:NO];
}

- (NSArray*) getAllPropertyValuesWithNames:(NSArray*)names fromStyleClass:(NSString*)styleClass getDeclarations:(BOOL)getDeclarations {
    NSArray* allDeclarations = [self getAllPropertyDeclarationsForStyleClass:[styleClass lowercaseString] inStyleSheet:@"styleSheetPropertyValues"];
    
    NSMutableArray* result = [NSMutableArray array];
    for(ISSPropertyDeclarations* declarations in allDeclarations) {
        [result addObjectsFromArray:[self getPropertyValuesWithNames:names fromDeclarations:declarations getDeclarations:getDeclarations]];
    }
    return result;
}


- (id) getSimplePropertyValueWithName:(NSString*)name {
    return [[self getPropertyValuesWithNames:@[name] fromStyleClass:@"simple"] firstObject];
}

- (UIColor*) colorOfFirstPixel:(UIImage*)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char* pixelData = (unsigned char*)calloc(4, sizeof(unsigned char));
    CGContextRef context = CGBitmapContextCreate(pixelData, 1, 1, 8, 4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, 1, 1), image.CGImage);
    CGContextRelease(context);
    
    NSInteger r = pixelData[0];
    NSInteger g = pixelData[1];
    NSInteger b = pixelData[2];
    NSInteger a = pixelData[3];
  
    free(pixelData);
    
    return [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a/255.0f];
    
}

- (BOOL) compareColorWithTolerance:(UIColor*)color1 color2:(UIColor*)color2 {
    NSArray* col1Components = [color1 iss_rgbaComponents];
    NSArray* col2Components = [color2 iss_rgbaComponents];
    for(NSUInteger i=0; i<4; i++) {
        CGFloat diff = [col1Components[i] floatValue] - [col2Components[i] floatValue];
        if( diff > (1.0f/255.0f) ) {
            return NO;
        }
    }
    return YES;
}


#pragma mark - Tests - bad data

- (void) testStyleSheetWithBadData {
    NSArray* result = [self parseStyleSheet:@"styleSheetWithBadData"];
    
    XCTAssertEqual(result.count, (NSUInteger)2, @"Expected two entries");
    
    ISSPropertyDeclarations* declarations = result[0];
    XCTAssertEqual(declarations.properties.count, (NSUInteger)1, @"Expected one property declaration");
    ISSPropertyDeclaration* declaration = declarations.properties[0];
    XCTAssertEqualObjects(declaration.property.name, @"alpha", @"Expected property alpha");
    
    declarations = result[1];
    XCTAssertEqual(declarations.properties.count, (NSUInteger)1, @"Expected one property declaration");
    declaration = declarations.properties[0];
    XCTAssertEqualObjects(declaration.property.name, @"clipsToBounds", @"Expected property clipsToBounds");
}


#pragma mark - Tests - structure

- (void) testStylesheetStructure {
    NSArray* result = [self parseStyleSheet:@"styleSheetStructure"];
    NSMutableSet* expectedSelectors = [[NSMutableSet alloc] initWithArray:@[@"uilabel", @"uilabel.class1", @"uilabel#identity.class1", @"#identity.class1", @".class1",
                                                                            @"uiview .class1 .class2", @"uilabel, uilabel.class1, .class1, uiview .class1 .class2",
                                                                            @"uiview > .class1 + .class2 ~ .class3", @"uiview", @"uiview .classn1", @"uiview .classn1 .classn2",
                                                                            @"uiview:onlychild", @"uiview:minosversion(8.4)", @"uiview#identifier.class1:onlychild", @"uiview:nthchild(2n+1)", @"uiview uilabel:firstoftype", @"uiview.classx", @"uiview.classx uilabel:lastoftype", @"uiview:pad:landscape", @"uiview:portrait:phone",
                                                                            @"* uiview", @"* uiview *", @"uiview *", @"uiview * uiview"]];
    
    for (ISSPropertyDeclarations* d in result) {
        NSMutableArray* chains = [NSMutableArray array];
        [d.selectorChains enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [chains addObject:[obj displayDescription]];
        }];
        NSString* selectorDescription = [chains componentsJoinedByString:@", "];
        
        ISSPropertyDeclaration* decl = d.properties.count ? d.properties[0] : nil;
        [decl transformValueIfNeeded];
        if( decl && [decl.propertyValue isEqual:@(0.666)] ) {
            if( [expectedSelectors containsObject:selectorDescription] ) {
                [expectedSelectors removeObject:selectorDescription];
            } else {
                NSLog(@"Didn't find: %@", selectorDescription);
            }
        } else {
            NSLog(@"Didn't find: %@", selectorDescription);
        }
    }
    
    XCTAssertEqual((NSUInteger)0, expectedSelectors.count, @"Not all selectors were found");
}


#pragma mark - Tests - property values


- (void) testNumberPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"alpha"];
    ISSAssertEqualFloats([value floatValue], 0.33f, @"Expected value '0.33' for property alpha");
    
    value = [self getSimplePropertyValueWithName:@"cornerRadius"];
    XCTAssertEqualObjects(value, @(5), @"Expected value '5' for property cornerRadius");
}

- (void) testBooleanPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"clipsToBounds"];
    XCTAssertEqualObjects(value, @YES, @"Expected value 'YES' for property clipsToBounds");
}

- (void) testStringPropertyValue {
    NSArray* values = [self getPropertyValuesWithNames:@[@"text", @"title", @"prompt"] fromStyleClass:@"simple"];
    XCTAssertEqualObjects(values[0], @"Text's:", @"Expected value 'Text:' for property text");
    XCTAssertEqualObjects(values[1], @"Title", @"Expected value 'Title' for property title");
    XCTAssertEqualObjects(values[2], @"Prompt", @"Expected value 'Prompt' for property prompt");
}

- (void) testLocalizedStringPropertyValue {
    NSArray* values = [self getPropertyValuesWithNames:@[@"text", @"title", @"attributedText"] fromStyleClass:@"localizedStrings"];
    XCTAssertEqualObjects(values[0], @"Text.localized");
    XCTAssertEqualObjects(values[1], @"Title.localized");
    XCTAssertEqualObjects([values[2] string], @"text1.localized-text2.localized");
}

- (void) testStringsWithEscapes {
    NSArray* values = [self getPropertyValuesWithNames:@[@"text", @"attributedText"] fromStyleClass:@"stringsWithEscapes"];
    XCTAssertEqualObjects(values[0], @"dr \"evil\" rules");
    XCTAssertEqualObjects([values[1] string], @"dr \"evil\" rules, and so does austin \"danger\" powers");
}

- (void) testOffsetPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"searchTextPositionAdjustment"];
    UIOffset offset = [value isKindOfClass:NSValue.class] ? [value UIOffsetValue] : UIOffsetZero;
    XCTAssertTrue(UIOffsetEqualToOffset(offset, UIOffsetMake(1, 2)), @"Expected UIOffset value of '{1, 2}' for property searchTextPositionAdjustment, got: %@", value);
}

- (void) testSizePropertyValue {
    id value = [self getSimplePropertyValueWithName:@"contentSize"];
    CGSize size = [value isKindOfClass:NSValue.class] ? [value CGSizeValue] : CGSizeZero;
    XCTAssertTrue(CGSizeEqualToSize(size, CGSizeMake(3, 4)), @"Expected CGSize value of '{3, 4}' for property contentSize, got: %@", value);
}

- (void) testInsetPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"contentInset"];
    UIEdgeInsets insets = [value isKindOfClass:NSValue.class] ? [value UIEdgeInsetsValue] : UIEdgeInsetsZero;
    XCTAssertTrue(UIEdgeInsetsEqualToEdgeInsets(insets, UIEdgeInsetsMake(10, 20, 30, 40)), @"Expected UIEdgeInsets value of '{10, 20, 30, 40}' for property contentInset, got: %@", value);
}

- (void) testPointPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"center"];
    CGPoint point = [value isKindOfClass:ISSPointValue.class] ? [value point] : CGPointZero;
    XCTAssertTrue(CGPointEqualToPoint(point, CGPointMake(5, 6)), @"Expected CGPoint value of '{5, 6}' for property center, got: %@", value);
}

- (void) testParentRelativePointPropertyValue {
    id value = [[self getPropertyValuesWithNames:@[@"center"] fromStyleClass:@"point1"] firstObject];

    UIView* parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    [parent addSubview:view];
    
    ISSPointValue* pointValue = [value isKindOfClass:ISSPointValue.class] ? value : nil;
    CGPoint point = [pointValue pointForView:view];
    XCTAssertTrue(CGPointEqualToPoint(point, CGPointMake(150, 50)), @"Expected CGPoint value of '{150, 50}' for property center, got: %@", value);
}

- (void) testWindowRelativePointPropertyValue {
    id value = [[self getPropertyValuesWithNames:@[@"center"] fromStyleClass:@"point2"] firstObject];
    
    UIWindow* parent = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    [parent addSubview:view];
    
    ISSPointValue* pointValue = [value isKindOfClass:ISSPointValue.class] ? value : nil;
    CGPoint point = [pointValue pointForView:view];
    XCTAssertTrue(CGPointEqualToPoint(point, CGPointMake(200, 100)), @"Expected CGPoint value of '{150, 50}' for property center, got: %@", value);
}

- (void) testAbsoluteRectPropertyValues {
    NSArray* values = [self getPropertyValuesWithNames:@[@"frame", @"bounds"] fromStyleClass:@"simple"];

    id value = [values firstObject];
    ISSRectValue* rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    XCTAssertTrue(CGRectEqualToRect(rectValue.rect, CGRectMake(1, 2, 3, 4)), @"Expected CGRect value of '{1, 2, 3, 4}' for property frame, got: %@", value);
    
    value = [values lastObject];
    rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    XCTAssertTrue(CGRectEqualToRect(rectValue.rect, CGRectMake(0, 0, 10, 20)), @"Expected CGRect value of '{0, 0, 10, 20}' for property bounds, got: %@", value);
}

- (void) testParentInsetRectPropertyValues {
    NSArray* values = [self getPropertyValuesWithNames:@[@"frame", @"bounds"] fromStyleClass:@"rect1"];
    
    UIView* parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    [parent addSubview:view];
    
    id value = [values firstObject];
    ISSRectValue* rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    CGRect rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(10, 10, 180, 180)), @"Expected CGRect value of '{10, 10, 180, 180}' for property bounds, got: %@(%@)", NSStringFromCGRect(rect), value);
    
    value = [values lastObject];
    rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(20, 10, 140, 160)), @"Expected CGRect value of '{20, 10, 140, 170}' for property bounds, got: %@(%@)", NSStringFromCGRect(rect), value);
}

- (void) testWindowInsetRectPropertyValues {
    NSArray* values = [self getPropertyValuesWithNames:@[@"frame", @"bounds"] fromStyleClass:@"rect2"];
    
    UIWindow* parent = [[UIWindow alloc] initWithFrame:CGRectMake(0, 0, 300, 300)];
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    [parent addSubview:view];
    
    id value = [values firstObject];
    ISSRectValue* rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    CGRect rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(10, 10, 280, 280)), @"Expected CGRect value of '{10, 10, 180, 180}' for property bounds, got: %@(%@)", NSStringFromCGRect(rect), value);
    
    value = [values lastObject];
    rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(20, 10, 240, 260)), @"Expected CGRect value of '{20, 10, 140, 170}' for property bounds, got: %@(%@)", NSStringFromCGRect(rect), value);
}

- (void) testRelativeRectPropertyValues {
    NSArray* values = [self getPropertyValuesWithNames:@[@"frame", @"bounds"] fromStyleClass:@"rect3"];
    
    UIView* parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    [parent addSubview:view];
    
    id value = [values firstObject];
    ISSRectValue* rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    CGRect rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(10, 20, 20, 40)), @"Expected CGRect value of '{10, 20, 20, 40}' for property frame, got: %@(%@)", NSStringFromCGRect(rect), value);
    
    value = [values lastObject];
    rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(110, 80, 60, 80)), @"Expected CGRect value of '{110, 80, 60, 80}' for property bounds, got: %@(%@)", NSStringFromCGRect(rect), value);
}

- (void) testAutoRelativeRectPropertyValues {
    NSArray* values = [self getPropertyValuesWithNames:@[@"frame", @"bounds"] fromStyleClass:@"rect4"];
    
    UIView* parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    [parent addSubview:view];
    
    id value = [values firstObject];
    ISSRectValue* rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    CGRect rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(20, 40, 180, 160)), @"Expected CGRect value of '{20, 40, 180, 160}' for property frame, got: %@(%@)", NSStringFromCGRect(rect), value);
    
    value = [values lastObject];
    rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(100, 0, 95, 200)), @"Expected CGRect value of '{100, 0, 95, 200}' for property bounds, got: %@(%@)", NSStringFromCGRect(rect), value);
}

- (void) testAutoRelativeRectPropertyValues2 {
    NSArray* values = [self getPropertyValuesWithNames:@[@"frame", @"bounds"] fromStyleClass:@"rect5"];
    
    UIView* parent = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 200)];
    UIView* view = [[UIView alloc] initWithFrame:CGRectZero];
    [parent addSubview:view];
    
    id value = [values firstObject];
    ISSRectValue* rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    CGRect rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(40, 20, 80, 120)), @"Expected CGRect value of '{40, 20, 80, 120}' for property frame, got: %@(%@)", NSStringFromCGRect(rect), value);
    
    value = [values lastObject];
    rectValue = [value isKindOfClass:ISSRectValue.class] ? value : nil;
    rect = [rectValue rectForView:view];
    XCTAssertTrue(CGRectEqualToRect(rect, CGRectMake(40, 20, 80, 120)), @"Expected CGRect value of '{40, 20, 80, 120}' for property bounds, got: %@(%@)", NSStringFromCGRect(rect), value);
}

- (void) testUIColorPropertyValue {
    NSArray* values = [self getPropertyValuesWithNames:@[@"color", @"tintColor", @"textColor", @"shadowColor"] fromStyleClass:@"simple"];
    XCTAssertEqualObjects(values[0], [UIColor iss_colorWithR:128 G:128 B:128]);
    XCTAssertEqualObjects(values[1], [UIColor iss_colorWithR:255 G:255 B:255]);
    XCTAssertEqualObjects(values[2], [UIColor iss_colorWithR:64 G:64 B:64 A:0.5]);
    XCTAssertEqualObjects(values[3], [UIColor redColor]);
}

- (void) testRGBAHexColorPropertyValues {
    NSArray* values = [self getPropertyValuesWithNames:@[@"color", @"titleColor", @"backgroundColor", @"tintColor", @"textColor", @"shadowColor"] fromStyleClass:@"hexColorsRGBA"];
    XCTAssertEqualObjects(values[0], [UIColor iss_colorWithR:64 G:128 B:176 A:0]);
    XCTAssertEqualObjects(values[1], [UIColor iss_colorWithR:0 G:255 B:128 A:1]);
    XCTAssertEqualObjects(values[2], [UIColor iss_colorWithR:0 G:0 B:0 A:128/255.0]);
    XCTAssertEqualObjects(values[3], [UIColor iss_colorWithR:128 G:0 B:0 A:0]);
    XCTAssertEqualObjects(values[4], [UIColor iss_colorWithR:128 G:0 B:0 A:1]);
    XCTAssertEqualObjects(values[5], [UIColor iss_colorWithR:128 G:0 B:0 A:128/255.0]);
}

- (void) testCompactHexColorPropertyValues {
    NSArray* values = [self getPropertyValuesWithNames:@[@"color", @"titleColor", @"backgroundColor", @"tintColor", @"textColor", @"shadowColor"] fromStyleClass:@"hexColorsCompact"];
    XCTAssertEqualObjects(values[0], [UIColor iss_colorWithR:0 G:0 B:0]);
    XCTAssertEqualObjects(values[1], [UIColor iss_colorWithR:255 G:255 B:255]);
    XCTAssertEqualObjects(values[2], [UIColor colorWithRed:0 green:0 blue:0 alpha:8/15.0f]);
    XCTAssertEqualObjects(values[3], [UIColor colorWithRed:8/15.0f green:8/15.0f blue:8/15.0f alpha:1]);
    XCTAssertEqualObjects(values[4], [UIColor colorWithRed:8/15.0f green:8/15.0f blue:8/15.0f alpha:8/15.0f]);
    XCTAssertEqualObjects(values[5], [UIColor colorWithRed:8/15.0f green:8/15.0f blue:8/15.0f alpha:0]);
}

- (void) testUIColorFunctionPropertyValues {
    NSArray* values = [self getPropertyValuesWithNames:@[@"color", @"titleColor", @"textColor", @"tintColor", @"shadowColor", @"sectionIndexColor", @"separatorColor"] fromStyleClass:@"colorfunctions"];
    UIColor* sourceColor = [UIColor iss_colorWithHexString:@"112233"];
    XCTAssertEqualObjects(values[0], [sourceColor iss_colorByIncreasingBrightnessBy:50.0f]);
    XCTAssertEqualObjects(values[1], [sourceColor iss_colorByIncreasingBrightnessBy:-50.0f]);
    XCTAssertEqualObjects(values[2], [sourceColor iss_colorByIncreasingSaturationBy:50.0f]);
    XCTAssertEqualObjects(values[3], [sourceColor iss_colorByIncreasingSaturationBy:-50.0f]);
    XCTAssertEqualObjects(values[4], [sourceColor iss_colorByIncreasingAlphaBy:50.0f]);
    XCTAssertEqualObjects(values[5], [sourceColor iss_colorByIncreasingAlphaBy:-50.0f]);
    XCTAssertEqualObjects(values[6], [[sourceColor iss_colorByIncreasingAlphaBy:-50.0f] iss_colorByIncreasingSaturationBy:50.0f]);
}

- (void) testParameterizedProperty {
    ISSPropertyDeclarations* declarations = [self getPropertyDeclarationsForStyleClass:@"simple" inStyleSheet:@"styleSheetPropertyValues"];
    ISSPropertyDeclaration* decl = nil;
    for(ISSPropertyDeclaration* d in declarations.properties) {
        if( [d.property.name isEqualToString:@"titleColor"] ) decl = d;
    }
    
    XCTAssertEqual((NSUInteger)1, decl.parameters.count, @"Expected one parameter");
    XCTAssertEqualObjects(@(UIControlStateSelected|UIControlStateHighlighted), decl.parameters[0], @"Expected UIControlStateSelected|UIControlStateHighlighted");
}

- (void) testPropertyPrefixes {
    // Test layer prefix properties
    NSArray* values = [self getPropertyValuesWithNames:@[@"layer.cornerRadius", @"layer.borderWidth"] fromStyleClass:@"prefixes" getDeclarations:YES];
    UIView* view = [[UIView alloc] init];
    ISSUIElementDetails* details = [[InterfaCSS sharedInstance] detailsForUIElement:view];
    [(ISSPropertyDeclaration*)values[0] applyPropertyValueOnTarget:details];
    [(ISSPropertyDeclaration*)values[1] applyPropertyValueOnTarget:details];
    ISSAssertEqualFloats(view.layer.cornerRadius, 5.0f);
    ISSAssertEqualFloats(view.layer.borderWidth, 10.0f);
    
    
    // Test other valid property prefixes
    values = [self getAllPropertyValuesWithNames:@[@"contentView.alpha", @"backgroundView.alpha",
                                                         @"selectedBackgroundView.alpha", @"multipleSelectionBackgroundView.alpha", @"titleLabel.alpha",
                                                         @"textLabel.alpha", @"detailTextLabel.alpha", @"inputView.alpha", @"inputAccessoryView.alpha",
                                                   @"tableHeaderView.alpha", @"tableFooterView.alpha", @"backgroundView.alpha"] fromStyleClass:@"prefixes" getDeclarations:NO];

    XCTAssertEqual((NSUInteger)12, values.count, @"Expected 12 values");
    for(id value in values) {
        XCTAssertEqualObjects(value, @(0.42));
    }
}

- (void) testTransformPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"transform"];
    CGAffineTransform transform = [value CGAffineTransformValue];
    CGAffineTransform t1 = CGAffineTransformMakeRotation((CGFloat)M_PI * 10 / 180.0f);
    CGAffineTransform t2 = CGAffineTransformMakeScale(20,30);
    CGAffineTransform t3 = CGAffineTransformMakeTranslation(40, 50);
    CGAffineTransform expected = CGAffineTransformConcat(t1, t2);
    expected = CGAffineTransformConcat(expected, t3);
    XCTAssertTrue(CGAffineTransformEqualToTransform(transform, expected), @"Unexpected transform value");
}

- (void) testAttributedStringPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"attributedText"];
    
    NSDictionary* attrs1 = [value attributesAtIndex:0 effectiveRange:nil];
    NSDictionary* attrs2 = @{
                             NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:12],
                             NSBackgroundColorAttributeName: [UIColor blueColor],
                             NSForegroundColorAttributeName: [UIColor colorWithRed:0 green:0 blue:0 alpha:1],
                             NSBaselineOffsetAttributeName: @(10),
                             NSStrokeColorAttributeName: [UIColor yellowColor],
                             NSStrokeWidthAttributeName: @(1.0)
                             };
    
    XCTAssertEqualObjects([value string], @"text");
    XCTAssertEqualObjects(attrs1, attrs2);
}

- (void) testAttributedStringPropertyValueConsistingOfMultipleStrings {
    id value = [self getSimplePropertyValueWithName:@"attributedTitle"];
    
    NSDictionary* attrs1 = [value attributesAtIndex:0 effectiveRange:nil];
    NSDictionary* attrs1e = @{
                             NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:14],
                             NSForegroundColorAttributeName: [UIColor iss_colorWithHexString:@"ffffff"],
                             };
    
    NSDictionary* attrs2 = [value attributesAtIndex:7 effectiveRange:nil];
    NSDictionary* attrs2e = @{
                             NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Medium" size:15],
                             NSForegroundColorAttributeName: [UIColor iss_colorWithHexString:@"000000"],
                             NSUnderlineStyleAttributeName: @(NSUnderlineStyleSingle | NSUnderlinePatternDash)
                             };
    
    XCTAssertEqualObjects([value string], @"title1 title2");
    XCTAssertEqualObjects(attrs1, attrs1e);
    XCTAssertEqualObjects(attrs2, attrs2e);
}

- (void) testEnumPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"contentMode"];
    XCTAssertEqual(UIViewContentModeBottomRight, [value integerValue], @"Unexpected contentMode value");
}

- (void) testEnumBitMaskPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"autoresizingMask"];
    UIViewAutoresizing autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    XCTAssertEqual(autoresizingMask, [value unsignedIntegerValue], @"Unexpected autoresizingMask value");
}

- (void) testFontPropertyValues {
    id value = [[self getPropertyValuesWithNames:@[@"font"] fromStyleClass:@"font1"] firstObject];
    XCTAssertEqualObjects(value, [UIFont fontWithName:@"HelveticaNeue-Medium" size:14], @"Unexpected font value");
    
    value = [[self getPropertyValuesWithNames:@[@"font"] fromStyleClass:@"font2"] firstObject];
    XCTAssertEqualObjects(value, [UIFont fontWithName:@"HelveticaNeue-Medium" size:15], @"Font function 'bigger' not applied correctly");
    
    value = [[self getPropertyValuesWithNames:@[@"font"] fromStyleClass:@"font3"] firstObject];
    XCTAssertEqualObjects(value, [UIFont fontWithName:@"HelveticaNeue-Medium" size:13], @"Font function 'smaller' not applied correctly");
    
    value = [[self getPropertyValuesWithNames:@[@"font"] fromStyleClass:@"font4"] firstObject];
    XCTAssertEqualObjects(value, [UIFont fontWithName:@"HelveticaNeue-Medium" size:10], @"Font function 'fontWithSize' not applied correctly");

    value = [[self getPropertyValuesWithNames:@[@"font"] fromStyleClass:@"font5"] firstObject];
    XCTAssertEqualObjects(value, [UIFont fontWithName:@"HelveticaNeue-Medium" size:5], @"Unexpected font value");

    value = [[self getPropertyValuesWithNames:@[@"font"] fromStyleClass:@"font6"] firstObject];
    XCTAssertEqualObjects(value, [UIFont fontWithName:@"Times New Roman" size:5], @"Unexpected font value");

    value = [[self getPropertyValuesWithNames:@[@"font"] fromStyleClass:@"font7"] firstObject];
    XCTAssertEqualObjects(value, [UIFont fontWithName:@"Times New Roman" size:5], @"Unexpected font value");
}

- (void) testImagePropertyValue {
    NSArray* values = [self getPropertyValuesWithNames:@[@"image", @"backgroundImage", @"shadowImage", @"progressImage", @"trackImage", @"highlightedImage", @"onImage", @"offImage"] fromStyleClass:@"image1"];
    
    UIImage* img = [(id)parser imageNamed:@"image.png"];
    UIColor* imgColor = [self colorOfFirstPixel:img];
    
    for (id value in values) {
        XCTAssertTrue([value isKindOfClass:UIImage.class], @"Expected image");
        UIColor* actual = [self colorOfFirstPixel:value];
        XCTAssertEqualObjects(imgColor, actual, @"Unexpected color value for image");
    }
}

- (void) testImageFromColorFunctionPropertyValue {
    NSArray* values = [self getPropertyValuesWithNames:@[@"image", @"backgroundImage"] fromStyleClass:@"imageColorFunctions"];

    UIColor* sourceColor = [UIColor iss_colorWithHexString:@"112233"];
    
    UIColor* actual = [self colorOfFirstPixel:values[0]];
    UIColor* expected = [sourceColor iss_colorByIncreasingBrightnessBy:50.0f];
    XCTAssertTrue([self compareColorWithTolerance:actual color2:expected], @"Unexpected color value for image");
    actual = [self colorOfFirstPixel:values[1]];
    expected = [[sourceColor iss_colorByIncreasingAlphaBy:-50.0f] iss_colorByIncreasingSaturationBy:50.0f];
    XCTAssertTrue([self compareColorWithTolerance:actual color2:expected], @"Unexpected color value for image");
}

- (void) testFullEnumNames {
    NSArray* values = [self getPropertyValuesWithNames:@[@"autoresizingMask", @"lineBreakMode", @"titleColor"] fromStyleClass:@"fullEnumNames" getDeclarations:YES];
    XCTAssertEqual(values.count, 3u, @"Unexpected value count");

    [values[0] transformValueIfNeeded];
    XCTAssertEqualObjects([values[0] propertyValue], @(UIViewAutoresizingFlexibleWidth), @"Unexpected propety value");
    [values[1] transformValueIfNeeded];
    XCTAssertEqualObjects([values[1] propertyValue], @(NSLineBreakByWordWrapping), @"Unexpected propety value");
    XCTAssertEqualObjects(((NSArray*)[values[2] parameters])[0], @(UIControlStateSelected), @"Unexpected propety value");
}

- (void) testNumericExpressions {
    NSArray* values = [self getPropertyValuesWithNames:@[@"hidden", @"alpha", @"cornerRadius", @"contentSize"] fromStyleClass:@"numericExpressions" getDeclarations:YES];
    
    [values[0] transformValueIfNeeded];
    XCTAssertEqualObjects([values[0] propertyValue], @(YES));
    
    [values[1] transformValueIfNeeded];
    XCTAssertEqualObjects([values[1] propertyValue], @(0.5));
    
    [values[2] transformValueIfNeeded];
    XCTAssertEqualObjects([values[2] propertyValue], @(142));
    
    [values[3] transformValueIfNeeded];
    CGSize size = [[values[3] propertyValue] CGSizeValue];
    XCTAssertTrue(CGSizeEqualToSize(size, CGSizeMake(42, 100)));
}

- (void) testISSLayoutParentRelative {
    ISSLayout* parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutParentRelative1"] firstObject];

    ISSLayout* layout = [[ISSLayout alloc] init];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue constantValue:100] forTargetAttribute:ISSLayoutAttributeWidth];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue constantValue:100] forTargetAttribute:ISSLayoutAttributeHeight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttributeInParent:ISSLayoutAttributeCenterX multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeCenterX];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttributeInParent:ISSLayoutAttributeCenterY multiplier:1.0f constant:-100] forTargetAttribute:ISSLayoutAttributeCenterY];
    
    XCTAssertEqualObjects(parsedLayout, layout);

    parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutParentRelative2"] firstObject];
    
    layout = [[ISSLayout alloc] init];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttributeInParent:ISSLayoutAttributeWidth multiplier:2.0f constant:0] forTargetAttribute:ISSLayoutAttributeWidth];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttributeInParent:ISSLayoutAttributeHeight multiplier:1.0f constant:100] forTargetAttribute:ISSLayoutAttributeHeight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue constantValue:100] forTargetAttribute:ISSLayoutAttributeLeft];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue constantValue:100] forTargetAttribute:ISSLayoutAttributeTop];
    
    XCTAssertEqualObjects(parsedLayout, layout);
}

- (void) testISSLayoutElementRelative {
    ISSLayout* parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutElementRelative1"] firstObject];
    
    ISSLayout* layout = [[ISSLayout alloc] init];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue constantValue:100] forTargetAttribute:ISSLayoutAttributeWidth];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue constantValue:100] forTargetAttribute:ISSLayoutAttributeHeight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeLeft inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeRight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeTop inElement:@"elementFoo" multiplier:1.0f constant:-100] forTargetAttribute:ISSLayoutAttributeBottom];
    
    XCTAssertEqualObjects(parsedLayout, layout);
    
    parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutElementRelative2"] firstObject];
    
    layout = [[ISSLayout alloc] init];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeWidth inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeWidth];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeHeight inElement:@"elementFoo" multiplier:2.0f constant:100] forTargetAttribute:ISSLayoutAttributeHeight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeRight inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeLeft];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeBottom inElement:@"elementFoo" multiplier:1.0f constant:-100] forTargetAttribute:ISSLayoutAttributeTop];
    
    XCTAssertEqualObjects(parsedLayout, layout);
}

- (void) testISSLayoutSizeToFit {
    ISSLayout* parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutParentSizeToFit1"] firstObject];
    
    ISSLayout* layout = [[ISSLayout alloc] init];
    layout.layoutType = ISSLayoutTypeSizeToFit;
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue constantValue:100] forTargetAttribute:ISSLayoutAttributeWidth];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue constantValue:100] forTargetAttribute:ISSLayoutAttributeHeight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttributeInParent:ISSLayoutAttributeRight multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeLeft];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttributeInParent:ISSLayoutAttributeBottom multiplier:1.0f constant:100] forTargetAttribute:ISSLayoutAttributeTop];
    
    XCTAssertEqualObjects(parsedLayout, layout);
    
    parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutParentSizeToFit2"] firstObject];
    
    layout = [[ISSLayout alloc] init];
    layout.layoutType = ISSLayoutTypeSizeToFit;
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttributeInParent:ISSLayoutAttributeWidth multiplier:2.0f constant:0] forTargetAttribute:ISSLayoutAttributeWidth];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttributeInParent:ISSLayoutAttributeHeight multiplier:2.0f constant:100] forTargetAttribute:ISSLayoutAttributeHeight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttributeInParent:ISSLayoutAttributeLeft multiplier:3.0f constant:0] forTargetAttribute:ISSLayoutAttributeRight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToLayoutGuide:ISSLayoutGuideBottom multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeBottom];
    
    XCTAssertEqualObjects(parsedLayout, layout);
}

- (void) testISSLayoutImplicitAttributes {
    ISSLayout* parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutImplicitAttributes1"] firstObject];
    
    ISSLayout* layout = [[ISSLayout alloc] init];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeWidth inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeWidth];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeHeight inElement:@"elementFoo" multiplier:2.0f constant:100] forTargetAttribute:ISSLayoutAttributeHeight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeCenterX inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeCenterX];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeCenterY inElement:@"elementFoo" multiplier:1.0f constant:-100] forTargetAttribute:ISSLayoutAttributeCenterY];
    
    XCTAssertEqualObjects(parsedLayout, layout);
    
    parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutImplicitAttributes2"] firstObject];
    [layout removeValuesForLayoutAttributes:@[@(ISSLayoutAttributeCenterX), @(ISSLayoutAttributeCenterY)]];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeRight inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeLeft];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeBottom inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeTop];
    
    XCTAssertEqualObjects(parsedLayout, layout);
    
    parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutImplicitAttributes3"] firstObject];
    [layout removeValuesForLayoutAttributes:@[@(ISSLayoutAttributeLeft), @(ISSLayoutAttributeTop)]];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeLeft inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeRight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeBottom inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeTop];
    
    XCTAssertEqualObjects(parsedLayout, layout);
    
    parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutImplicitAttributes4"] firstObject];
    [layout removeValuesForLayoutAttributes:@[@(ISSLayoutAttributeRight), @(ISSLayoutAttributeTop)]];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeRight inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeLeft];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeTop inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeBottom];
    
    XCTAssertEqualObjects(parsedLayout, layout);
    
    parsedLayout = [[self getPropertyValuesWithNames:@[@"layout"] fromStyleClass:@"layoutImplicitAttributes5"] firstObject];
    [layout removeValuesForLayoutAttributes:@[@(ISSLayoutAttributeLeft), @(ISSLayoutAttributeBottom)]];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeLeft inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeRight];
    [layout setLayoutAttributeValue:[ISSLayoutAttributeValue valueRelativeToAttribute:ISSLayoutAttributeTop inElement:@"elementFoo" multiplier:1.0f constant:0] forTargetAttribute:ISSLayoutAttributeBottom];
    
    XCTAssertEqualObjects(parsedLayout, layout);
}

- (void) testNestedVariable {
    id value = [[self getPropertyValuesWithNames:@[@"font"] fromStyleClass:@"nestedVariableClass"] firstObject];
    XCTAssertEqualObjects(value, [UIFont fontWithName:@"GillSans" size:42]);
}

/*- (void) testParsingPerformance {
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:@"interfaCSSTests" ofType:@"css"];
    NSString* styleSheetData = [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];
    NSMutableString* mergedStylesheets = [NSMutableString string];
    for(int i=0; i<10; i++) {
        [mergedStylesheets appendString:styleSheetData];
    }
    
    [self measureBlock:^{
        [parser parse:mergedStylesheets];
    }];
}*/

@end
