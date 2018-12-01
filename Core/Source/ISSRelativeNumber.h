//
//  ISSRelativeNumber.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT (http://www.github.com/tolo/InterfaCSS/LICENSE)
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ISSRelativeNumberUnit) {
    ISSRelativeNumberUnitAbsolute,
    ISSRelativeNumberUnitPercent,
    ISSRelativeNumberUnitAuto
};

@interface ISSRelativeNumber : NSObject

@property (nonatomic, readonly) NSNumber* value;
@property (nonatomic, readonly) ISSRelativeNumberUnit unit;

- (instancetype) initWithNumber:(NSNumber*)number andUnit:(ISSRelativeNumberUnit)unit;

@end

NS_ASSUME_NONNULL_END
