//
//  ISSElementStylingProxy+Protected.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSElementStylingProxy.h"

NS_ASSUME_NONNULL_BEGIN


@interface NSObject (ISSElementStylingProxy)

@property (nonatomic, strong, nullable, setter=iss_setStylingProxy:) ISSElementStylingProxy* iss_stylingProxy;

@end


NS_ASSUME_NONNULL_END
