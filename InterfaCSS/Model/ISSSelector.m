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
#import "ISSPropertyDefinition.h"
#import "NSString+ISSStringAdditions.h"

@implementation ISSSelector

#pragma mark - Utility methods

- (BOOL) isEqual:(NSString*)string1 string2:(NSString*)string2 {
    if (string1 == string2) return YES;
    else return [string1 isEqualToString:string2];
}


#pragma mark - ISSelector interface

- (id) initWithType:(NSString*)type class:(NSString*)styleClass {
    self = [super init];
    if (self) {
        _type = type;
        _styleClass = styleClass;
    }
    return self;
}

- (id) copyWithZone:(NSZone*)zone {
    return [[self.class allocWithZone:zone] initWithType:self.type class:self.styleClass];
}

- (BOOL) matchesComponent:(id)component {
    BOOL typeMatch = !self.type || [self.type isEqualToString:@"*"];
    
    if( !typeMatch ) {
        NSString* componentType = [ISSPropertyDefinition typeForViewClass:[component class]];
        typeMatch = [componentType isEqualIgnoreCase:self.type];
        if( !typeMatch ) { // Remove leading "ui"
            componentType = [componentType stringByReplacingCharactersInRange:NSMakeRange(0, 2) withString:@""];
            typeMatch = [componentType isEqualIgnoreCase:self.type];
        }
    }
    
    // TYPE
    if( typeMatch ) {
        // STYLE CLASS
        if( !self.styleClass ) return YES;
        else {
            NSSet* styleClasses = [[InterfaCSS interfaCSS] styleClassesForUIObject:component];
            for(NSString* componentClass in styleClasses) {
                if ( [componentClass compare:self.styleClass options:NSCaseInsensitiveSearch] == NSOrderedSame ) return YES;
            }
        }
    }
    return NO;
}

- (NSString*) displayDescription {
    if ( _type && _styleClass ) return [NSString stringWithFormat:@"%@.%@", _type, _styleClass];
    else if ( _type ) return [NSString stringWithFormat:@"%@", _type];
    else return [NSString stringWithFormat:@".%@", _styleClass];
}


#pragma mark - NSObject overrides

- (NSString*) description {
    return [NSString stringWithFormat:@"Selector(%@)", self.displayDescription];
}

- (BOOL) isEqual:(id)object {
    if ( [object isKindOfClass:[ISSSelector class]] ) {
        ISSSelector* other = (ISSSelector*)object;
        return [self isEqual:self.type string2:other.type] && [self isEqual:self.styleClass string2:other.styleClass];
    } else return NO;
}

- (NSUInteger) hash {
    return 31 * [self.type hash] + [self.styleClass hash];
}

@end