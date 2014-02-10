//
//  ImageSaliency.mm
//  see_project
//
//	Created by Marynel Vazquez on 11/28/10.
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

#include "ImageSaliency.h"
#include "ImageConversion.h"
#include "SeeCommon.h"
#include <assert.h>
#include <math.h>
#include <iostream>
#include <DataLogging/DLTiming.h>

//#define TIME_SALIENCY         //!< time saliency execution
//#define TIME_FEATURESITTI     //!< time featuresItti execution

#pragma mark PRIVATE PROTOTYPES


void see_maxNormalize(img& image, size_t width, size_t height);
img see_centerSurround(img& img1, size_t w1, size_t h1,
                       img& img2, size_t w2, size_t h2);
img see_centerSurround2(img& img1, size_t w1, size_t h1,
                        img& img2, size_t w2, size_t h2);

#pragma mark SALIENCY ITTI

/*! Extract intensity and color opponency features
    \param array input image (RGBA)
    \param width image width
    \param height image height
    \param shrinkingTimes how many times to shrink original data by half
	\param featInt image intensity
	\param featRG red-green opponency
	\param featBY blue-yellow opponency
 */
void see_featuresItti(const unsigned char *array, size_t& width, size_t& height, unsigned int shrinkingTimes,
					  img *featInt, img *featRG, img *featBY)
{    
#ifdef TIME_FEATURESITTI
    double t = tic();
#endif
    
	img red = 0, green = 0, blue = 0;
    size_t size;
    
#ifdef TIME_FEATURESITTI
    double tDecomp = tic();
#endif
    
    if (shrinkingTimes > 0)
    {
        see_shrinkRGBA(shrinkingTimes, array, width, height, FILTER_GAUS7, FSIZE_GAUS7, &red, &green, &blue);
        size = width*height;
    }
    else
    {
        size = width*height;
        see_decompose(array, size, &red, &green, &blue);
    }

#ifdef TIME_FEATURESITTI
    tDecomp = toc(tDecomp);
    tDecomp = tDecomp / NANOS_IN_MS;
    COUT_TIME_LOG_AT("see_decompose", tDecomp);
#endif
    
    
#ifdef TIME_FEATURESITTI
    double tInt = tic();
#endif
    
	*featInt = see_intensity(red, green, blue, size);
    
#ifdef TIME_FEATURESITTI
    tInt = toc(tInt);
    tInt = tInt / NANOS_IN_MS;
    COUT_TIME_LOG_AT("see_intensity", tInt);
#endif
    
    
#ifdef TIME_FEATURESITTI
    double tOpp = tic();
#endif
    
	see_opponency(red, green, blue, size, featRG, featBY);
    
#ifdef TIME_FEATURESITTI
    tOpp = toc(tOpp);
    tOpp = tOpp / NANOS_IN_MS;
    COUT_TIME_LOG_AT("see_opponency", tOpp);
#endif
    
    
	free(red); free(green); free(blue);
    
#ifdef TIME_FEATURESITTI
    t = toc(t);
    t = t / NANOS_IN_MS;
    COUT_TIME_LOG(t);
#endif

}

/*! Normalize image depending on number of local maximums
	\param image input image
	\param width image width
	\param height image height
 
	Thransforms input image by normalizing its values. Local
	maximums greater than <a>t</a> are counted
	and then \f[ (x',y') = (x,y)/\sqrt(m) \f], where <a>m</a>
	is the number of local max.
	 
	If no local maximums are found, <a>image</a> is not modified.
	 
	\note this is taking maximas as greater than (not equal) than the neighbors!
 */
void see_maxNormalize(img& image, size_t width, size_t height)
{    
	assert( image != 0 );
    
    float threshold = 0.0;
    vDSP_maxv(image, 1, &threshold, width*height);
    
    // \todo remove if stable...
    if (isnan(threshold) || isinf(threshold)) 
    {
        return; //\todo check why this happens! 
        std::cout << "threshols is wrong! = " << threshold <<  std::endl;
        assert(!isnan(threshold));
        assert(!isinf(threshold));
    }  
    
	threshold = threshold*0.5; // half maximum
    
	size_t w = width-2; 
	img tmp = (float *)malloc(width * sizeof(float));
	img tmp1 = (float *)malloc(w * sizeof(float));

    float m = 0.0f;
	
	
	for ( int row = 1; row < height - 1; row++ )
	{
		// max(top,bottom)
		vDSP_vmax(image+(row-1)*width, 1, image+(row+1)*width, 1,tmp, 1, width);
        // max(max(top,bottom), this_row)
        vDSP_vmax(tmp, 1, image + row*width, 1, tmp, 1, width);
        
        // max(left, right)
        vDSP_vmax(tmp, 1, tmp+2, 1, tmp1, 1, w);
        // max(max(left, right), middle)
        vDSP_vmax(tmp1, 1, tmp+1, 1, tmp1, 1, w);

		float *addr = image + row*width + 1;	

		// go linear here because we don't want to convert
		// image to another type (e.g. char or int) for 
		// logic bit-wise comparison...
		for (int col = 1; col < w - 1; col ++)
		{
			if (addr[col] > threshold && tmp1[col] == addr[col]) m = m + 1.0;
		}
	}
	
	if (m > 0)
	{
		m = 1.0/sqrt(m);
		vDSP_vsmul(image,1,&m,image,1,width*height);
	}

	free(tmp);
	free(tmp1);
}

/*! Accross-scale center-surround operator
	\param img1 bigger image
	\param w1 <a>img1</a> width
	\param h1 <a>img1</a> height
	\param img2 smaller image
	\param w2 <a>img2</a> width
	\param h2 <a>img2</a> height
	\return center surround result
	\note <a>img2</a> should be a subsampled version of <a>img1</a>
 */
img see_centerSurround(img& img1, size_t w1, size_t h1,
                       img& img2, size_t w2, size_t h2)
{    
	size_t size = w1*h1;
	img scaled = see_enlarge(w1, h1, img2, w2, h2);
    
//    std::cout << "center surround with " << w1 << "x" << h1 
//              << " and " << w2 << "x" << h2 << std::endl;
    
    // vDSP_vsub(A, i, B, j, C, k, ...) yields C = B - A.
	vDSP_vsub(scaled, 1, img1, 1, scaled, 1, size);	
//	vDSP_vsub(img1, 1, scaled, 1, scaled, 1, size);	
    
#ifdef DO_DOUBLE_CENTER_SURROUND
    float t = 0;
    vDSP_vthres (scaled, 1, &t, scaled, 1, size);
#else
    vDSP_vabs(scaled, 1, scaled, 1, size);
#endif

	see_maxNormalize(scaled, w1, h1);
	
	return scaled;
}

#ifdef DO_DOUBLE_CENTER_SURROUND
/*! Accross-scale center-surround operator (inverse)
 \param img1 bigger image
 \param w1 <a>img1</a> width
 \param h1 <a>img1</a> height
 \param img2 smaller image
 \param w2 <a>img2</a> width
 \param h2 <a>img2</a> height
 \return center surround result
 \note <a>img2</a> should be a subsampled version of <a>img1</a>
 */
img see_centerSurround2(img& img1, size_t w1, size_t h1,
                        img& img2, size_t w2, size_t h2)
{    
	size_t size = w1*h1;
	img scaled = see_enlarge(w1, h1, img2, w2, h2);
    
    //    std::cout << "center surround with " << w1 << "x" << h1 
    //              << " and " << w2 << "x" << h2 << std::endl;
    
    // vDSP_vsub(A, i, B, j, C, k, ...) yields C = B - A.
	vDSP_vsub(img1, 1, scaled, 1, scaled, 1, size);	
    //	vDSP_vsub(img1, 1, scaled, 1, scaled, 1, size);	
    float t = 0;
    vDSP_vthres (scaled, 1, &t, scaled, 1, size);
//	vDSP_vabs(scaled, 1, scaled, 1, size);
    
	see_maxNormalize(scaled, w1, h1);
	
	return scaled;
}
#endif
				  

/*! Simplified version of Itti's saliency method
	\param array input image buffer (RGBA)
	\param width image width
	\param height image height
	\param pyrlev pyramid size
	\param offset number of pyramid levels ignored during computation
	\param surrlev number of surround levels to consider {1,..,<a>surrlev<a/>}
	\param saliency saliency map
	\param salw <a>saliency</a> width
	\param salh <a>saliency</a> height
 
	\note The full size of the pyramid is <a>pyrlev<a/>+<a>surrlev</a>.
	\note If offset is zero, the firt level of the pyramid is the input image.
	
	\todo check parameters
 */
void see_saliencyItti(const unsigned char *array, size_t width, size_t height,
					  size_t pyrlev, size_t offset, size_t surrlev,
					  img& saliency, size_t& salw, size_t& salh,
                      img *featureInt, img *featureRG, img *featureBY)
{
#ifdef TIME_SALIENCY
    double t = tic();
#endif
    
	assert( offset >= 0 );
	
	img featInt = 0, featRG = 0, featBY = 0;
	
#ifdef TIME_SALIENCY
    double tFeat = tic();
#endif
    
	// extract features (reduce image first if offset > 0)
	see_featuresItti(array, width, height, offset, &featInt, &featRG, &featBY);
    
#ifdef TIME_SALIENCY
    tFeat = toc(tFeat);
    tFeat = tFeat / NANOS_IN_MS;
    COUT_TIME_LOG_AT("see_featuresItti",tFeat);
#endif
    
	salw = width;
	salh = height;
    
    see_saliencyIttiWithFeatures(featInt, featRG, featBY, width, height, pyrlev, surrlev, saliency);

	if (featureInt != NULL && featureInt != 0)
        *featureInt = featInt;
    else 
        free(featInt);
    
    if (featureRG != NULL && featureRG != 0)
        *featureRG = featRG;
    else 
        free(featRG);
    
    if (featureBY != NULL && featureBY != 0)
        *featureBY = featBY;
    else 
        free(featBY);
    
#ifdef TIME_SALIENCY
    t = toc(t);
    t = t / NANOS_IN_MS;
    COUT_TIME_LOG(t);
#endif
}

/*! Simplified version of Itti's saliency method given intensity, r-g and b-y features
    \param featInt intensity feature
    \param featRG red-green feature
    \param faetBY blue-yellow features
    \param width image width
    \param height image height
    \param pyrlev pyramid size
    \param surrlev number of surround levels to consider {1,..,<a>surrlev<a/>}
    \param saliency saliency map
    \param salw <a>saliency</a> width
    \param salh <a>saliency</a> height

    \note The full size of the pyramid is <a>pyrlev<a/>+<a>surrlev</a>

    \todo check parameters
 */
void see_saliencyIttiWithFeatures(const img featInt, const img featRG, const img featBY, 
                                  size_t width, size_t height, size_t pyrlev, size_t surrlev,
                                  img& saliency)
{
#ifdef TIME_SALIENCY
    double t = tic();
#endif
    
//    std::cout << "input saliency: " << width << "x" << height << std::endl;
    
    size_t totlev = pyrlev + surrlev, size = width*height;
    pyr pyrInt; pyr pyrRG; pyr pyrBY;
	pyr pyrSurrInt; pyr pyrSurrRG; pyr pyrSurrBY;
    
    // build feature pyramids
#ifdef TIME_SALIENCY
    double tPyrAvg = 0;
    double tPyr = tic();
#endif
    
	see_pyramid(featInt, width, height, totlev, pyrInt, FILTER_GAUS7, FSIZE_GAUS7, 0);
#ifdef TIME_SALIENCY
    tPyr = toc(tPyr);
    tPyrAvg = tPyr / NANOS_IN_MS;
    tPyr = tic();
#endif
    
    see_pyramid(featRG, width, height, totlev, pyrRG, FILTER_GAUS7, FSIZE_GAUS7, 0);
#ifdef TIME_SALIENCY
    tPyr = toc(tPyr);
    tPyrAvg = tPyrAvg + (tPyr / NANOS_IN_MS);
    tPyr = tic();
#endif
    
    see_pyramid(featBY, width, height, totlev, pyrBY, FILTER_GAUS7, FSIZE_GAUS7, 0);
#ifdef TIME_SALIENCY
    tPyr = toc(tPyr);
    tPyrAvg = tPyrAvg + (tPyr / NANOS_IN_MS);
    tPyrAvg = tPyrAvg/3.0;
    COUT_TIME_LOG_AT("avg(see_pyramid)",tPyrAvg);
#endif    
	
	// set max size of image in pyramids
	size_t w1 , h1, w2, h2;
	img surround;
#ifdef DO_DOUBLE_CENTER_SURROUND
	img surround2;
#endif
	
#ifdef TIME_SALIENCY
    double tCenterSurround = tic();
#endif
    
	// apply accross scale center-surround operations
	for (int l=0; l<pyrlev; l++)
	{
		// set image size at this level
		w1 = width >> l; h1 = height >> l;
		
		for (int s=1; s<surrlev+1; s++)
		{
			// set second image size
			w2 = w1 >> s; h2 = h1 >> s;
			
			// intensity
			surround = see_centerSurround(pyrInt.at(l), w1, h1, pyrInt.at(l+s), w2, h2);
#ifdef DO_DOUBLE_CENTER_SURROUND
			surround2 = see_centerSurround2(pyrInt.at(l), w1, h1, pyrInt.at(l+s), w2, h2);
#endif
			if (l) // store result with a size of width*height
			{
				img tmp = see_enlarge(width, height, surround, w1, h1);
				free(surround);
				surround = tmp;
#ifdef DO_DOUBLE_CENTER_SURROUND
				img tmp2 = see_enlarge(width, height, surround2, w1, h1);
				free(surround2);
				surround2 = tmp2;
#endif
			}
			pyrSurrInt.push_back(surround);
#ifdef DO_DOUBLE_CENTER_SURROUND
			pyrSurrInt.push_back(surround2);
#endif
            
			// r-g
			surround = see_centerSurround(pyrRG.at(l), w1, h1, pyrRG.at(l+s), w2, h2);
#ifdef DO_DOUBLE_CENTER_SURROUND
			surround2 = see_centerSurround2(pyrRG.at(l), w1, h1, pyrRG.at(l+s), w2, h2);
#endif
			if (l) // store result with a size of width*height
			{
				img tmp = see_enlarge(width, height, surround, w1, h1);
				free(surround);
				surround = tmp;
#ifdef DO_DOUBLE_CENTER_SURROUND
				img tmp2 = see_enlarge(width, height, surround2, w1, h1);
				free(surround2);
				surround2 = tmp2;
#endif
			}
			pyrSurrRG.push_back(surround);
#ifdef DO_DOUBLE_CENTER_SURROUND
			pyrSurrRG.push_back(surround2);
#endif
			
			// b-y
			surround = see_centerSurround(pyrBY.at(l), w1, h1, pyrBY.at(l+s), w2, h2);
#ifdef DO_DOUBLE_CENTER_SURROUND
			surround2 = see_centerSurround2(pyrBY.at(l), w1, h1, pyrBY.at(l+s), w2, h2);
#endif
			if (l) // store result with a size of width*height
			{
				img tmp = see_enlarge(width, height, surround, w1, h1);
				free(surround);
				surround = tmp;
#ifdef DO_DOUBLE_CENTER_SURROUND
				img tmp2 = see_enlarge(width, height, surround2, w1, h1);
				free(surround2);
				surround2 = tmp2;
#endif
			}
			pyrSurrBY.push_back(surround);
#ifdef DO_DOUBLE_CENTER_SURROUND
			pyrSurrBY.push_back(surround2);
#endif			
		}
	}
    
#ifdef TIME_SALIENCY
    tCenterSurround = toc(tCenterSurround);
    tCenterSurround = tCenterSurround / NANOS_IN_MS;
    COUT_TIME_LOG_AT("all center surround",tCenterSurround);
#endif
	
    
#ifdef TIME_SALIENCY
    double tConspicuity = tic();
#endif
    
	// compute conspicuity maps
	for ( int i = 1; i < pyrSurrInt.size(); i++ )
	{
		// intensity
		vDSP_vadd(pyrSurrInt.at(0),1,pyrSurrInt.at(i),1,pyrSurrInt.at(0),1,size);
		// r-g
		vDSP_vadd(pyrSurrRG.at(0),1,pyrSurrRG.at(i),1,pyrSurrRG.at(0),1,size);
		// b-y
		vDSP_vadd(pyrSurrBY.at(0),1,pyrSurrBY.at(i),1,pyrSurrBY.at(0),1,size);
	}
    
	see_maxNormalize(pyrSurrInt.at(0), width, height);
	see_maxNormalize(pyrSurrRG.at(0), width, height);
	see_maxNormalize(pyrSurrBY.at(0), width, height);
	vDSP_vadd(pyrSurrRG.at(0),1,pyrSurrBY.at(0),1,pyrSurrRG.at(0),1,size);
	see_maxNormalize(pyrSurrRG.at(0), width, height); // store color conspicuity in top RG
    
#ifdef TIME_SALIENCY
    tConspicuity = toc(tConspicuity);
    tConspicuity = tConspicuity / NANOS_IN_MS;
    COUT_TIME_LOG_AT("all conspicuity",tConspicuity);
#endif
	
#ifdef TIME_SALIENCY
    double tMerge = tic();
#endif
    
	// combine conspicuity maps and store final result
	saliency = (float *)malloc(size*sizeof(float));
	float divfactor = 0.5;
	vDSP_vadd(pyrSurrInt.at(0),1,pyrSurrRG.at(0),1,pyrSurrInt.at(0),1,size);
	vDSP_vsmul(pyrSurrInt.at(0),1,&divfactor,saliency,1,size);
    
#ifdef TIME_SALIENCY
    tMerge = toc(tMerge);
    tMerge = tMerge / NANOS_IN_MS;
    COUT_TIME_LOG_AT("final merge",tMerge);
#endif
    
	// be good with the environment
	see_freePyr(pyrSurrInt); see_freePyr(pyrSurrRG); see_freePyr(pyrSurrBY);
    pyrInt.erase(pyrInt.begin());
    pyrRG.erase(pyrRG.begin());
    pyrBY.erase(pyrBY.begin());
	see_freePyr(pyrInt); see_freePyr(pyrRG); see_freePyr(pyrBY);    
    
#ifdef TIME_SALIENCY
    t = toc(t);
    t = t / NANOS_IN_MS;
    COUT_TIME_LOG(t);
#endif
}


