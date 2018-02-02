//
//  ISSSelector.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSSelector.h"

#import "ISSPseudoClass.h"
#import "ISSElementStylingProxy.h"
#import "ISSStylingContext.h"

#import "NSString+ISSAdditions.h"
#import "NSObject+ISSLogSupport.h"


@implementation ISSSelector {
    BOOL _wildcardType;
}

#pragma mark - ISSelector interface

- (instancetype) initWithType:(Class)type wildcardType:(BOOL)wildcardType elementId:(NSString*)elementId styleClasses:(NSArray*)styleClasses pseudoClasses:(NSArray*)pseudoClasses {
    if (self = [super init]) {
        _wildcardType = wildcardType;
        _type = type;
        _elementId = [elementId lowercaseString];
        if( styleClasses ) {
            NSMutableArray* lcStyleClasses = [NSMutableArray array];
            for(NSString* styleClass in styleClasses) {
                [lcStyleClasses addObject:[styleClass lowercaseString]];
            }
            _styleClasses = lcStyleClasses;
        } else _styleClasses = nil;
        if( pseudoClasses.count == 0 ) pseudoClasses = nil;
        _pseudoClasses = pseudoClasses;
    }
    return self;
}

- (instancetype) initWithType:(Class)type elementId:(NSString*)elementId styleClasses:(NSArray*)styleClasses pseudoClasses:(NSArray*)pseudoClasses {
    return [self initWithType:type wildcardType:NO elementId:elementId styleClasses:styleClasses pseudoClasses:pseudoClasses];
}

- (instancetype) initWithWildcardTypeAndElementId:(NSString*)elementId styleClasses:(NSArray*)styleClasses pseudoClasses:(NSArray*)pseudoClasses {
    return [self initWithType:nil wildcardType:YES elementId:elementId styleClasses:styleClasses pseudoClasses:pseudoClasses];
}

- (instancetype) copyWithZone:(NSZone*)zone {
    return [[(id)self.class allocWithZone:zone] initWithType:_type wildcardType:_wildcardType elementId:self.elementId styleClasses:self.styleClasses pseudoClasses:self.pseudoClasses];
}

- (NSString*) styleClass {
    return [self.styleClasses firstObject];
}


- (BOOL) matchesElement:(ISSElementStylingProxy*)elementDetails stylingContext:(ISSStylingContext*)stylingContext {
    // TYPE
    BOOL match = !self.type || _wildcardType;
    if( !match ) {
        match = elementDetails.canonicalType == self.type;
    }
    
    // ELEMENT ID
    if( match && self.elementId ) {
        match = [elementDetails.elementId iss_isEqualIgnoreCase:self.elementId];
    }
    
    // STYLE CLASSES
    if( match && self.styleClasses ) {
        for(NSString* styleClass in self.styleClasses) {
            match = [elementDetails.styleClasses containsObject:styleClass];
            if( !match ) break;
        }
    }

    // PSEUDO CLASSES
    if( !stylingContext.ignorePseudoClasses && match && self.pseudoClasses.count ) {
        for(ISSPseudoClass* pseudoClass in self.pseudoClasses) {
            match = [pseudoClass matchesElement:elementDetails stylingContext:stylingContext];
            if( !match ) break;
        }
    }

    return match;
}

- (NSUInteger) specificity {
    NSUInteger specificity = 0;
    if( self.elementId ) specificity += 100;
    if( self.styleClasses.count ) specificity += 10 * self.styleClasses.count;
    if( self.pseudoClasses.count ) specificity += 10 * self.pseudoClasses.count;
    if( self.type ) specificity += 1;
    
    return specificity;
}

- (NSString*) displayDescription {
    NSString* typeString = _type ? NSStringFromClass(_type) : @"";
    if( !_type && _wildcardType ) typeString = @"*";

    NSString* idString = @"";
    if( _elementId ) {
        idString = [NSString stringWithFormat:@"#%@", _elementId];
    }

    NSString* classString = @"";
    if( self.styleClasses.count > 0 ) {
        for(NSString* styleClass in self.styleClasses) {
            classString = [classString stringByAppendingFormat:@".%@", styleClass];
        }
    }

    NSString* pseudoClassSuffix = @"";
    if( self.pseudoClasses.count > 0 ) {
        for(ISSPseudoClass* pseudoClass in self.pseudoClasses) {
            pseudoClassSuffix = [pseudoClassSuffix stringByAppendingFormat:@":%@", pseudoClass.displayDescription];
        }
    }

    return [NSString stringWithFormat:@"%@%@%@%@", typeString, idString, classString, pseudoClassSuffix];
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"Selector(%@)", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    if( object == self ) return YES;
    else if ( [object isKindOfClass:ISSSelector.class] ) {
        ISSSelector* other = (ISSSelector*)object;
        return _wildcardType == other->_wildcardType && self.type == other.type &&
            self.styleClasses == other.styleClasses ? YES : [self.styleClasses isEqual:other.styleClasses] &&
            self.pseudoClasses == other.pseudoClasses ? YES : [self.pseudoClasses isEqual:other.pseudoClasses];
    } else return NO;
}

- (NSUInteger) hash {
    return 31u*31u*31u * [self.type hash] + 31u*31u*[self.styleClasses hash] + 31*[self.elementId hash] + [self.pseudoClasses hash] + (_wildcardType ? 1 : 0);
}

@end
