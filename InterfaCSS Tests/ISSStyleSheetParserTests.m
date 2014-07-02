//
//  ISSStyleSheetParserTests.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-16.
//  Copyright (c) 2014 Leafnode AB.
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
#import "ISSParcoaStyleSheetParser.h"

@interface ISSParcoaStyleSheetTestParser : ISSParcoaStyleSheetParser
@end
@implementation ISSParcoaStyleSheetTestParser

- (UIImage*) imageNamed:(NSString*)name {
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:name ofType:nil];
    return [UIImage imageWithContentsOfFile:path];
}

@end

@interface ISSStyleSheetParserTests : XCTestCase

@end


@implementation ISSStyleSheetParserTests {
    id<ISSStyleSheetParser> parser;
}

+ (void) setUp {
    [super setUp];
    //NSLog(@"%@", [ISSPropertyDefinition propertyDescriptionsForMarkdown]);
}

- (void) setUp {
    [super setUp];

    parser = [[ISSParcoaStyleSheetTestParser alloc] init];
}

- (void) tearDown {
    [super tearDown];
}


#pragma mark - Utils

- (NSArray*) parseStyleSheet:(NSString*)name {
    NSString* path = [[NSBundle bundleForClass:self.class] pathForResource:name ofType:@"css"];
    NSString* styleSheetData = [NSString stringWithContentsOfFile:path usedEncoding:nil error:nil];
    return [parser parse:styleSheetData];
}

- (ISSPropertyDeclarations*) getPropertyDeclarationsForStyleClass:(NSString*)styleClass inStyleSheet:(NSString*)stylesheet {
    NSArray* result = [self parseStyleSheet:stylesheet];
    
    ISSPropertyDeclarations* declarations = nil;
    for (ISSPropertyDeclarations* d in result) {
        if( [[[d.selectorChains[0] selectorComponents][0] styleClass] isEqualToString:styleClass] ) {
            declarations = d; break;
        }
    }
    return declarations;
}

- (NSArray*) getPropertyValuesWithNames:(NSArray*)names fromStyleClass:(NSString*)styleClass {
    return [self getPropertyValuesWithNames:names fromStyleClass:styleClass getDeclarations:NO];
}

- (NSArray*) getPropertyValuesWithNames:(NSArray*)names fromStyleClass:(NSString*)styleClass getDeclarations:(BOOL)getDeclarations {
    ISSPropertyDeclarations* declarations = [self getPropertyDeclarationsForStyleClass:[styleClass lowercaseString] inStyleSheet:@"styleSheetPropertyValues"];
    
    NSMutableArray* values = [NSMutableArray array];
    
    for(NSString* name in names) {
        id value = nil;
        for(ISSPropertyDeclaration* d in declarations.properties) {
            NSString* propertyName = d.property.name;
            if( d.prefix && ![d.prefix isEqualToString:@"layer"] ) {
                propertyName = [[d.prefix stringByAppendingString:@"."] stringByAppendingString:propertyName];
            }
            
            if( [propertyName iss_isEqualIgnoreCase:name] ) {
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
    NSMutableSet* expectedSelectors = [[NSMutableSet alloc] initWithArray:@[@"uilabel", @"uilabel.class1", @".class1",
                                                                            @"uiview .class1 .class2", @"uilabel, uilabel.class1, .class1, uiview .class1 .class2",
                                                                            @"uiview > .class1 + .class2 ~ .class3", @"uiview", @"uiview .classn1", @"uiview .classn1 .classn2",
                                                                            @"uiview:onlychild", @"uiview:nthchild(2n+1)", @"uiview uilabel:firstoftype", @"uiview.classx uilabel:lastoftype",
                                                                            @"* uiview", @"* uiview *", @"uiview *", @"uiview * uiview"]];
    
    for (ISSPropertyDeclarations* d in result) {
        NSMutableArray* chains = [NSMutableArray array];
        [d.selectorChains enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [chains addObject:[obj displayDescription]];
        }];
        NSString* selectorDescription = [chains componentsJoinedByString:@", "];
        
        ISSPropertyDeclaration* decl = d.properties.count ? d.properties[0] : nil;
        [decl transformValueIfNeeded];
        if( decl && [decl.propertyValue isEqual:@(0.666f)] ) {
            if( [expectedSelectors containsObject:selectorDescription] ) {
                [expectedSelectors removeObject:selectorDescription];
            } else {
                NSLog(@"Didn't find: %@", selectorDescription);
            }
        } else NSLog(@"Didn't find: %@", selectorDescription);
    }
    
    XCTAssertEqual((NSUInteger)0, expectedSelectors.count, @"Not all selectors were found");
}


#pragma mark - Tests - property values


- (void) testNumberPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"alpha"];
    XCTAssertEqualObjects(value, @YES, @"Expected value '1' for property alpha");
}

- (void) testBooleanPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"clipsToBounds"];
    XCTAssertEqualObjects(value, @YES, @"Expected value 'YES' for property clipsToBounds");
}

- (void) testStringPropertyValue {
    NSArray* values = [self getPropertyValuesWithNames:@[@"text", @"title", @"prompt"] fromStyleClass:@"simple"];
    XCTAssertEqualObjects(values[0], @"Text:", @"Expected value 'Text:' for property text");
    XCTAssertEqualObjects(values[1], @"Title", @"Expected value 'Title' for property title");
    XCTAssertEqualObjects(values[2], @"Prompt", @"Expected value 'Prompt' for property prompt");
}

- (void) testOffsetPropertyValue {
    id value = [self getSimplePropertyValueWithName:@"shadowOffset"];
    UIOffset offset = [value isKindOfClass:NSValue.class] ? [value UIOffsetValue] : UIOffsetZero;
    XCTAssertTrue(UIOffsetEqualToOffset(offset, UIOffsetMake(1, 2)), @"Expected UIOffset value of '{1, 2}' for property shadowOffset, got: %@", value);
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
    [(ISSPropertyDeclaration*)values[0] applyPropertyValueOnTarget:view];
    [(ISSPropertyDeclaration*)values[1] applyPropertyValueOnTarget:view];
    XCTAssertEqual(view.layer.cornerRadius, 5.0f);
    XCTAssertEqual(view.layer.borderWidth, 10.0f);
    
    
    // Test other valid property prefixes
    values = [self getPropertyValuesWithNames:@[@"contentView.alpha", @"backgroundView.alpha",
                                                         @"selectedBackgroundView.alpha", @"multipleSelectionBackgroundView.alpha", @"titleLabel.alpha",
                                                         @"textLabel.alpha", @"detailTextLabel.alpha", @"inputView.alpha", @"inputAccessoryView.alpha",
                                                         @"tableHeaderView.alpha", @"tableFooterView.alpha", @"backgroundView.alpha"] fromStyleClass:@"prefixes"];

    XCTAssertEqual((NSUInteger)12, values.count, @"Expected 12 values");
    for(id value in values) {
        XCTAssertEqualObjects(value, @(0.42f));
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
    NSArray* values = [self getPropertyValuesWithNames:@[@"autoresizingMask", @"titleColor"] fromStyleClass:@"fullEnumNames" getDeclarations:YES];
    XCTAssertEqual(values.count, 2u, @"Unexpected value count");
    [values[0] transformValueIfNeeded];
    XCTAssertEqualObjects([values[0] propertyValue], @(UIViewAutoresizingFlexibleWidth), @"Unexpected propety value");
    XCTAssertEqualObjects([values[1] parameters][0], @(UIControlStateSelected), @"Unexpected propety value");
}

@end
