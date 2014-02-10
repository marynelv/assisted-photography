//
//  SeeCommon.h
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#ifndef SEE_COMMON
#define SEE_COMMON

//#define PRINT_DEBUG_MSG
//#define TIME_PROCESSES

#ifdef __OBJC__

#define SeeDebugFile [NSString stringWithFormat:@"%@: %d",[[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__]
#define SeeDebugLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#endif

#endif