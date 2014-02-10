//
//  ImageBlurriness.h
//  Framework-See
//
//	Created by Marynel Vazquez on 03/01/12.
//	Copyright 2012 Carnegie Mellon University
//
//	This work was developed under the Rehabilitation Engineering Research 
//	Center on Accessible Public Transportation (www.rercapt.org) and is funded 
//	by grant number H133E080019 from the United States Department of Education 
//	through the National Institute on Disability and Rehabilitation Research. 
//	No endorsement should be assumed by NIDRR or the United States Government 
//	for the content contained on this code.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#ifndef IMAGE_BLURRINESS
#define IMAGE_BLURRINESS

#include "ImageTypes.h"
#include "ImageConversion.h"
#include <math.h>

#if __cplusplus
extern "C" {
#endif
    
    inline float blurMetricToUserRating(float blurValue)
    {
        return (3.79/(1+exp(10.72*blurValue - 4.55))) + 1.13;
    }
    
    float perceptualBlurMetric(const img image, size_t width, size_t height, 
                               size_t bytesPerRow, const float *filter, size_t lenFilter, img *blurredH = 0, img *blurredV = 0, 
                               img *variationH = 0, img *variationV = 0);
    
#if __cplusplus
}
#endif

#endif
