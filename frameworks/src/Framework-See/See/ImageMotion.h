//
//  ImageMotion.h
//  Framework-See
//
//	Created by Marynel Vazquez on 12/02/11.
//	Copyright 2011 Carnegie Mellon University
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

#ifndef IMAGE_MOTION
#define IMAGE_MOTION

#include "ImageTypes.h"
#include <BasicMath/Vector2.h>
#include <BasicMath/Rectangle.h>

#if __cplusplus
extern "C" {
#endif
    
    /**
     LKTemplateMatching status codes
     */
    typedef enum {
        TRACKING_OK,                //!< tracking processed finished without inconvenients
        TRACKING_STOPPEDBYBOUNDS,   //!< tracking stopped because tamplate went out of bounds
        TRACKING_OUTSIDEBOUNDS,     //!< template is outside bounds
        TRACKING_EMPTY,             //!< template is seriously dark! 
        TRACKING_NUM_RESULTS
    } TRACKINGRESULT;
        
//    img see_extractWindow(size_t w, size_t h, img image, const Rectangle& rect, 
//                          unsigned int margin = 0, Rectangle* windowRect = 0);
    TRACKINGRESULT see_LKTemplateMatching(size_t width, size_t height, img prevIm, img nextIm,
                                          Rectangle templateBox, Vector2 &motion, 
                                          Vector2 *leftMotion = 0, float *ssd = 0, 
                                          float epsi = 0.00003, int maxIter = 1500,
                                          img* gradX = 0, img* gradY = 0, img *tmplEnlarged = 0, Rectangle* tmplEnlargedBox = 0,
                                          img *trackedEnlarged = 0, Rectangle* trackedEnlargedBox = 0);
    
    TRACKINGRESULT see_FlexibleLKTemplateMatching(size_t width, size_t height, img prevIm, img nextIm,
                                                  Rectangle templateBox, float minTracked, Vector2 &motion, 
                                                  Vector2 *leftMotion = 0, float *ssd = 0, 
                                                  float epsi = 0.00003, int maxIter = 1500,
                                                  img* gradX = 0, img* gradY = 0, 
                                                  img *tmplEnlarged = 0, Rectangle* tmplEnlargedBox = 0,
                                                  img *trackedEnlarged = 0, Rectangle* trackedEnlargedBox = 0);
    
    TRACKINGRESULT see_PyramidalLKTemplateMatching(size_t width, size_t height, img prevIm, img nextIm, 
                                                   Rectangle templateBox, unsigned int pyrLevels, Vector2 &motion, 
                                                   Vector2 *leftMotion = 0, float *ssd = 0,
                                                   float epsi = 0.00003, int maxIter = 1500, pyr *prevPyr = 0, pyr *nextPyr = 0);
    
    TRACKINGRESULT see_LKPyramidalLK(size_t width, size_t height, img prevIm, img nextIm,
                                     Rectangle templateBox, unsigned int pyrLevels, Vector2 &motion,
                                     float *ssd = 0, float epsi = 0.03, int maxIter = 100, 
                                     pyr *prevPyr = 0, pyr *nextPyr = 0);
                        
#if __cplusplus
}
#endif

#endif
