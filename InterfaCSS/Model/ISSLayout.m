//
// Created by Tobias Löfstrand on 2015-01-24.
// Copyright (c) 2015 Leafnode AB. All rights reserved.
//

#import "ISSLayout.h"

#import "ISSUIElementDetails.h"


NSString* const ISSLayoutAttributeRelationParent = @"ISSLayoutAttributeRelationParent";
NSString* const ISSLayoutAttributeRelationLayoutGuide = @"ISSLayoutAttributeRelationLayoutGuide";

NSInteger const ISSLayoutAttributeXAxisMask = 0x10;           // 0001 0000
NSInteger const ISSLayoutAttributeYAxisMask = 0x20;           // 0010 0000
NSInteger const ISSLayoutAttributeMarginMask = 0x40;          // 0100 0000


static NSDictionary* stringToAttribute;
static NSDictionary* stringToLayoutGuide;


/**
 * ISSLayoutAttributeValue
 */
@interface ISSLayoutAttributeValue ()
@property (nonatomic, readwrite) ISSLayoutAttribute targetAttribute;
@end

@implementation ISSLayoutAttributeValue

+ (ISSLayoutAttributeValue*) constantValue:(CGFloat)constant {
    return [[self alloc] initWithElementId:nil attribute:ISSLayoutAttributeDefault multiplier:0 constant:constant];
}

+ (ISSLayoutAttributeValue*) valueRelativeToAttributeInParent:(ISSLayoutAttribute)attribute multiplier:(CGFloat)multiplier constant:(CGFloat)constant {
    return [[self alloc] initWithElementId:ISSLayoutAttributeRelationParent attribute:attribute multiplier:multiplier constant:constant];
}

+ (ISSLayoutAttributeValue*) valueRelativeToAttribute:(ISSLayoutAttribute)attribute inElement:(NSString*)elementId multiplier:(CGFloat)multiplier constant:(CGFloat)constant {
    return [[self alloc] initWithElementId:elementId attribute:attribute multiplier:multiplier constant:constant];
}

+ (ISSLayoutAttributeValue*) valueRelativeToLayoutGuide:(ISSLayoutGuide)guide multiplier:(CGFloat)multiplier constant:(CGFloat)constant {
    // Note: Using a ISSLayoutGuide value as a ISSLayoutAttribute parameter works since all ISSLayoutGuide values translate to proper ISSLayoutAttribute values (with the corresponding meaning)
    return [[self alloc] initWithElementId:ISSLayoutAttributeRelationLayoutGuide attribute:(ISSLayoutAttribute)guide multiplier:multiplier constant:constant];
}

- (instancetype) initWithElementId:(NSString*)elementId attribute:(ISSLayoutAttribute)attribute multiplier:(CGFloat)multiplier constant:(CGFloat)constant {
    if ( self = [super init] ) {
        _relativeElementId = elementId;
        _relativeAttribute = attribute;
        _multiplier = multiplier;
        _constant = constant;
    }
    return self;
}

- (BOOL) isConstantValue {
    return self.relativeElementId == nil;
}

- (BOOL) isParentRelativeValue {
    return self.relativeElementId == ISSLayoutAttributeRelationParent;
}

- (BOOL) isLayoutGuideValue {
    return self.relativeElementId == ISSLayoutAttributeRelationLayoutGuide;
}

- (BOOL) isRelativeToLayoutMargin {
    return (self.relativeAttribute & ISSLayoutAttributeMarginMask);
}

- (CGFloat) resolveForElement:(UIView*)element withRelativeElement:(ISSUIElementDetails*)relativeElementDetails layoutGuideInsets:(UIEdgeInsets)layoutGuideInsets didResolve:(BOOL*)didResolve {
    UIView* parentView = element.superview;
    CGRect rect = parentView.bounds;
    UIView* relativeElement = relativeElementDetails.view;
    if( self.isParentRelativeValue ) relativeElement = parentView;
    UIWindow* window = element.window;
    if( !window ) window = [UIApplication sharedApplication].keyWindow;
    BOOL resolveResult = YES;
    UIEdgeInsets layoutMargins = UIEdgeInsetsZero;

    // Parent relative value:
    if( relativeElement == parentView ) {
        if( [parentView respondsToSelector:@selector(layoutMargins)] ) layoutMargins = parentView.layoutMargins;
        // Since rect is already set to parentView.bounds by default, we don't have to do anything more here with rect
    }
    // Layout guide relative value:
    else if( self.isLayoutGuideValue ) {
        rect = UIEdgeInsetsInsetRect(window.bounds, layoutGuideInsets);
        // Convert the window rect to the coordinate system of the parent view of the current element
        rect = [window convertRect:rect toView:parentView];
    }
    // Value relative to other element:
    else if( relativeElementDetails && parentView ) {
        UIView* relativeElementParent = relativeElementDetails.parentView;
        if( [relativeElement respondsToSelector:@selector(layoutMargins)] ) layoutMargins = relativeElement.layoutMargins;
        CGRect effectiveRectForRelativeElement = [relativeElement alignmentRectForFrame:relativeElement.frame]; // Use the alignment rect of the relativeElement when resolving the LayoutAttributeValue

        if( relativeElementParent == parentView ) { // When relativeElement has same parent, we can use effectiveRectForRelativeElement straight away
            rect = effectiveRectForRelativeElement;
        } else if( relativeElementParent ) { // Convert the frame of the relative element to the coordinate system of the parent view
            rect = [relativeElementParent convertRect:[relativeElement alignmentRectForFrame:relativeElement.frame] toView:parentView];
        } else { // Or if no parent - use the window
            rect = [window convertRect:[relativeElement alignmentRectForFrame:relativeElement.frame] toView:parentView];
        }
    }
    // Constant value or invalid value:
    else {
        resolveResult = self.isConstantValue;
    }

    *didResolve = resolveResult;

    if( self.isRelativeToLayoutMargin ) {
        rect = UIEdgeInsetsInsetRect(rect, layoutMargins);
    }
    return [self resolveWithRect:rect];
}

- (CGFloat) resolveWithRect:(CGRect)rect {
    CGFloat value = 0;

    ISSLayoutAttribute targetAttribute = self.targetAttribute;
    ISSLayoutAttribute effectiveRelativeAttribute = self.relativeAttribute;
    // Resolve relativeAttribute with default value to appropriate value based on targetAttribute:
    if( effectiveRelativeAttribute == ISSLayoutAttributeDefault ) {
        if( self.isParentRelativeValue ) {
            effectiveRelativeAttribute = targetAttribute; // If relative to parent, use same attribute as targetAttribute when resolving relation
        } else {
            // Use opposite attribute as default when resolving relation to other elements than parent:
            if( targetAttribute == ISSLayoutAttributeTop ) effectiveRelativeAttribute = ISSLayoutAttributeBottom;
            else if( targetAttribute == ISSLayoutAttributeLeft ) effectiveRelativeAttribute = ISSLayoutAttributeRight;
            else if( targetAttribute == ISSLayoutAttributeBottom ) effectiveRelativeAttribute = ISSLayoutAttributeTop;
            else if( targetAttribute == ISSLayoutAttributeRight ) effectiveRelativeAttribute = ISSLayoutAttributeLeft;
            else effectiveRelativeAttribute = targetAttribute;
        }
    }

    switch( effectiveRelativeAttribute ) {
        case ISSLayoutAttributeWidth: {
            value = rect.size.width; break;
        }
        case ISSLayoutAttributeHeight: {
            value = rect.size.height; break;
        }
        case ISSLayoutAttributeTop:
        case ISSLayoutAttributeTopMargin: {
            value = rect.origin.y; break;
        }
        case ISSLayoutAttributeLeft:
        case ISSLayoutAttributeLeftMargin:
        {
            value = rect.origin.x; break;
        }
        case ISSLayoutAttributeBottom:
        case ISSLayoutAttributeBottomMargin: {
            value = rect.origin.y + rect.size.height; break;
        }
        case ISSLayoutAttributeRight:
        case ISSLayoutAttributeRightMargin: {
            value = rect.origin.x + rect.size.width; break;
        }
        case ISSLayoutAttributeCenterX: {
            value = rect.origin.x + rect.size.width / 2; break;
        }
        case ISSLayoutAttributeCenterY: {
            value = rect.origin.y + rect.size.height / 2; break;
        }
        case ISSLayoutAttributeDefault: break;
    }

    return value * self.multiplier + self.constant;
}


#pragma mark - NSObject overrides

- (NSString*) description {
    NSString* constantString = @"";
    if( self.constant != 0 ) {
        if( self.constant > 0 ) constantString = [NSString stringWithFormat:@" + %.2f", self.constant];
        constantString = [NSString stringWithFormat:@" - %.2f", fabs(self.constant)];
    }
    NSString* multiplierString = @"";
    if( self.multiplier != 1 ) {
        multiplierString = [NSString stringWithFormat:@" * %.2f", self.constant];
    }
    
    if( self.isConstantValue ) {
        return [NSString stringWithFormat:@"LayoutAttributeValue( %@ = %.2f )", [ISSLayout attributeToString:self.targetAttribute], self.constant];
    } else if( self.isParentRelativeValue ) {
        return [NSString stringWithFormat:@"LayoutAttributeValue( %@ = parent.%@%@%@ )", [ISSLayout attributeToString:self.targetAttribute], [ISSLayout attributeToString:self.relativeAttribute], multiplierString, constantString];
    } else if( self.isLayoutGuideValue ) {
        return [NSString stringWithFormat:@"LayoutAttributeValue( %@ = guide.%@%@%@ )", [ISSLayout attributeToString:self.targetAttribute], [ISSLayout attributeToString:self.relativeAttribute], multiplierString, constantString];
    } else {
        return [NSString stringWithFormat:@"LayoutAttributeValue( %@ = %@.%@%@%@ )", [ISSLayout attributeToString:self.targetAttribute], self.relativeElementId, [ISSLayout attributeToString:self.relativeAttribute], multiplierString, constantString];
    }
}

@end


/**
 * ISSLayout
 */
@interface ISSLayout ()
@property (nonatomic, strong) NSMutableDictionary* attributes;
@property (nonatomic) BOOL autoWidth; // Set to YES by default, set to NO when constraint is added
@property (nonatomic) BOOL autoHeight; // Set to YES by default, set to NO when constraint is added
@end

@implementation ISSLayout

#pragma mark - Lifecycle

+ (void) initialize {
    stringToAttribute = @{
            @"default" : @(ISSLayoutAttributeDefault),
            @"width" : @(ISSLayoutAttributeWidth),
            @"height": @(ISSLayoutAttributeHeight),
            @"top" : @(ISSLayoutAttributeTop),
            @"topmargin" : @(ISSLayoutAttributeTopMargin),
            @"left" : @(ISSLayoutAttributeLeft),
            @"leftmargin" : @(ISSLayoutAttributeLeftMargin),
            @"bottom" : @(ISSLayoutAttributeBottom),
            @"bottommargin" : @(ISSLayoutAttributeBottomMargin),
            @"right" : @(ISSLayoutAttributeRight),
            @"rightmargin" : @(ISSLayoutAttributeRightMargin),
            @"centerx" : @(ISSLayoutAttributeCenterX),
            @"centery" : @(ISSLayoutAttributeCenterY)
    };
    stringToLayoutGuide =@ {
            @"top" : @(ISSLayoutGuideTop),
            @"bottom" : @(ISSLayoutGuideBottom),
            @"center" : @(ISSLayoutGuideCenter)
    };
}

- (instancetype) init {
    if ( self = [super init] ) {
        _layoutType = ISSLayoutTypeStandard;
        _attributes = [[NSMutableDictionary alloc] init];
        _autoWidth = YES;
        _autoHeight = YES;
    }
    return self;
}


#pragma mark - Frame and attribute value resolving

- (CGFloat) resolveValueForView:(UIView*)view targetLayoutAttribute:(ISSLayoutAttribute)attribute elementMappings:(NSDictionary*)elementMappings layoutGuideInsets:(UIEdgeInsets)layoutGuideInsets didResolve:(BOOL*)didResolve {
    ISSLayoutAttributeValue* attributeValue = self.attributes[@(attribute)];
    ISSUIElementDetails* relativeElementDetails = attributeValue.relativeElementId ? elementMappings[attributeValue.relativeElementId] : nil;

    return [attributeValue resolveForElement:view withRelativeElement:relativeElementDetails layoutGuideInsets:layoutGuideInsets didResolve:didResolve];
}

- (void) applyValue:(CGFloat)value toRect:(CGRect*)rect forView:(UIView*)view autoWidth:(BOOL)autoWidth autoHeight:(BOOL)autoHeight forLayoutAttribute:(ISSLayoutAttribute)attribute {
    switch(attribute) {
        case ISSLayoutAttributeTop:
        case ISSLayoutAttributeTopMargin: {
            if( attribute == ISSLayoutAttributeTop ) rect->origin.y = value;
            else rect->origin.y = value - view.layoutMargins.top; // Offset with margin
            if( autoHeight ) rect->size.height -= value;
            break;
        }
        case ISSLayoutAttributeLeft:
        case ISSLayoutAttributeLeftMargin: {
            if( attribute == ISSLayoutAttributeLeft ) rect->origin.x = value;
            else rect->origin.x = value - view.layoutMargins.left; // Offset with margin
            if( autoWidth ) rect->size.width -= value;
            break;
        }
        case ISSLayoutAttributeBottom:
        case ISSLayoutAttributeBottomMargin: {
            if( attribute == ISSLayoutAttributeBottom ) rect->origin.y = value - rect->size.height;
            else rect->origin.y = value - rect->size.height + view.layoutMargins.bottom; // Offset with margin
            if( autoHeight ) rect->size.height -= value;
            break;
        }
        case ISSLayoutAttributeRight:
        case ISSLayoutAttributeRightMargin: {
            if( attribute == ISSLayoutAttributeRight ) rect->origin.x = value - rect->size.width;
            else rect->origin.x = value - rect->size.width + view.layoutMargins.right; // Offset with margin
            if( autoWidth ) rect->size.width -= value;
            break;
        }
        case ISSLayoutAttributeCenterX: {
            rect->origin.x = value - rect->size.width / 2;
            break;
        }
        case ISSLayoutAttributeCenterY: {
            rect->origin.y = value - rect->size.height / 2;
            break;
        }
        default: break;
    }
}

- (BOOL) resolveRectForView:(UIView*)view withResolvedElements:(NSDictionary*)elementMappings andLayoutGuideInsets:(UIEdgeInsets)layoutGuideInsets {
    BOOL didResolve = YES;

    CGRect resolvedRect = CGRectMake(0, 0, view.superview.bounds.size.width, view.superview.bounds.size.height);
    CGSize intrinsicSize = view.intrinsicContentSize;

    // Resolve width and height first
    BOOL usingAutoWidth = self.autoWidth;
    BOOL usingAutoHeight = self.autoHeight;
    if( self.autoWidth ) {
        if( intrinsicSize.width != UIViewNoIntrinsicMetric ) { // If no width layout value has been specified, but an intrinsic content width is available - use that
            resolvedRect.size.width = intrinsicSize.width;
            usingAutoWidth = NO;
        }
    } else {
        resolvedRect.size.width = [self resolveValueForView:view targetLayoutAttribute:ISSLayoutAttributeWidth elementMappings:elementMappings layoutGuideInsets:layoutGuideInsets didResolve:&didResolve];
        if( !didResolve ) return NO;
    }
    if( self.autoHeight ) {
        if( intrinsicSize.height != UIViewNoIntrinsicMetric ) { // If no height layout value has been specified, but an intrinsic content height is available - use that
            resolvedRect.size.height = intrinsicSize.height;
            usingAutoHeight = NO;
        }
    } else {
        resolvedRect.size.height = [self resolveValueForView:view targetLayoutAttribute:ISSLayoutAttributeHeight elementMappings:elementMappings layoutGuideInsets:layoutGuideInsets didResolve:&didResolve];
        if( !didResolve ) return NO;
    }

    // If sizeToFit mode - get the desired size for the view, using width & height as max values
    BOOL isSizeToFit = self.layoutType == ISSLayoutTypeSizeToFit;
    if( isSizeToFit ) {
        CGSize size = [view sizeThatFits:CGSizeMake(resolvedRect.size.width, resolvedRect.size.height)];
        if( size.width < resolvedRect.size.width ) resolvedRect.size.width = size.width;
        if( size.height < resolvedRect.size.height ) resolvedRect.size.height = size.height;
    }
    
    // Resolve layout attributes
    for(NSNumber* attributeKey in self.attributes.allKeys) {
        ISSLayoutAttribute attribute = (ISSLayoutAttribute)attributeKey.integerValue;
        CGFloat value = [self resolveValueForView:view targetLayoutAttribute:attribute elementMappings:elementMappings layoutGuideInsets:layoutGuideInsets didResolve:&didResolve];
        if( !didResolve ) return NO;

        [self applyValue:value toRect:&resolvedRect forView:view autoWidth:usingAutoWidth autoHeight:usingAutoHeight forLayoutAttribute:attribute];
    }

    // Update frame
    CATransform3D t3d = view.layer.transform;
    CGAffineTransform t = view.transform;
    view.transform = CGAffineTransformIdentity;
    view.layer.transform = CATransform3DIdentity;
    if( !CGRectEqualToRect(resolvedRect, view.frame) ) { // Don't touch frame if it hasn't changed
        view.frame = resolvedRect;
    }
    view.transform = t;
    view.layer.transform = t3d;

    return YES;
}


#pragma mark - Attributes

+ (NSArray*) attributeNames {
    return [stringToAttribute allKeys];
}

+ (NSString*) attributeToString:(ISSLayoutAttribute)attribute {
    __block NSString* attributeName = nil;
    [stringToAttribute enumerateKeysAndObjectsUsingBlock:^(NSString* key, NSNumber* value, BOOL *stop) {
        if( [value integerValue] == attribute ) {
            attributeName = key;
            *stop = YES;
        }
    }];
    return attributeName;
}

+ (ISSLayoutAttribute) attributeFromString:(NSString*)string {
    NSNumber* b = string ? stringToAttribute[string.lowercaseString] : nil;
    if( b ) return (ISSLayoutAttribute)b.integerValue;
    else return ISSLayoutAttributeDefault;
}

+ (ISSLayoutGuide) layoutGuideFromString:(NSString*)string {
    NSNumber* b = string ? stringToLayoutGuide[string.lowercaseString] : nil;
    if( b ) return (ISSLayoutGuide)b.integerValue;
    else return ISSLayoutGuideTop;
}

- (void) addLayoutAttributeValue:(ISSLayoutAttributeValue*)attributeValue {
    NSAssert(attributeValue.targetAttribute != ISSLayoutAttributeDefault, @"ISSLayoutAttributeDefault cannot be used as parameter to %@", NSStringFromSelector(_cmd));

    if( attributeValue.targetAttribute == ISSLayoutAttributeWidth ) self.autoWidth = NO;
    else if( attributeValue.targetAttribute == ISSLayoutAttributeHeight ) self.autoHeight = NO;

    self.attributes[@(attributeValue.targetAttribute)] = attributeValue;
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"Layout%@", self.attributes.allValues];
}

@end
