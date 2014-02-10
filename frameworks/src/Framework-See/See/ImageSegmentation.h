//
//  ImageSegmentation.h
//  see_project
//
//	Created by Marynel Vazquez on 11/30/10.
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

#ifndef IMAGE_SEGMENTATION
#define IMAGE_SEGMENTATION

#include "ImageTypes.h"

#if __cplusplus
extern "C" {
#endif

#pragma mark THRESHOLDING
	
#define THR_NO_SCALING 0.0f // no scaling before thresholding
	
void see_threshold(img *image, size_t size, float threshold, float scale);

/*! Threshold image with optional scaling
	\param image input image
	\param size image width times image height
	\param threshold threshold
	\param scale optional scaling before binarization
	\return binary version of <a>image</a> (uchar)
	 
	This function first scales the image to [0,<a>scale</a>] 
	using <a>scaleTo()</a> if <a>scale</a> is not zero. Then, 
	the image thresholded, setting zeros in all pixels with a 
	value less than <a>threshold</a>.
	 
	\note scale should be zero or positive
 */
inline img see_threshold2(const img image, size_t size, float threshold, float scale)
{
	img result = (float *)malloc(size*sizeof(float));
	cblas_scopy(size, image, 1, result, 1);
	see_threshold(&result, size, threshold, scale);
	return result;
}
	
/*! Threshold image assuming a uniform distribution of pixel values
	\param image input image
	\param size image width times image height 
 
	Consider each pixel in a discretized version
	of the input image as a bin in a two-dimensional
	histogram. If a pixel has a value of 100
	over 255, then we interpret its corresponding bin
	has 100 samples.
 
	The expected number of samples that would fall in 
	each bin (pixel) assuming a uniform distribution is
	the total number of samples in the histogram (sum of 
	all pixels) divided by the number of bins. The 
	expected number of samples is the threshold used in
	this function.
 
	The implementation does not actually discretize 
	the image, but works equivalently with a float array.
	The image is first displaced so that its minimum value 
	is zero.
	
	\note The resulting image can be considered as a binary
	map, where all values different than zero are 1.
 */
inline void see_uniformThresh(img *image, size_t size)
{
	// make sure the image does not have negative values
	float tmp = 0.0;
	vDSP_minv(*image, 1, &tmp, size);
	if (tmp != 0.0)
	{
		tmp = -tmp;
		vDSP_vsadd(*image, 1, &tmp, *image, 1, size);
	}
	// threshold
	vDSP_sve(*image, 1, &tmp, size);
	if (tmp > 0.0)
	{
		tmp = tmp/(float)size;
		see_threshold(image, size, tmp, THR_NO_SCALING);
	}
}
	
#pragma mark BLOBS
	
#define CC_UNLABELED	0.0f		//!< unlabeled pixel
#define CC_SURROUNDING	-1.0f		//!< surrounding contour pixel
	
img see_labelBlobs(const img image, size_t w, size_t h, int &nlabels);	

void see_colorBlobs(const img labels, size_t size, int nlabels, img *red, img *green, img *blue);
	
void see_highlightBlob(const img labels, size_t size, float label, img *highlight, float val);
	
float see_selectMostMeaningfulBlob( const img image, size_t size, const img labels, int nlabels, 
								    bool discretize, float **entropy = 0, int **sumval = 0, int **numbins = 0, 
								    img *discimg = 0 );
void see_weightedMean( const img image, size_t w, size_t h, const img labels, 
					   float label, float &x, float &y);

	
#if __cplusplus
}
#endif

#endif