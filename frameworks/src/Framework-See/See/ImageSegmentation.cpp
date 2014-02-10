//
//  ImageSegmentation.m
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

#include <assert.h>
#include <Accelerate/Accelerate.h>
#include "ImageSegmentation.h"
#include "ImageConversion.h"

#pragma mark PRIVATE PROTOTYPES

bool see_tracer( int &point, int &row, int &col, const img image, size_t w, size_t h, 
                img labels, int label, char& contourPoint);
void see_contourTracing( const img image, size_t w, size_t h, 
                        img labels, int row, int col, int point,
                        int label, char neighbor );


#pragma mark THRESHOLDING

/*! Threshold image with optional scaling (in place)
	\param image input image
	\param size image width times image height
	\param threshold threshold
	\param scale optional scaling before binarization
 
	This function first scales the image to [0,<a>scale</a>] 
	using <a>scaleTo()</a> if <a>scale</a> is not zero. Then, 
	the image thresholded, setting zeros in all pixels with a 
	value less than <a>threshold</a>.
 
	\note scale should be zero or positive
 */
void see_threshold(img *image, size_t size, float threshold, float scale)
{
	assert( scale >= 0.0 );
	
	if ( scale != THR_NO_SCALING ) 
	{
		// scale image if scale > 0
		see_scaleTo(*image, size, scale);
	}
	
	vDSP_vthres(*image, 1, &threshold, *image, 1, size);
	
}


#pragma mark BLOBS

// pixel/label type
#define CC_BLANK	 0.0f			//!< empty pixel

// neighbors ordering
#define CC_NEIGHBOR_RIGHT		0	//!< right neighbor
#define CC_NEIGHBOR_DOWNRIGHT	1	//!< lower-right neighbor
#define CC_NEIGHBOR_DOWN		2	//!< lower neighbor
#define CC_NEIGHBOR_DOWNLEFT	3	//!< lower-left neighbor
#define CC_NEIGHBOR_LEFT		4	//!< left neighbor
#define CC_NEIGHBOR_LEFTUP		5	//!< upper-left neighbor
#define CC_NEIGHBOR_UP			6	//!< upper neighbor
#define CC_NEIGHBOR_UPRIGHT		7	//!< upper-right neighbor

/*! Find next point in contour
	\param point position along image array (initial point as input, prev point as output)
	\param row <a>point</a> row
	\param col <a>point</a> col
	\param image binary image
	\param w <a>image</a> width
	\param h <a>image</a> height 
	\param labels labels Mat
	\param label contour label
	\param contourPoint previous (input) and future contour point (output)
	\return true if ini point is not isolated
 
	<a>tracer()</a> takes charge of marking surrounding contour points.
 
	<a>tracer()</a> starts looking for the next contour point from 
	<a>contourPoint</a>. After the routine finishes, the position of 
	<a>next</a> is returned in <a>contourPoint</a>. 
 
	\note <a>tracer</a> is a subroutine used by <a>contourTracing</a> to
	trace (external or internal) contours along a binary image.
 */
bool see_tracer( int &point, int &row, int &col, const img image, size_t w, size_t h, 
				 img labels, int label, char& contourPoint)
{
	char initialContourPoint = contourPoint;
	bool gotNextPoint = false;
	bool outOfBounds = false;
	int nextPoint = 0;
	
	do { // check for next contour point in neighboring pixels
		
		switch (contourPoint) {
			case CC_NEIGHBOR_RIGHT: // point (col + 1, row )
				outOfBounds = (col + 1) == w; 
				nextPoint = point + 1;
				break;
			case CC_NEIGHBOR_DOWNRIGHT: // point (col + 1, row + 1)
				outOfBounds = ((row + 1) == h) || ((col + 1) == w); 
				nextPoint = point + 1 + w;
				break;
			case CC_NEIGHBOR_DOWN: // point (col, row + 1)
				outOfBounds = ((row + 1) == h);
				nextPoint = point + w;
				break;
			case CC_NEIGHBOR_DOWNLEFT: // point (col + 1, row - 1)
				outOfBounds = ((row + 1) == h) || ((col - 1) == -1);
				nextPoint = point + w - 1;
				break;
			case CC_NEIGHBOR_LEFT: // point (col, row - 1)
				outOfBounds = (col - 1) == -1;
				nextPoint = point - 1;
				break;
			case CC_NEIGHBOR_LEFTUP: // point (col - 1, row - 1)
				outOfBounds = ((row - 1) == -1) || ((col - 1) == -1);
				nextPoint = point - w - 1;
				break;
			case CC_NEIGHBOR_UP: // point (col, row - 1)
				outOfBounds = (row - 1) == -1;
				nextPoint = point - w;
				break;
			case CC_NEIGHBOR_UPRIGHT: // point (col + 1, row - 1)
				outOfBounds = ((row - 1) == -1) || ((col + 1) == w);
				nextPoint = point - w + 1;
				break;
		}
		
		if ( !outOfBounds )
		{ 
			if (image[nextPoint] != CC_BLANK) {
				gotNextPoint = true;
				labels[nextPoint] = (float)label;
			} else {
				// mark surrounding
				assert( labels[nextPoint] == CC_UNLABELED || labels[nextPoint] == CC_SURROUNDING );
				labels[nextPoint] = CC_SURROUNDING;
			}	
		}
		
		contourPoint = (contourPoint + 1) % 8;
		
	} while ( !gotNextPoint && contourPoint != initialContourPoint );

	// set nextCol and nextRow after all these so we don't do 
	// way more assignments than necessary!
	switch (contourPoint) {
		case CC_NEIGHBOR_RIGHT: // prev UPRIGHT
			col = col + 1; row = row - 1;
			break;
		case CC_NEIGHBOR_DOWNRIGHT: // prev RIGHT
			col = col + 1; 
			break;
		case CC_NEIGHBOR_DOWN: // prev DOWNRIGHT
			col = col + 1; row = row + 1;
			break;
		case CC_NEIGHBOR_DOWNLEFT: // prev DOWN
			row = row + 1;
			break;
		case CC_NEIGHBOR_LEFT: // prev DOWNLEFT
			col = col - 1; row = row + 1;
			break;
		case CC_NEIGHBOR_LEFTUP: /// prev LEFT
			col = col - 1; 
			break;
		case CC_NEIGHBOR_UP: // prev LEFTUP
			col = col - 1; row = row - 1;
			break;
		case CC_NEIGHBOR_UPRIGHT: // prev UP
			row = row - 1;
			break;
	}
	point = nextPoint;
	
	// add 1 to contourPoint so next call to trace starts appropriately
	contourPoint = (contourPoint + 5) % 8;
	
	return gotNextPoint;	
}

/*! Finds and labels internal or external contour from a starting point
	\param image binary image
	\param w <a>image</a> width
	\param h <a>image</a> height
	\param labels labels Mat
	\param row initial row
	\param col initial col
	\param point position along image array (row*width + col)
	\param label label to mark with
	\param neighbor starting neighbor
 */
void see_contourTracing( const img image, size_t w, size_t h, 
						 img labels, int row, int col, int point,
						 int label, char neighbor )
{
	int nextPoint = point, nextRow = row, nextCol = col, currentPoint;
	bool justPassedIniPoint = true;
	
	assert(image[point] != CC_BLANK);
	
	// tracer returns false if nextPoint is isolated
	if (!see_tracer( nextPoint, nextRow, nextCol, image, w, h, labels, label, 
					 neighbor )) return;
	currentPoint = nextPoint;
	
	for (;;){
		
		see_tracer( currentPoint, nextRow, nextCol, image, w, h, labels, label, 
				    neighbor );
	
		// stop if we looped along contour
		if (justPassedIniPoint && currentPoint == nextPoint) break;
		
		if (currentPoint == point) justPassedIniPoint = true;
		else justPassedIniPoint = false;
		
	}
}

/*! Label blobs (8-connected components) in binary image
	\param image binary image
	\param w <a>image</a> width
	\param h <a>image</a> height
	\param nlabels number of blobs found
	\return labels matrix of connected labels
 
	Finds connected components using F. Chang, C-J Chen, and C-J Lu
	"A Linear-Time Component-Labeling Algorithm Using Contour Tracing Technique".
 
	 \note <a>image</a> is assumed to have black background and white foreground (blobs). 
	 Blobs are labeled from 1 to nlabels.
 */
img see_labelBlobs(const img image, size_t w, size_t h, int &nlabels)
{
	size_t size = w*h;
	img labels = (float*)calloc(size,sizeof(float));
	nlabels = 0;
	
	int lastRow = h - 1;
	
	int row = 0, col = 0, p = 0; 
	for ( row = 0; row < h; row++ )
	{
		for ( col = 0; col < w; col++ )
		{
			float c = image[p];         // current pixel
			float& l = labels[p];		// current label
			
			if ( c == CC_BLANK ) { p++; continue;}	// nothing to do with empty pixel
			
			if ( l == CC_UNLABELED &&
				 ( row == 0 || image[p-w] == CC_BLANK ))
			{
				// external contour
				nlabels++;
				l = (float)nlabels;
				see_contourTracing(image, w, h, labels, row, col, p, l, CC_NEIGHBOR_UPRIGHT);
			}
			else if (( row == lastRow && l == CC_UNLABELED ) ||
//					 ( labels[p+w] == CC_UNLABELED && image[p+w] == CC_BLANK ))
					 ( row != lastRow && labels[p+w] == CC_UNLABELED && image[p+w] == CC_BLANK ))
			{
				// internal contour
				if ( l == CC_UNLABELED )
				{
					// use label of left neighbor
					l = labels[p-1];
				}
				
				see_contourTracing(image, w, h, labels, row, col, p, l, CC_NEIGHBOR_DOWNLEFT);
			}
			else
			{
				// c is not a contour point
				// we simply copy the label of the neighbor
				if ( l == CC_UNLABELED )
					l = labels[p-1];
			}
					 
			p++;
		}
	}
	
	// forget about surrounding label...
	// this operation could be accelerated by separating the surrounding
	// flags to another array, and then passing this array to all other 
	// functions in order to maintain consistency
	float t = 0.0f;
	vDSP_vthres(labels, 1, &t, labels, 1, size);
	
	return labels;
}

/*! Create r-g-b representation of grouped blobs
	\param labels labels matrix
	\param size number of elements in <a>labels</a>
	\param nlabels number of labels
	\param red red channel of color representation
	\param green red channel of color representation
	\param blue red channel of color representation
	
	This function is only for visualization purposes.
	Coloring is not optimized with vector operations.
 
	\note <a>labels</a> is assumed to have stride of 1.  
 */
void see_colorBlobs(const img labels, size_t size, int nlabels, img *red, img *green, img *blue)
{	
	*red = (float *)malloc(size*sizeof(float));
	*green = (float *)malloc(size*sizeof(float));
	*blue = (float *)malloc(size*sizeof(float));
	
	for ( int p=0; p < size; p++ )
	{
		float label = labels[p];
			
		if ( label != CC_UNLABELED ){
			// select color randomly
			(*red)[p] = float(int((label*1000*255/nlabels)+10)%256);
			(*green)[p] = float(int((label*40*255/nlabels)+70)%256);
			(*blue)[p] = float(int((label*75*255/nlabels)+140)%256);
		} 
		
	}
}

/*! Highlight specified blob
	\param labels labels matrix
	\param size <a>labels</a> size
	\param label blob label
	\param highlight image where to highlight
	\param val highlight value
 */
void see_highlightBlob(const img labels, size_t size, 
					   float label, img *highlight, float val)
{
	assert( highlight != 0 );
	
	if ( *highlight == 0 )
	{
		*highlight = (float *)malloc(size*sizeof(float));
		vDSP_vclr(*highlight,1,size);
	}
	
	if (label != 0)
	{
		for ( int pos = 0; pos < size; pos++ )
		{
			if ( labels[pos] == label )
			{
				(*highlight)[pos] = val;
			}
		}
	}
}

/*! Select most meaningful blob
	\param image segmented image
	\param size <a>image</a> width times <a>image</a> height
	\param labels labels matrix (same size as <a>image</a>)
	\param nlabels number of labels in <a>labels</a>
	\param discretize discretize image to [0,255] 
	\param entropy array with entropy per label
	\param sumval array with sum of pixel values per label (number of samples per label)
	\param numbins number of bins per label
	\param discimg discretized image
	\return label with highest relative entropy
 
	\note <a>selectMostMeaningfulBlob()</a> returns 0 if <a>nlabels</a> is zero,
	or if there aren't any meaningful regions to pick from. Otherwise, 
	it returns an integer (though packed as a float for convenience).
 */
float see_selectMostMeaningfulBlob( const img image, size_t size, const img labels, int nlabels, 
								    bool discretize, float **entropy, int **sumval, int **numbins, 
								    img *discimg)
{
	float *e = (float *)malloc(nlabels*sizeof(float));
	int *s = (int*)calloc(nlabels, sizeof(int));
	int *n = (int*)calloc(nlabels, sizeof(int));
	int M = 0, selected = 0, l;
	float label, r, p, t, maxe = 0;
	
	img discrete = 0;
	if (discretize)
	{
		discrete = (float *)malloc(size*sizeof(float));
		cblas_scopy(size, image, 1, discrete, 1);
		see_scaleTo(discrete, size, 255.0);
	}
	else 
	{
		discrete = image;
	}
	
	// compute statistics per label
	for ( int pos=0; pos < size; pos++ )
	{
		label = labels[pos];
		float nsamples = discrete[pos];
		if ( label != CC_UNLABELED)
		{
			l = (int)label - 1;
			M += (int)nsamples;				// total number of samples
			s[l] += (int)nsamples;	// number of samples per label
			n[l] += 1;				// number of bins per label
		}
	}
	
	// compute meaningfulness threshold assuming uniform distribution
	t = (log((float)size*(size + 1.0)) - log(2.0))/M;
	
	// compute blobs' relative entropy
	for ( l = 0; l < nlabels; l++ )
	{
		p = n[l] * 1.0 / size;	// expected number of samples per bin
		r = s[l] * 1.0 / M;		// expected proportion of samples
		if ( r <= p )
		{
			e[l] = 0;
		}
		else 
		{
			e[l] = (r*(log(r)/log(2) - log(p)/log(2)) + 
						(1-r)*(log(1-r)/log(2) - log(1-p)/log(2)));
		}
		if ( e[l] > t )
		{
			// region is meaningful
			if ( selected == 0 || maxe < e[l] )
			{
				// set most meaningful region (so far)
				selected = l + 1;
				maxe = e[l];
			}
		}
	}
	
	// be good with the environment
	if (entropy) *entropy = e; else free(e);
	if (sumval) *sumval = s; else free(s);
	if (numbins) *numbins = n; else free(n);
	
	if (discimg) *discimg = discrete; else if (discretize) free(discrete);
	
	return selected;
}

/*! Compute (spatial) weighted mean of a particular blob
	\param image thresholded image
	\param w <a>image</a> width
	\param h <a>image</a> height
	\param labels labels matrix (same size of <a>image</a>)
	\param label blob label (integer packed as a float)
	\param x horizontal component of weighted mean
	\param y vertical component of weighted mean
	
	\note <a>label</a> must be a valid identifier in <a>labels</a>.
 */
void see_weightedMean( const img image, size_t w, size_t h, const img labels, 
					   float label, float &x, float &y)
{
	if (!label) // no label was selected (no region is meaningful!)
	{
		x = w/2.0;
		y = h/2.0;
		return;
	}
	
	int pos = 0;
	float sum = 0.0;
	x = 0.0; y = 0.0;
	
	for ( int row = 0; row < h; row++ )
	{
		for ( int col=0; col < w; col++ )
		{
			if ( labels[pos] == label )
			{
				x += image[pos]*col;
				y += image[pos]*row;
				sum += image[pos];
			}
			pos++;
		}
	}
	x /= sum;
	y /= sum;
}

