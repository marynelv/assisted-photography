//
//  DLFramesPerSecond.h
//  DataLogging
//
//    Created by Marynel Vazquez on 10/2/11.
//    Copyright 2011 Carnegie Mellon University.
//
//    This work was developed under the Rehabilitation Engineering Research 
//    Center on Accessible Public Transportation (www.rercapt.org) and is funded 
//    by grant number H133E080019 from the United States Department of Education 
//    through the National Institute on Disability and Rehabilitation Research. 
//    No endorsement should be assumed by NIDRR or the United States Government 
//    for the content contained on this code.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.
//

#ifndef DL_FPS_TRACKER
#define DL_FPS_TRACKER

#include "DLTiming.h"

#if __cplusplus
extern "C" {
#endif
    
/**
    Time interval tracker
    Use to compute framerates or the number of times a process completes in a second.   
    All that needs to be provided is a time stamp in seconds (preferably with double precision).
    @note In Objective C, an easy way to get the time stamp is by using the method <a>CACurrentMediaTime</a>.
 */
class FPSTracker
{
private:
    
    unsigned int _identifier;        //!< ID (for reference only)
    uint64_t _resetTime;
    unsigned int _count;             //!< number of updates (so far) in a second
    unsigned int _rate;              //!< number of updates per second (e.g., could be frame rate)
    
    void init(unsigned int identifier);
    
public:    
    FPSTracker();
    FPSTracker(unsigned int identifier);
    ~FPSTracker();
    
    bool update(bool printNewFPS = false);
    void reset();
    unsigned int rate();
};
    
#if __cplusplus
}
#endif

#endif
