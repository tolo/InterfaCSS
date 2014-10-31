//
//  ISSViewPrototype.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Created by Tobias Löfstrand on 2014-02-07.
//  Copyright (c) 2014 Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>


typedef UIView* (^ViewBuilderBlock)(UIView* superview);

/**
 * Represents a registered
 */
@interface ISSViewPrototype : NSObject

@property (nonatomic, strong, readonly) NSString* name;

@property (nonatomic, strong, readonly) NSString* propertyName;
@property (nonatomic, readonly) BOOL addAsSubView;

@property (nonatomic, copy, readonly) ViewBuilderBlock viewBuilderBlock;
@property (nonatomic, strong) NSArray* subviewPrototypes;

+ (ISSViewPrototype*) prototypeWithName:(NSString*)name propertyName:(NSString*)propertyName addAsSubView:(BOOL)addAsSubView viewBuilderBlock:(ViewBuilderBlock)viewBuilderBlock;

- (UIView*) createViewObjectFromPrototype:(id)parentObject;

@end
