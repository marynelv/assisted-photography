//
//  ImageConversion.h
//  see_project
//
//	Created by Marynel Vazquez on 11/23/10.
//	Copyright 2010 Carnegie Mellon University
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

#ifndef IMAGE_CONVERSION
#define IMAGE_CONVERSION

#include "ImageTypes.h"
#include <BasicMath/Vector2.h>
#include <Accelerate/Accelerate.h>
#include <assert.h>
#include <BasicMath/Rectangle.h>

#if __cplusplus
extern "C" {
#endif	
    	
#pragma mark BASIC IMAGE CONVERSION
	
/*! Convert unsigned char array to float array
 \param array uchar array
 \param stride <a>array</a> stride
 \param length number of elements in converted array
 \param left elements to ignore at the beginning of the <a>array</a>
 \param right elements to ignore at the end of the <a>array</a>
 \return <a>array</a> as float array
 \note The final array is assumed to have stride of 1 when copying
 */
inline float* see_ucharArrayToFloat(const unsigned char *array,
									int32_t stride,
									size_t length,
									size_t left,
									size_t right)
{	
    size_t realLength = length-left-right;
	float *f = (float *) calloc(realLength, sizeof(float));
	vDSP_vfltu8((unsigned char*)array+left,stride,f,1,length);
	return f;
}

/*! Convert float array to unsigned char array
    \param array float array
    \param length number of elements in <a>array<a/>
    \param left elements to ignore at the beginning of the <a>array</a>
    \param right elements to ignore at the end of the <a>array</a>
    \param stride output stride
    \return <a>array</a> as uchar array
    \note The input array is assumed to have stride of one. 
    <a>left</a> plus <a>right</a> should be less than <a>length</a>
 */
inline unsigned char* see_floatArrayToUChar(const float *array,
											size_t length,
											size_t left,
											size_t right,
											int32_t stride)
{
	assert(left + right < length);
    size_t realLength = length-left-right;
	unsigned char *c = (unsigned char *) malloc(realLength*sizeof(unsigned char));
	vDSP_vfixru8((float*)array+left,1,c,stride,realLength);
	return c;
}
    
/*! Convert float array to unsigned char array
    \param array float array
    \param length number of elements in <a>array<a/>
    \return <a>array</a> as uchar array
    \note The input array is assumed to have stride of one. 
    <a>left</a> plus <a>right</a> should be less than <a>length</a>
*/
inline unsigned char* see_floatArrayToUCharRGB(const float *array,
                                               size_t length)
{
    unsigned char *c = (unsigned char *) malloc(length*sizeof(unsigned char)*3);
    vDSP_vfixru8((float*)array,1,c,3,length);
    vDSP_vfixru8((float*)array,1,c+1,3,length);
    vDSP_vfixru8((float*)array,1,c+2,3,length);
    return c;
}

/*! Scale image to range in [0,<a>maxVal</a>]
	\param image input image
	\param size image width times image size
	\param maxVal maximum value after scaling (inclusive)
	\note <a>image</a> is assumed to have stride of 1. 
 */
inline void see_scaleTo(img &image, size_t size, float maxVal, int32_t stride = 1)
{
	
	float maximum = 0.0, minimum = 0.0;
	vDSP_minv(image, stride, &minimum, size);
	vDSP_maxv(image, stride, &maximum, size);
	
	//NSLog(@"max = %.2f | min = %.2f", maximum, minimum);
	minimum = -minimum;
	float r = maxVal/(maximum + minimum);
	vDSP_vsadd(image, stride, &minimum, image, stride, size);
	vDSP_vsmul(image, stride, &r, image, stride, size);
}
    
img see_scaleToAndCopy(img &image, size_t size, float maxVal, int32_t stride = 1);
	
void see_decomposeRGBA(const unsigned char *array, size_t size, 
                       img *red, img *green, img *blue);
void see_decomposeBGRA(const unsigned char *array, size_t size, 
                       img *red, img *green, img *blue);
    
/**
    Decompose color image into R-G-B channels (assumes the image comes in BGRA format)
    \param array image to decompose (BGRA)
    \param size image width times image height
    \param red red channel
    \param blue blue channel
    \param green green channel
    \param normalize normalize in [0,1]
 
    \note This method was added for convenience since Apple recommended working with BGRA data instead of RGBA.
 */
inline void see_decompose(const unsigned char *array, size_t size, 
                          img *red, img *green, img *blue)
{
    see_decomposeBGRA(array, size, red, green, blue);
}
			   
img see_intensity(const img r, const img g, const img b, size_t size);
void see_opponency(const img r, const img g, const img b, size_t size, img *rg, img *by);
	
img see_enlargeWithDim(size_t desiredw, size_t desiredh, const img& image, 
                       size_t width, size_t height, size_t& neww, size_t& newh, bool pixelate = false);
img see_enlarge(size_t desiredw, size_t desiredh, const img& image, 
                size_t width, size_t height);
    
img see_shrinkByHalf(const img image, size_t width, size_t height, const float *filter, size_t length);
    
void see_shrinkRGBA(unsigned int shrinkingTimes, const unsigned char *array, size_t& width, size_t& height, 
                    const float *filter, size_t length, 
                    img *r = NULL, img *g = NULL, img *b = NULL);
	
img see_subpixBlock(const img image, size_t width, size_t height, float x, float y, size_t w);	
    
img see_extractWindow(size_t w, size_t h, img image, 
                      const Rectangle& rect, unsigned int margin, 
                      Rectangle* windowRect);
img see_addMargin(size_t w, size_t h, img image, unsigned int margin, size_t *newW = NULL, size_t *newH = NULL);
    
#pragma mark FILTERING
	
const float see_filterGaus7[] = 
	{0.0044f, 0.0540f, 0.2420f, 0.3991f, 
		0.2420f, 0.0540f, 0.0044f};
#define FILTER_GAUS7	see_filterGaus7
#define FSIZE_GAUS7		7
	
const float see_filterDerivGauss7[] =
    {0.0133, 0.1080, 0.2420, 0, -0.2420, -0.1080, -0.0133};
#define FILTER_GAUSDERIV7 see_filterDerivGauss7
#define FSIZE_GAUSDERIV7  7
    
    
const float see_filterDerivPrewitt3[] =
    {-1, 0, 1};
#define FILTER_PREWITTDERIV3 see_filterDerivPrewitt3
#define FSIZE_PREWITTDERIV3  3    
    
const float see_filterAverage3[] =
    {0.3333, 0.3333, 0.3333};
#define FILTER_AVERAGE3 see_filterAverage3
#define FSIZE_AVERAGE3 3
    
const float see_filterAverage5[] =
    {0.2, 0.2, 0.2, 0.2, 0.2};
#define FILTER_AVERAGE5 see_filterAverage5
#define FSIZE_AVERAGE5 5
    
const float see_filterAverage9[] =
    {0.1111, 0.1111, 0.1111, 0.1111, 0.1111, 
        0.1111, 0.1111, 0.1111, 0.1111};
#define FILTER_AVERAGE9 see_filterAverage9
#define FSIZE_AVERAGE9 9
    
img see_convolveHor(const img image, size_t width, size_t height, size_t bytesPerRow, 
                    const float *filter, size_t lenFilter, Vector2* size = 0, unsigned int emptyMargin = 0);
img see_convolveVer(const img image, size_t width, size_t height, size_t bytesPerRow, 
                    const float *filter, size_t lenFilter, Vector2* size = 0, unsigned int emptyMargin = 0);
    
#pragma mark PYRAMID

void see_pyramid(const img image, size_t width, size_t height, size_t lev,
			 pyr& pyramid, const float *filter, size_t length, int offset);
	
void see_freePyr(pyr& pyramid);
void see_freePyrUpToBase(pyr& pyramid);
	
#if __cplusplus
}
#endif

#endif