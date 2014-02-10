//
//  DLTiming.h
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

#ifndef DL_TIMING
#define DL_TIMING

#if __cplusplus
extern "C" {
#endif

    #include <mach/mach_time.h>
        
    #define NANOS_IN_SEC    1000000000.0        //!< nanoseconds in a second
    #define NANOS_IN_MS     1000000.0           //!< nanoseconds in a milisecond
    #define MS_IN_SEC       1000.0              //!< miliseconds in a second

    #define NANOS_TO_SEC(x) ((x)/NANOS_IN_SEC)  //!< nanoseconds to seconds
    #define NANOS_TO_MS(x)  ((x)/NANOS_IN_MS)   //!< nanoseconds to miliseconds
    #define MS_TO_SEC(x)    ((x)/MS_IN_SEC)     //!< miliseconds to seconds

    #define SEC_TO_NANOS(x) ((x)*NANOS_IN_SEC)  //!< seconds to nanoseconds 
    #define MS_TO_NANOS(x)  ((x)*NANOS_IN_MS)   //!< miliseconds to nanoseconds 
    #define SEC_TO_MS(x)    ((x)*MS_IN_SEC)     //!< seconds to miliseconds 

    extern uint32_t machTimeBaseNum;            //!< mach_timebase_info numerator
    extern uint32_t machTimeBaseDenom;          //!< mach_timebase_info denominator
    extern double machTimeFreqNanoSec;          //!< frequency in nano seconds
//    extern double machTimeFreqSec;              //!< frequency in seconds

    void initMachTime();
    bool isMachTimeValid();
    
    double tic();
    double toc(double ticTime);
    
    /** Print time log from a function to std::cout */
    #define COUT_TIME_LOG(t) printf("time(%s) = %f\n", __FUNCTION__,  t);
    /** Print time log from a function (with extra description) to std::cout */
    #define COUT_TIME_LOG_AT(loc,t) printf("time(%s,%s) = %f\n", __FUNCTION__, loc, t);
    
#if __cplusplus
}
#endif    
    
#endif
