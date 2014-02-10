//
//  DLTiming.cpp
//  Framework-DataLogging
//
//    Created by Marynel Vazquez on 11/6/11.
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

#include "DLTiming.h"

uint32_t machTimeBaseNum = 0;
uint32_t machTimeBaseDenom = 0;
double machTimeFreqNanoSec = 0.0;
//double machTimeFreqSec = 0.0;

/**
    Initialize <a>machTimeBaseNum</a>, <a>machTimeBaseDenom</a>, <a>machTimeFreqNanoSec</a> and <a>machTimeFreqSec</a>
 */
void initMachTime()
{
    struct mach_timebase_info machTimeBaseInfo; 
    mach_timebase_info(&machTimeBaseInfo);   
    machTimeBaseNum = machTimeBaseInfo.numer;
    machTimeBaseDenom = machTimeBaseInfo.denom;
    machTimeFreqNanoSec = ((double)machTimeBaseNum) / ((double)machTimeBaseDenom);
//    machTimeFreqSec = machTimeFreqNanoSec * NANOS_IN_SEC;
}

/**
    Have <a>machTimeBaseNum</a>, <a>machTimeBaseDenom</a>, <a>machTimeFreqNanoSec</a> and <a>machTimeFreqSec</a> been initialized?
    @return have the variables been initialized?
 */
bool isMachTimeValid(){ 
    return machTimeFreqNanoSec != 0.0;// && machTimeFreqSec == machTimeFreqNanoSec * NANOS_IN_SEC; 
}

/**
    Instant absolute time in nano seconds
    @return time
 */
double tic()
{
    uint64_t absoluteTime = mach_absolute_time();
    return ((double)absoluteTime * machTimeFreqNanoSec);
}

/**
    Elapsed time in nano seconds
    @param ticTime absolute initial time (in nano seconds)
    @return elapsed time since <a>tic</a>
 */
double toc(double ticTime)
{
    double current = tic();
    return current - ticTime;
}

