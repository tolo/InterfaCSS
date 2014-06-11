//
//  ISSSelector.m
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2012-02-22.
//  Copyright (c) 2012 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import "ISSSelector.h"

#import "InterfaCSS.h"
#import "NSString+ISSStringAdditions.h"
#import "NSObject+ISSLogSupport.h"
#import "ISSPseudoClass.h"
#import "ISSUIElementDetails.h"

@implementation ISSSelector {
    BOOL _wildcardType;
}

#pragma mark - ISSelector interface

- (instancetype) initWithType:(Class)type wildcardType:(BOOL)wildcardType class:(NSString*)styleClass pseudoClass:(ISSPseudoClass*)pseudoClass {
    self = [super init];
    if (self) {
        _wildcardType = wildcardType;
        _type = type;
        _styleClass = [styleClass lowercaseString];
        _pseudoClass = pseudoClass;
    }
    return self;
}

+ (instancetype) selectorWithType:(NSString*)type class:(NSString*)styleClass pseudoClass:(ISSPseudoClass*)pseudoClass {
    Class typeClass = nil;
    BOOL wildcardType = NO;

    if( [type iss_hasData] ) {
        if( [type isEqualToString:@"*"] ) wildcardType = YES;
        else {
            type = [type lowercaseString];
            if( ![type hasPrefix:@"ui"] ) type = [@"ui" stringByAppendingString:type];
            typeClass = [ISSPropertyDefinition canonicalTypeClassForType:type];
        }
    }

    if( typeClass || wildcardType || styleClass ) {
        return [[self alloc] initWithType:typeClass wildcardType:wildcardType class:styleClass pseudoClass:pseudoClass];
    } else if( [type iss_hasData] ) {
        if( [InterfaCSS interfaCSS].useLenientSelectorParsing ) {
            ISSLogWarning(@"Unrecognized type: %@ - using type as style class instead", type);
            return [[self alloc] initWithType:nil wildcardType:NO class:type pseudoClass:pseudoClass];
        } else {
            ISSLogWarning(@"Unrecognized type: %@", type);
        }
    }  else {
        ISSLogWarning(@"Invalid selector - type and style class missing!");
    }
    return nil;
}

- (instancetype) copyWithZone:(NSZone*)zone {
    return [[self.class allocWithZone:zone] initWithType:_type wildcardType:_wildcardType class:self.styleClass pseudoClass:self.pseudoClass];
}

- (BOOL) matchesElement:(ISSUIElementDetails*)elementDetails {
    // TYPE
    BOOL match = !self.type || _wildcardType;
    if( !match ) {
        match = elementDetails.canonicalType == self.type;
    }

    // STYLE CLASS
    if( match && self.styleClass ) {
        match = [elementDetails.styleClasses containsObject:self.styleClass];
    }

    // PSEUDO CLASS
    if( match && self.pseudoClass ) {
        match = [self.pseudoClass matchesElement:elementDetails];
    }

    return match;
}

- (NSString*) displayDescription {
    NSString* pseudoClassSuffix = @"";
    NSString* typeString = _type ? [ISSPropertyDefinition canonicalTypeForViewClass:_type] : nil;
    if( !_type && _wildcardType ) typeString = @"*";
    
    if( self.pseudoClass ) pseudoClassSuffix = [NSString stringWithFormat:@":%@", self.pseudoClass.displayDescription];
    if ( typeString && _styleClass ) return [NSString stringWithFormat:@"%@.%@%@", typeString, _styleClass, pseudoClassSuffix];
    else if ( typeString ) return [NSString stringWithFormat:@"%@%@", typeString, pseudoClassSuffix];
    else return [NSString stringWithFormat:@".%@%@", _styleClass, pseudoClassSuffix];
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
            [NSString iss_string:self.styleClass isEqualToString:other.styleClass] &&
            self.pseudoClass == other.pseudoClass ? YES : [self.pseudoClass isEqual:other.pseudoClass];
    } else return NO;
}

- (NSUInteger) hash {
    return 31u*31u * [self.type hash] + 31*[self.styleClass hash] + [self.pseudoClass hash] + (_wildcardType ? 1 : 0);
}

@end