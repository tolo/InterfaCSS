//
//  ISSMacros.h
//  Part of InterfaCSS - http://www.github.com/tolo/InterfaCSS
//
//  Copyright (c) Tobias Löfstrand, Leafnode AB.
//  License: MIT - http://www.github.com/tolo/InterfaCSS/blob/master/LICENSE
//

#ifndef ISSMacros_h
#define ISSMacros_h


#define ISS_ISEQUAL(x,y) ((x == y) || (x != nil && [x isEqual:y]))
#define ISS_ISEQUAL_FLT(x, y) (fabs((x) - (y)) < FLT_EPSILON)


#ifndef ISS_OS_VERSION_MIN_REQUIRED
    #if defined(__IPHONE_OS_VERSION_MIN_REQUIRED)
        #define ISS_OS_VERSION_MIN_REQUIRED __IPHONE_OS_VERSION_MIN_REQUIRED
    #elif defined(__TV_OS_VERSION_MIN_REQUIRED)
        #define ISS_OS_VERSION_MIN_REQUIRED __TV_OS_VERSION_MIN_REQUIRED
    #else
        #define ISS_OS_VERSION_MIN_REQUIRED 80000
    #endif
#endif


#ifndef ISS_OS_VERSION_MAX_ALLOWED
    #if defined(__IPHONE_OS_VERSION_MAX_ALLOWED)
        #define ISS_OS_VERSION_MAX_ALLOWED __IPHONE_OS_VERSION_MAX_ALLOWED
    #elif defined(__TV_OS_VERSION_MAX_ALLOWED)
        #define ISS_OS_VERSION_MAX_ALLOWED __TV_OS_VERSION_MAX_ALLOWED
    #else
        #define ISS_OS_VERSION_MAX_ALLOWED 11000
    #endif
#endif


#endif
