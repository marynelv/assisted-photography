//
//  DLFramesPerSecond.cpp
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

#include "DLFramesPerSecond.h"
#include <iostream>


/**
    Common initialization between constructors
    Reset the interval tracker and sets the identifier
    @param identifier identifier
 */
inline void 
FPSTracker::init(unsigned int identifier)
{
    if (!isMachTimeValid()) initMachTime();
    
    reset();
    _identifier = identifier;
}

/**
    Constructor
 */
FPSTracker::FPSTracker()
{
    init(0);
}

/**
    Constructor
    @param identifier identifier
 */
FPSTracker::FPSTracker(unsigned int identifier)
{
    init(identifier);
}

/**
    Destructor
 */
FPSTracker::~FPSTracker()
{}

/**
    Update time interval tracker
    @param printNewFPS print new fps to stdout?
    @return did we complete a second cycle?
 */
bool 
FPSTracker::update(bool printNewFPS)
{
    bool cycle = false;
    uint64_t timeStamp = mach_absolute_time();
    if (!_count)
    {
        // start interval tracker
        _resetTime = timeStamp;
        _count = 1;
    }
    else if ((double)(timeStamp - _resetTime)*machTimeFreqNanoSec > NANOS_IN_SEC)
    {
        _rate = _count;
        _count = 0;
        _resetTime = timeStamp;
        
        cycle = true;
        
        if (printNewFPS) std::cout << "frame rate: " << _rate << std::endl;
    }
    else
    {
        _count = _count + 1;
    }
    
    return cycle;
}

/**
    Reset time interval tracker
 */
void 
FPSTracker::reset()
{
    _resetTime = 0.0;
    _count = 0;
    _rate = 0;
}

/**
    Rate
    @return computed rate (0 if it hasn't been computed or no updates happened during the last second)
 */
unsigned int 
FPSTracker::rate()
{
    return _rate;
}