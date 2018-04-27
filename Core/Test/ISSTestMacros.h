//
//  ISSTestMacros.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#import "ISSMacros.h"

#ifndef ISSTestMacros_h
#define ISSTestMacros_h

#define ISSAssertEqualFloats(x, y, ...) XCTAssertTrue(ISS_ISEQUAL_FLT(x, y), __VA_ARGS__)

#define ISSAssertEqualIgnoringCase(x, y, ...) XCTAssertEqualObjects([x lowercaseString], [y lowercaseString], __VA_ARGS__)

#endif
