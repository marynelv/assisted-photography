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

#import "ImageConversion.h"
#import <iostream>

#pragma mark BASIC IMAGE CONVERSION

/*! Scale image to range in [0,<a>maxVal</a>]
 \param image input image
 \param size image width times image size
 \param maxVal maximum value after scaling (inclusive)
 \return scaled image
 \note <a>image</a> is assumed to have stride of 1. 
 */
img see_scaleToAndCopy(img &image, size_t size, float maxVal, int32_t stride)
{
    img scaled = (float *)malloc(sizeof(float)*size);
    
    float maximum = 0.0, minimum = 0.0;
    vDSP_minv(image, stride, &minimum, size);
    vDSP_maxv(image, stride, &maximum, size);
    
    //NSLog(@"max = %.2f | min = %.2f", maximum, minimum);
    minimum = -minimum;
    float r = maxVal/(maximum + minimum);
    vDSP_vsadd(image, stride, &minimum, scaled, stride, size);
    vDSP_vsmul(scaled, stride, &r, scaled, stride, size);
    
    return scaled;
}

/*! Decompose color image (RGBA) into R-G-B channels (float arrays)
	\param array image to decompose (RGBA)
	\param size image width times image height
	\param red red channel
	\param blue blue channel
	\param green green channel
	\param normalize normalize in [0,1]
	\todo Error checking.
 */
void see_decomposeRGBA(const unsigned char *array, size_t size, 
                       img *red, img *green, img *blue)
{
	if (red)
	{
		img r = (float*)malloc(size*sizeof(float));
		vDSP_vfltu8((unsigned char*)array,4,r,1,size);
		*red = r;
	}
	
	if (green)
	{
		img g = (float*)malloc(size*sizeof(float));
		vDSP_vfltu8((unsigned char*)array+1,4,g,1,size);
		*green = g;
	}
			  
	if (blue)
	{
		img b = (float*)malloc(size*sizeof(float));
		vDSP_vfltu8((unsigned char*)array+2,4,b,1,size);
		*blue = b;
	}
}

/*! Decompose color image (BGRA) into R-G-B channels (float arrays)
    \param array image to decompose (BGRA)
    \param size image width times image height
    \param red red channel
    \param blue blue channel
    \param green green channel
    \param normalize normalize in [0,1]
    \todo Error checking.
 */
void see_decomposeBGRA(const unsigned char *array, size_t size, 
                       img *red, img *green, img *blue)
{
	if (red != 0 || red != NULL)
	{
		img r = (float*)malloc(size*sizeof(float));
		vDSP_vfltu8((unsigned char*)array+2,4,r,1,size);
		*red = r;
	}
	
	if (green != 0 || green != NULL)
	{
		img g = (float*)malloc(size*sizeof(float));
		vDSP_vfltu8((unsigned char*)array+1,4,g,1,size);
		*green = g;
	}
    
	if (blue != 0 || blue != NULL)
	{
		img b = (float*)malloc(size*sizeof(float));
		vDSP_vfltu8((unsigned char*)array,4,b,1,size);
		*blue = b;
	}
}

/*! Get intensity from RGB arrays
 \param r red component
 \param g green component
 \param b blue component
 \param size width*height
 \return intensity image
 \note <a>r</a>, <a>g</a> and <a>b</a> are assumed to have stride of 1
 */
img see_intensity(const img r, const img g, const img b, size_t size)
{
	float *intensity = (float*)calloc(size,sizeof(float));
	vDSP_vadd(r,1,g,1,intensity,1,size);
	vDSP_vadd(intensity,1,b,1,intensity,1,size);
	// use mean(r,g,b)
	cblas_sscal((int)size, 1.0/3.0, intensity, 1);
	return intensity;
}

/*! Compute color opponencies
	\param r red color channel
	\param g green color channel
	\param b blue color channel
	\param size image width times image height
	\param rg red-green opponency
	\param by blue-yellow opponency
 */
void see_opponency(const img r, const img g, const img b, size_t size, img *rg, img *by)
{
	if (!rg && !by) return;
	
	// find max(b,max(r,g)) 
	float *ma = (float *)malloc(size*sizeof(float));
	vDSP_vmax(r,1,g,1,ma,1,size);
	vDSP_vmax(ma,1,b,1,ma,1,size);

    // vDSP_vsub(A, i, B, j, C, k, ...) yields C = B - A.
    
	if (rg) // red-green
	{
		*rg = (float *)malloc(size*sizeof(float));
		vDSP_vsub(g, 1, r, 1, *rg, 1, size);
	}
	
	if (by) // blue-yellow
	{
		*by = (float *)malloc(size*sizeof(float));
		// find min(r,g) 
		float *mi = (float *)malloc(size*sizeof(float));
		vDSP_vmin(r, 1, g, 1, mi, 1, size);
		vDSP_vsub(mi, 1, b, 1, *by, 1, size);
		free(mi);
	}
	
	// avoid fluctuations by setting zeros at low luminance
	for (int p=0; p<size; p++)
	{
		if (ma[p] < 25.5)
		{
			if (rg) (*rg)[p] = 0.0f; 
            if (by) (*by)[p] = 0.0f;
		}
		else 
		{
			if (rg) (*rg)[p] = (*rg)[p]/ma[p];
			if (by) (*by)[p] = (*by)[p]/ma[p];
		}
	}
	
	// be good with the environment
	free(ma);
}

/*! Enlarge image by (integer) factor using bilinear interpolation
	\param desiredw desired width
	\param desuredh desired height
	\param image input image (single channel)
	\param width <a>image</a> width
	\param height <a>image</a> height
    \param neww new <a>image</a> width after enlarging
    \param newh new <a>image</a> height after enlarging
	\param pixelate if <a>true</a> inhibits interpolation 
 */
img see_enlargeWithDim(size_t desiredw, size_t desiredh,
                       const img& image, size_t width, size_t height,
                       size_t& neww, size_t& newh, bool pixelate)
{
	size_t factor = desiredw / width;                   //!< round mutiplicative factor
	assert(factor > 1 && factor == desiredh / height);  //!< aspect ratio should be consistent
	
	size_t scaledw = width * factor;                    //!< (round) new width
	size_t scaledh = height * factor;                   //!< (round) new height
	
	int extraW = factor-1 + (desiredw - scaledw);
	int extraH = factor-1 + (desiredh - scaledh);
	int extraT = extraH>>1;				// top replication
	int extraB = extraH - extraT;		// bottom replication
	int extraL = extraW>>1;				// top replication
	int extraR = extraW - extraL;		// bottom replication
	size_t w = desiredw - extraW;
	size_t h = desiredh - extraH;
	
	img enlarged = (float *)malloc(desiredw*desiredh*sizeof(float));
	img tmp = (float *)malloc(w*height*sizeof(float));
	float *ramph = (float *)malloc(w*sizeof(float));
	float *rampv = (float *)malloc(h*sizeof(float));

	float initval = 0;
	float increment = 1.0f/factor;
	vDSP_vramp(&initval, &increment, ramph, 1, w);
	vDSP_vramp(&initval, &increment, rampv, 1, h);
	
	if (pixelate)
	{
		int *rampih = (int*)malloc(w*sizeof(int));
		int *rampiv = (int*)malloc(h*sizeof(int));
		vDSP_vfix32(ramph, 1, rampih, 1, w);
		vDSP_vfix32(rampv, 1, rampiv, 1, h);
		vDSP_vflt32(rampih, 1, ramph, 1, w);
		vDSP_vflt32(rampiv, 1, rampv, 1, h);
		free(rampih); free(rampiv);
	}
    
	// horizontal interpolation
	for ( int row = 0; row < height; row++ )
	{
		vDSP_vlint(image + (row*width), ramph, 1, 
				   tmp + row, height, w, width);
	}
	
	// vertical interpolation
	for ( int col = 0; col < w; col++ ) 
	{
		vDSP_vlint(tmp + col*height, rampv, 1, 
				   enlarged + (col+extraL) + (extraT*desiredw), 
				   desiredw, h, height);
	}
	
	// replicate missing border
	float* addrtop = enlarged + extraT*desiredw + extraL;
	float* addrbottom = enlarged + ((extraT+h-1)*desiredw) + extraL;
	for ( int e = 0; e < extraB; e++ ) // top-bottom
	{
		if (e < extraT)
			cblas_scopy(w,addrtop, 1,
						enlarged + (e*desiredw) + extraL, 1);
		cblas_scopy(w,addrbottom, 1,
					addrbottom + (e+1)*desiredw, 1);
	}
	float* addrleft = enlarged + extraL;
	float* addrright = addrleft + w - 1;
	for ( int e = 0; e < extraR; e++ ) // left-right
	{
		if (e < extraL)
			cblas_scopy(desiredh,addrleft, desiredw,
						enlarged + e, desiredw);
		cblas_scopy(desiredh,addrright, desiredw,
					addrright + (e+1), desiredw);
	}
		
	free(tmp);
	free(ramph);
	free(rampv);
    
    neww = scaledw;
    newh = scaledh;
			   
	return enlarged;
}

/*! Enlarge image by (integer) factor using bilinear interpolation
    \param desiredw desired width
    \param desuredh desired height
    \param image input image (single channel)
    \param width <a>image</a> width
    \param height <a>image</a> height
    \param neww new <a>image</a> width after enlarging
    \param newh new <a>image</a> height after enlarging
 */
img see_enlarge(size_t desiredw, size_t desiredh, const img& image, 
                size_t width, size_t height)
{
	assert(desiredw > width && desiredh > height);
		
	img enlarged = (float *)malloc(desiredw*desiredh*sizeof(float));
	img tmp = (float *)malloc(desiredw*height*sizeof(float));
	float *ramph = (float *)malloc(desiredw*sizeof(float));
	float *rampv = (float *)malloc(desiredh*sizeof(float));
    
    // set up ramps for interpolation
    // (try to center the enlarged image instead of biasing towards a corner)
	float incrementW = (width-1.0)/desiredw; 
	float incrementH = (height-1.0)/desiredh;
	float initvalW = (width - 1.0 - incrementW*(desiredw-1))*0.5; 
	float initvalH = (height - 1.0 - incrementH*(desiredh-1))*0.5;
	vDSP_vramp(&initvalW, &incrementW, ramph, 1, desiredw);
	vDSP_vramp(&initvalH, &incrementH, rampv, 1, desiredh);
    
	// horizontal interpolation
	for ( int row = 0; row < height; row++ )
	{
		vDSP_vlint(image + (row*width), ramph, 1, 
				   tmp + row, height, desiredw, width);
	}
	
	// vertical interpolation
	for ( int row = 0; row < desiredw; row++ ) 
	{
		vDSP_vlint(tmp + row*height, rampv, 1, 
				   enlarged + row, desiredw, desiredh, height);
	}
	
	free(tmp);
	free(ramph);
	free(rampv);
    
	return enlarged;
}

/*! Shrink image to half size (this is equivalent to going from one step in a pyramid to the next)
    \param image data source (single channel)
    \param width image width
    \param height image height
    \param filter filter	
    \param length filter length
    \return reduced image to half of its original size
 */
img see_shrinkByHalf(const img image, size_t width, size_t height, const float *filter, size_t length)
{
    assert(image != 0 && length > 0 && filter != 0);
    
    size_t width2 = width >> 1;                             //!< (round) new image width
    size_t height2 = height >> 1;                           //!< (round) new image height
    
    size_t extraL = (length + 3) & 0xFFFFFFFC;              //!< extra pixels that need to be added to convolve with the filter
	size_t midExtraL = extraL >> 1;                         //!< half extraL
	size_t fullSize = (width + extraL)*(height + extraL);   //!< full size of the image (adding up the extraL pixels all around)
    int bytesPerRowSignal = (width + extraL);               //!< pixels to process per row
    
    img tmp = (float*)calloc(width2*height2, sizeof(float));//!< shrinked image 
    img signal = (float*)malloc(fullSize*sizeof(float));    //!< allocate space for the processed image with extra pixels
    img auxsig = (float*)malloc(fullSize*sizeof(float));    //!< auxiliary array
	
    float* filteraddr = (float*)filter+length-1;            //!< filter address (convolutions require to start from the end)
    
    // copy horizontally and extend vertically
    for ( int row=0; row < height; row++ )
    {
        cblas_scopy(width, image + (row*width), 1, 
                    signal + ((row+midExtraL)*bytesPerRowSignal) + midExtraL, 1);
        // copy extra pixels to apply the filter properly on the borders
        if (row < midExtraL)
        {
            cblas_scopy(width, image + ((midExtraL-row)*width), 1, 
                        signal + (row*bytesPerRowSignal) + midExtraL, 1);
            cblas_scopy(width, image + ((height-midExtraL+row)*width), 1, 
                        signal + ((height+extraL-1-row)*bytesPerRowSignal) + midExtraL, 1);
        }
    }
    
    
    // extend horizontally and filter vertically 
    for ( int col=0; col < width + midExtraL; col++ )
    {
        // copy extra pixels to apply the filter properly on the borders
        if (col < midExtraL)
        {
            cblas_scopy(height + extraL, signal + (extraL-1-col), bytesPerRowSignal, 
                        signal + col, bytesPerRowSignal);
            cblas_scopy(height + extraL, signal + (width-1-col), bytesPerRowSignal, 
                        signal + (width+midExtraL+col), bytesPerRowSignal);				
        }
        
        // convolve with the filter
        vDSP_conv(signal + col, bytesPerRowSignal, filteraddr, -1,
                  auxsig + col + midExtraL, bytesPerRowSignal, height, length);			
    }
    
    // filter horizontally, set result in auxiliary var
    for ( int row=0; row < height; row++ )
    {
        vDSP_conv(auxsig + (row*bytesPerRowSignal) + midExtraL, 1, filteraddr, -1,
                  auxsig + (row*width), 1, width, length);
    }
    
    
    // save subsampled image
    for ( int row=0; row < height2; row ++ )
    {
        cblas_scopy(width2, auxsig + (row*4*width2), 2, 
                    tmp + (row*width2), 1);
    }
    
    free(signal);	
	free(auxsig);
    
    return tmp;
}

/*! Shrinks RGBA data array to half size (a number of times) and outputs independent R-G-B results
    \param shrinkingTimes how many times to shrink? (e.g., use 1 to reduce image to half size)
    \param image data source (single channel)
    \param width initial image width (which will be modified to final image width)
    \param height initla image height (which will be modified to final image height)
    \param filter filter	
    \param length filter length
    \param r red image (or NULL if undesired)
    \param g green image (or NULL if undesired)
    \param b blue image (or NULL if undesired)
 
    The parameter <a>shrinkingTimes</a> is equivalent to offset when building pyramids. The image should 
    be shrinked at least once.
 
    The output parameters <a>r<a/>, <a>g</a> and <a>b</a> should not be initialized before hand or
    a memory leak will be produced. This function allocates the necessary space for the arrays.
 
    \note At least one of <a>r<a/>, <a>g</a>, <a>b</a> should not be NULL 
 */
void see_shrinkRGBA(unsigned int shrinkingTimes, const unsigned char *array, size_t& width, size_t& height,  
                    const float *filter, size_t length, img *r, img *g, img *b)
{
    assert(shrinkingTimes > 0);
    assert(r != NULL || r != 0 || g != NULL || g != 0 || b != NULL || b != 0);
    
    // decompose original image into R-G-B
    size_t size = width*height;
    see_decompose(array, size, r, g, b);
    
    img tmp = 0;
    
    for (int t = 0; t<shrinkingTimes; t++)
    {        
        // shrink red channel
        if (r != NULL || r != 0)
        {
            tmp = see_shrinkByHalf(*r, width, height, filter, length);
            free(*r);
            *r = tmp;
        }
        
        // shrink green channel
        if (g != NULL || g != 0)
        {
            tmp = see_shrinkByHalf(*g, width, height, filter, length);
            free(*g);
            *g = tmp;
        }
        
        // shrink blue channel
        if (b != NULL || b != 0)
        {
            tmp = see_shrinkByHalf(*b, width, height, filter, length);
            free(*b);
            *b = tmp;
        }
        
        // reduce size by half for next loop
        width = width >> 1;
        height = height >> 1;
    }    
}

#include <iostream>

/*! Extract a subblock from an image using subpixel computation
	\param image data source (single channel)
	\param width image width
	\param height image height
	\param x horizontal position of the center of the subblock
	\param y vertical position of the center of the subblock
	\param w subblock size is (2*w + 1) 
 
	\note The point (<a>x</a>,<a>y</a>) should be in the
	range [w,width-w]x[w,height-w], and <a>w</a> should be positive
 */
img see_subpixBlock(const img image, size_t width, size_t height, 
					float x, float y, size_t w)
{
	assert(w > 0);
	assert(x > w && y > w && x < width - w -1 && y < height - w - 1);
	
	int winsize = 2*w + 1;
	img subblock = (float *)malloc(winsize*winsize*sizeof(float));
	
	float increment = 1;
	float *ramp = (float *)malloc(winsize*sizeof(float));
	
	// horizontal interpolation
	float initval = x - w;
	vDSP_vramp(&initval, &increment, ramp, 1, winsize);

	int toprow = floor(y - w);// if (toprow < 0) toprow = 0;
	int botrow = (ceil(y) == y ? y + w + 1 : ceil(y + w)); // if (botrow > height) botrow = height;
	int rowstocopy =  botrow - toprow + 1; //8
	
	img tmpim = (float *)malloc(winsize*rowstocopy*sizeof(float));
	
	for ( int row = toprow; row < toprow + rowstocopy; row++ )
	{
		vDSP_vlint(image + row*width, ramp, 1, 
				   tmpim + (row - toprow), rowstocopy, 
				   winsize, width);
	}
	
	// vertical interpolation
	initval = y - w - toprow;
	vDSP_vramp(&initval, &increment, ramp, 1, winsize);
		
	for ( int col = 0; col < winsize; col++ )
	{
		vDSP_vlint(tmpim + rowstocopy*col, ramp, 1, 
				   subblock + col, winsize, winsize, rowstocopy);
	}
	
	// seg fault here
	free(tmpim);
	free(ramp);
	
	return subblock;
}

img see_extractWindow(size_t w, size_t h, img image, const Rectangle& rect, 
                      unsigned int margin, Rectangle* windowRect)
{
    if (image == 0 || image == NULL || *image == 0) 
        return 0;
    
    float left = rect.left() - margin;
    float top = rect.top() - margin;
    float right = rect.right() + margin;
    float bottom = rect.bottom() + margin;
    if (left < 0 || top < 0 || right >= w-2 || bottom >= h-2){
        std::cout << "Extract window failed with margin of " << margin << " for " << rect << std::endl; 
        return 0;
    }
    
//    std::cout << "l=" << left << " t=" << top << " r=" << right << " b=" << bottom;
    
    float width = right - left;
    float height = bottom - top;
    
    vDSP_Length windowWRound = roundf(width);
    vDSP_Length windowHRound = roundf(height);
    size_t length = windowWRound*windowHRound;
    
    img window = (float *)calloc(length,sizeof(float));
    
    // horizontal interpolation    
    float *ramp = (float *)malloc(sizeof(float)*windowWRound);
    float increment = 1; 
    vDSP_vramp(&left, &increment, ramp, 1, windowWRound);
    
    int toprow = floor(top);
    int botrow = ceil(bottom); //(ceil(bottom) == bottom ? bottom + 1 : bottom);
    int rowstocopy = botrow - toprow + 1;
    
//    std::cout << " toprow=" << toprow << " botrow=" << botrow << " rowstocopy=" << rowstocopy << std::flush;

    
    img tmpIm = (float *)malloc(sizeof(float)*rowstocopy*windowWRound);
    
    for (int r=toprow; r < toprow + rowstocopy; r++)
    {
        vDSP_vlint(image + r*w, ramp, 1, 
                   tmpIm + (r - toprow), rowstocopy, windowWRound, w);
    }
    free(ramp);
    
    // vertical interpolation
    ramp = (float *)malloc(sizeof(float)*windowHRound);
    float initval = top - toprow;
    vDSP_vramp(&initval, &increment, ramp, 1, windowHRound);
    
//    std::cout << " vertinterp for initval=" << initval << std::flush;

    
    for (int c=0; c < windowWRound; c++)
    {
        vDSP_vlint(tmpIm + rowstocopy*c, ramp, 1, 
                   window + c, windowWRound, windowHRound, rowstocopy);
    }
    free(ramp);
    free(tmpIm);
    
//    std::cout << std::endl;
    
    if (windowRect != 0) 
    { 
        windowRect->origin = Vector2(left, top);
        windowRect->size = Vector2(windowWRound, windowHRound);
    }
    
    return window;    
}

/**
    Add zero margin around image
    \param w image width
    \param h image height
    \param image image to be extended along the horizontal and vertical dimensions
    \param newW new image width
    \param newH new image Height
    \return extended image with zero margin
 */
img see_addMargin(size_t w, size_t h, img image, unsigned int margin, size_t *newW, size_t *newH)
{
    size_t newHeight = h + 2*margin;
    size_t newWidth = w + 2*margin;
    
    img extendedImage = (float *) malloc(newWidth*newHeight*sizeof(float));
    
    for (int r=0; r<h; r++)
    { cblas_scopy((int)w, image+r*w, 1, extendedImage + margin + (r + margin)*newWidth, 1); }
    
    if (newW != NULL) *newW = newWidth;
    if (newH != NULL) *newH = newHeight;
    
    return extendedImage;
}

#pragma mark FILTERING

// \todo bytesperrow are not used. remove in future calls...
img see_convolveHor(const img image, size_t width, size_t height, size_t bytesPerRow, 
                    const float *filter, size_t lenFilter, Vector2* size, unsigned int emptyMargin)
{    
    size_t validW = width - (lenFilter - 1);
    size_t newW = validW + 2*emptyMargin; size_t newH = height + 2*emptyMargin;
    //assert(newW == width);
    
    size_t newLength = newW * newH;
    img convolved = (float*)calloc(newLength, sizeof(float)); 
    
    const float *filterAddr = filter + lenFilter - 1;
    
    for (int r=0; r<height; r++)
    {
        vDSP_conv(image + r*width, 1, filterAddr, -1,
                  convolved + emptyMargin*newW + emptyMargin + r*newW, 1, validW, lenFilter);	
    }
    
    if (size != 0) {size->x = newW; size->y = newH;}
    
    return convolved;
}

// \todo bytesperrow are not used. remove in future calls...
img see_convolveVer(const img image, size_t width, size_t height, size_t bytesPerRow, 
                    const float *filter, size_t lenFilter, Vector2* size, unsigned int emptyMargin)
{
    size_t validH = height - (lenFilter - 1);
    size_t newW = width + 2*emptyMargin; size_t newH = validH + 2*emptyMargin;
    //assert(newH == height); 
    
    size_t newLength = newW * newH;
    img convolved = (float*)calloc(newLength,sizeof(float)); 
    
    const float *filterAddr = filter + lenFilter - 1;
    
    for (int c=0; c<width; c++)
    {
        vDSP_conv(image + c, bytesPerRow, filterAddr, -1,
                  convolved + emptyMargin*newW + emptyMargin + c, newW, validH, lenFilter);	
    }
    
    if (size != 0) {size->x = newW; size->y = newH;}
    
    return convolved;
}

#pragma mark PYRAMID

/*! Decompose image into channels and build pyramid
	\param image input image
	\param width image width
	\param height image height
	\param lev number of pyramid levels
	\param pyramid pyramid
	\param filter filter	
	\param length filter length
	\param offset how many levels to ignore before pushing image into pyramid
	\note if offset is zero, the first image of the pyramid points to <a>image</a>
 */
void see_pyramid(const img image, size_t width, size_t height, size_t lev,
				 pyr& pyramid, const float *filter, size_t length, int offset)
{
	assert(image != 0 && lev > 0 && 
		   width > 1<<(int(lev)) && height > 1<<(int(lev)) &&
		   length > 0 && filter != 0);
	
	// decompose image into float arrays
	//size_t size = width*height;
	    
    size_t midExtraL = floorf(length*0.5);                  //!< extra pixels needed per size to colvolve with the filter (half extraL)
	size_t extraL = midExtraL*2;                            //!< extra pixels needed per dimension
	
	img signal = (float*)calloc(width*(height + extraL),sizeof(float));    //!< allocate space for the processed image with extra pixels
	img auxsig = (float*)calloc((width + extraL)*height,sizeof(float));    //!< auxiliary array
	const float* filteraddr = filter + length - 1;          //!< filter address (convolutions require to start from the end)
	
    size_t w = 0, h = 0;                                    //!< temporary dimensions
    int bytesPerRowAux;                                     //!< elements per row in signal

    img im = image;                                         //!< pointer to previous pyramid level
	
	// set up pyramid...
	int totlev = lev + offset;                              //!< total number of pyramid levels to process
	if (offset == 0)
	{	// first image of the pyramid points to <a>image</a>
        pyramid.push_back(image);
//        std::cout << "setting up pyr lev(0) of " << width << "x" << height << std::endl; 
	}
	// build pyramid levels from 1 up to totlev
	for (int l=1; l<totlev; l++)				
	{			
        w = width; h = height;
        if (w % 2 != 0) w -= 1;                         //!< assure width is multiple of 2
        if (h % 2 != 0) h -= 1;                         //!< assure height is multiple of 2
		bytesPerRowAux = (w + extraL);               //!< pixels to process per row
        
		// copy horizontally and replicate top-bottom borders
		for ( int row=0; row < h; row++ )
		{
			cblas_scopy(w, im + (row*width), 1, 
						signal + (row+midExtraL)*w, 1);
            // copy extra pixels
			if (row < midExtraL)
			{
				cblas_scopy(w, im, 1, 
							signal + row*w, 1);
				cblas_scopy(w, im + (height-1)*width, 1, 
							signal + (row+h+midExtraL)*w, 1);
			}
		}
		
		// filter vertically 
		for ( int col=0; col < w; col++ )
		{			
            // convolve with the filter
			vDSP_conv(signal + col, w, filteraddr, -1,
					  auxsig + col + midExtraL, bytesPerRowAux, h, length);			
		}
        
        // replicate left-right borders to apply the filter properly on the sides
        for (int col=0; col < midExtraL; col++)
        {
            cblas_scopy(height, auxsig + midExtraL, bytesPerRowAux, 
                        auxsig + col, bytesPerRowAux);
            cblas_scopy(height, auxsig + midExtraL + w - 1, bytesPerRowAux, 
                        auxsig + midExtraL + w + col, bytesPerRowAux);	            
        }
        
		// filter horizontally, set result in auxiliary var
		for ( int row=0; row < h; row++ )
		{
			vDSP_conv(auxsig + (row*bytesPerRowAux) + midExtraL, 1, filteraddr, -1,
					  signal + (row*w), 1, w, length);
		}
		
		// new image dimensions
		width = w >> 1;
		height = h >> 1;
		
        // save subsampled image
        img tmp = (float*)calloc(width*height, sizeof(float)); 
        for ( int row=0; row < height; row++ )
        {
            cblas_scopy(width, signal + row*2*w, 2, tmp + (row*width), 1);
        }
        
        // save new image
		if (l >= offset) 
        {
            pyramid.push_back(tmp);
//            std::cout << "setting up pyr lev("<< l <<") of " << width << "x" << height << std::endl; 
        }
        
        // free previous image if it's not the original and it's not in the pyramid
        if (l > 1 && l <= offset) free(im);
        
        // get ready to process new image
        im = tmp;
	}
	
	free(signal);	
	free(auxsig);

}

/*! Free pyramid 
	\param pyramid pyramid
 */
void see_freePyr(pyr& pyramid)
{
	if (!pyramid.empty())
	{
		for (int l=0; l<pyramid.size(); l++)
		{
			float *im = pyramid.at(l); 
			free(im);
		}
		pyramid.clear();
	}
}

/*! Free pyramid up to base image (do not release original image)
    \param pyramid pyramid
 */
void see_freePyrUpToBase(pyr& pyramid)
{
    if (!pyramid.empty())
	{
        int nlev = pyramid.size();
		for (int l=nlev-1; l>0; l--)
		{
			float *im = pyramid.back(); free(im);
            pyramid.pop_back();
		}
	}
}

