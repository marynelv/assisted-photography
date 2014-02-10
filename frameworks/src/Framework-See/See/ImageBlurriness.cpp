//
//  ImageBlurriness.cpp
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

#include "ImageBlurriness.h"
#include <math.h>

/**
    Blur metric for gray image
    \param image grayscale image
    \param width image width
    \param height image height
    \param bytesperrow bytes per row in the image
    \param filter blur/averaging filter
    \param lenFilter filter length
    \return blur metric evaluation
 
    Follows the method of F. Cretea, T. Dolmierea, P. Ladreta, M. Nicolas. The Blur Effect: 
    Perception and Estimation with a New No-Reference Perceptual Blur Metric. Proceedings 
    of SPIE. 2007
 */
float perceptualBlurMetric(const img image, size_t width, size_t height, size_t bytesPerRow, 
                           const float *filter, size_t lenFilter, img *blurredH, img *blurredV,
                           img *variationH, img *variationV)
{
    unsigned int margin = floor(lenFilter/2);

    size_t extendedW, extendedH;
    img extendedImage = see_addMargin(width, height, image, margin, &extendedW, &extendedH);
    
    // replicate borders
    for (int m=0; m<margin; m++)
    {
        // copy top and bottom borders
        cblas_scopy((int)width, image, 1, extendedImage + margin + m*extendedW, 1);
        cblas_scopy((int)width, image + (height - 1)*width, 1, extendedImage + margin + (m + margin + height)*extendedW, 1);
        // copy left and right borders
        cblas_scopy((int)height, image, (int)width, extendedImage + margin*extendedW + m, (int)extendedW);
        cblas_scopy((int)height, image + width - 1, (int)width, extendedImage + margin + width + margin*extendedW + m, (int)extendedW);
    }
    
    // blur image
    Vector2 blurredHorSize, blurredVerSize;
    img blurredHor = see_convolveHor(extendedImage, extendedW, extendedH, 0, 
                                     filter, lenFilter, &blurredHorSize, 0 /* margin */);
    img blurredVer = see_convolveVer(extendedImage, extendedW, extendedH, 0, 
                                     filter, lenFilter, &blurredVerSize, 0 /* margin */);
    assert(blurredHorSize.x == width && blurredVerSize.y == height);
    
    free(extendedImage);
    
    // compute image differences
    // note: vDSP_vsub(A, i, B, j, C, k, ...) yields C = B - A.
    size_t diffHorLength = (width-1)*height;
    size_t diffVerLength = width*(height-1);
    img diffImageHor = (float *)malloc(diffHorLength*sizeof(float));
    img diffImageVer = (float *)malloc(diffVerLength*sizeof(float));
    img diffBlurredHor = (float *)malloc(diffHorLength*sizeof(float));
    img diffBlurredVer = (float *)malloc(diffVerLength*sizeof(float));
    
    vDSP_vsub(image + width, 1, image, 1, diffImageVer, 1, diffVerLength);
    
    for (int c=0; c < width-1; c++) {
        vDSP_vsub(image + 1 + c, width, image + c, width, diffImageHor + c, width - 1, height);
    }

    for (int r=0; r < height - 1; r++) {
        vDSP_vsub(blurredVer + (r + 1)*extendedW + margin, 1, blurredVer + r*extendedW + margin, 1, 
                  diffBlurredVer + r*width, 1, width);
    }
    
    for (int r=0; r < height; r++) {
        vDSP_vsub(blurredHor + (r + margin)*width + 1, 1, blurredHor + (r + margin)*width, 1, 
                  diffBlurredHor + r*(width-1), 1, width-1);
    }
        
    if (blurredH == 0) free(blurredHor); 
    else *blurredH = blurredHor;
    if (blurredV == 0) free(blurredVer);
    else *blurredV = blurredVer;
        
    // compute abs of differences
    vDSP_vabs(diffImageHor, 1, diffImageHor, 1, diffHorLength);
    vDSP_vabs(diffImageVer, 1, diffImageVer, 1, diffVerLength);
    vDSP_vabs(diffBlurredHor, 1, diffBlurredHor, 1, diffHorLength);
    vDSP_vabs(diffBlurredVer, 1, diffBlurredVer, 1, diffVerLength);
    
    // compute image variation after blurring and threshold at zero
    // this way we keep only differences that have decreased
    img variationHor = (float *)malloc(diffHorLength*sizeof(float));
    img variationVer = (float *)malloc(diffVerLength*sizeof(float));
    
    vDSP_vsub(diffBlurredHor, 1, diffImageHor, 1, variationHor, 1, diffHorLength);
    vDSP_vsub(diffBlurredVer, 1, diffImageVer, 1, variationVer, 1, diffVerLength);
    
    float lowerThresh = 0.0;
    vDSP_vthres(variationHor, 1, &lowerThresh, variationHor, 1, diffHorLength);
    vDSP_vthres(variationVer, 1, &lowerThresh, variationVer, 1, diffVerLength);
    
    free(diffBlurredHor); free(diffBlurredVer);

    // compute sum of coefficients (need to loop because of the border)
    float sumDiffImageHor = 0, sumDiffImageVer = 0; 
    float sumVariationHor = 0, sumVariationVer = 0;
    float tmp;
    
    for (int r=0; r<height-1; r++)
    { // size might be wrong here!
        tmp = 0; 
        vDSP_sve(diffImageHor + (width - 1)*r, 1, &tmp, width - 1); 
        sumDiffImageHor += tmp;
        
        tmp = 0; 
        vDSP_sve(diffImageVer + width*r, 1, &tmp, width - 1); 
        sumDiffImageVer += tmp;
        
        tmp = 0; 
        vDSP_sve(variationHor + (width - 1)*r, 1, &tmp, width - 1); 
        sumVariationHor += tmp;
        
        tmp = 0; 
        vDSP_sve(variationVer + width*r, 1, &tmp, width - 1); 
        sumVariationVer += tmp;
    }
        
    free(diffImageHor); free(diffImageVer);
    
    if (variationH == 0) free(variationHor); 
    else *variationH = variationHor;
    if (variationV == 0) free(variationVer); 
    else *variationV = variationVer;
    
    // normalize results
    float blurHor = (sumDiffImageHor - sumVariationHor)/sumDiffImageHor;
    float blurVer = (sumDiffImageVer - sumVariationVer)/sumDiffImageVer;
        
    // select blur as the more anoying normalized sum of differences
    return (blurHor > blurVer ? blurHor : blurVer);
}
