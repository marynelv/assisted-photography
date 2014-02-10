//
//  ImageMotion.cpp
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

#include "ImageMotion.h"
#include "ImageConversion.h"
#include <Accelerate/Accelerate.h>
#include <assert.h>

//#define PERFORM_SANITY_CHECKS

#pragma mark Template Matching

//img see_extractWindow(size_t w, size_t h, img image, const Rectangle& rect, 
//                      unsigned int margin, Rectangle* windowRect)
//{
//    float left = rect.left() - margin;
//    float top = rect.top() - margin;
//    float right = rect.right() + margin;
//    float bottom = rect.bottom() + margin;
//    if (left < 0 || top < 0 || right >= w-2 || bottom >= h-2)
//        return 0;
//    
//    float width = right - left;
//    float height = bottom - top;
//    
//    vDSP_Length windowWRound = roundf(width);
//    vDSP_Length windowHRound = roundf(height);
//    size_t length = windowWRound*windowHRound;
//    
//    img window = (float *)calloc(length,sizeof(float));
//    
//    // horizontal interpolation    
//    float *ramp = (float *)malloc(sizeof(float)*windowWRound);
//    float increment = 1; 
//    vDSP_vramp(&left, &increment, ramp, 1, windowWRound);
//    
//    int toprow = floor(top);
//    int botrow = (ceil(bottom) == bottom ? bottom + 1 : bottom);
//    int rowstocopy = botrow - toprow + 1;
//    
//    img tmpIm = (float *)malloc(sizeof(float)*rowstocopy*windowWRound);
//    
//    for (int r=toprow; r < toprow + rowstocopy; r++)
//    {
//        vDSP_vlint(image + r*w, ramp, 1, 
//                   tmpIm + (r - toprow), rowstocopy, windowWRound, w);
//    }
//    free(ramp);
//    
//    // vertical interpolation
//    ramp = (float *)malloc(sizeof(float)*windowHRound);
//    float initval = top - toprow;
//    vDSP_vramp(&initval, &increment, ramp, 1, windowHRound);
//    
//    for (int c=0; c < windowHRound; c++)
//    {
//        vDSP_vlint(tmpIm + rowstocopy*c, ramp, 1, 
//                   window + c, windowWRound, windowHRound, rowstocopy);
//    }
//    free(ramp);
//    free(tmpIm);
//        
//    if (windowRect != 0) *windowRect = Rectangle(left, top, right, bottom);
//    
//    return window;    
//}

/** Track template window in image
    \param width prev,next images width
    \param height prev,next images height
    \param prevIm normalized previous image
    \param nextIm normalized next image
    \param templateBox template in prevIm (should fit inside the image)
    \param motion template motion from prevIm to nextIm
    \param epsi motion update threshold to stop looking for the template
    \return tracking result (ok, template outside bounds or failure)
 
    If <a>motion</a> is not (0,0), it's values are used as initial 
    displacement for the tracking procedure.
 
    LKTemplateMatching may return one of the following codes:
    TRACKING_OK - tracking processed finished without inconvenients
    TRACKING_STOPPEDBYBOUNDS - tracking stopped because tamplate went out of bounds
    TRACKING_OUTSIDEBOUNDS - template is outside bounds
    TRACKING_EMPTY - template is seriously dark
 
    \note The template should lie inside the box [3 3 width-4 height-4] in prevIm, so that
    image gradients can be computed correctly
 */
TRACKINGRESULT see_LKTemplateMatching(size_t width, size_t height, img prevIm, img nextIm,
                                      Rectangle templateBox, Vector2 &motion, Vector2 *leftMotion, float *ssd, 
                                      float epsi, int maxIter, img* gradX, img* gradY, 
                                      img *tmpl, Rectangle* tmplEnlargedBox,
                                      img *trackedEnlarged, Rectangle* trackedEnlargedBox)
{
    unsigned int margin = floor(FSIZE_GAUSDERIV7/2);
//    if (templateBox.left() < margin || templateBox.top() < margin || 
//           templateBox.right() >= width - 1 - margin || templateBox.bottom() >= height - 1 - margin)
//    {
//        return TRACKING_OUTSIDEBOUNDS;
//    }
    
    // find template
    Rectangle enlargedBox;
    img tempIm =  see_extractWindow(width, height, prevIm, templateBox, margin, &enlargedBox);
//    std::cout << "templateBox " << templateBox << " enlargedBox" << enlargedBox << std::endl;

    if (tempIm == 0) 
        return TRACKING_OUTSIDEBOUNDS;
    int tempLength = (int)enlargedBox.width() * enlargedBox.height();

//    // check if template window has content to track
//    float sumTempIm = 0;
//    vDSP_sve (tempIm, 1, &sumTempIm, tempLength);
//    if (sumTempIm < tempLength*0.05) { 
//        free(tempIm); 
//#ifdef PERFORM_SANITY_CHECKS
//        std::cout << sumTempIm << " < " << tempLength*0.05 
//        << " for tempLength = " << tempLength << std::endl;
//#endif
//        return TRACKING_EMPTY; 
//    }
    
    
    // estimate the gradient of the template
    Vector2 gxSize(0,0), gySize(0,0);
    int tempWRound = int(roundf(templateBox.width())), tempHRound = int(roundf(templateBox.height()));
    int enlargedWRound = int(roundf(enlargedBox.width())), enlargedHRound = int(roundf(enlargedBox.height()));
    img gx = see_convolveHor(tempIm + margin*enlargedWRound, enlargedWRound, tempHRound, enlargedWRound, 
                             FILTER_GAUSDERIV7, FSIZE_GAUSDERIV7, &gxSize, margin);
    img gy = see_convolveVer(tempIm + margin, tempWRound, enlargedHRound, enlargedWRound, 
                             FILTER_GAUSDERIV7, FSIZE_GAUSDERIV7, &gySize, margin);
    
#ifdef PERFORM_SANITY_CHECKS
    if (!(roundf(gxSize.x) == roundf(enlargedBox.size.x) &&
          roundf(gxSize.y) == roundf(enlargedBox.size.y) &&
          roundf(gySize.x) == roundf(enlargedBox.size.x) &&
          roundf(gySize.y) == roundf(enlargedBox.size.y)))
    {
        std::cout << "ERROR" << std::endl;
    }
    assert(roundf(gxSize.x) == roundf(enlargedBox.size.x) &&
           roundf(gxSize.y) == roundf(enlargedBox.size.y) &&
           roundf(gySize.x) == roundf(enlargedBox.size.x) &&
           roundf(gySize.y) == roundf(enlargedBox.size.y));
#endif
    
    // compute the Hessian matrix
    // H = [Hxx Hxy; Hyx Hyy] = [gx gy]'*[gx gy]
    float Hxx = 0, Hxy = 0, Hyx = 0, Hyy = 0;
    vDSP_dotpr(gx, 1, gx, 1, &Hxx, tempLength);
    vDSP_dotpr(gx, 1, gy, 1, &Hxy, tempLength);
    vDSP_dotpr(gy, 1, gx, 1, &Hyx, tempLength);
    vDSP_dotpr(gy, 1, gy, 1, &Hyy, tempLength);
    // find H^{-1}
    float detH = Hxx*Hyy - Hxy*Hyx;
    float invH[2][2] = {{ Hyy/detH, -Hxy/detH},
                        {-Hyx/detH,  Hxx/detH}};
    // we will end up using -inv(H)*[gx gy]' as constant update step 

    // track as an optimization problem: we just seek to minimize the error
    Vector2 delta(0,0); //motion = Vector2(0,0);
    Rectangle matchBox = templateBox, enlargedMatchBox;
    img match = 0;
    img diff = (float *)calloc(sizeof(float),tempLength);
    TRACKINGRESULT result = TRACKING_OK;
    int iter = 0;
    do {
        
        // update motion 
        motion = motion + delta;
        
        // update match
        matchBox.origin = matchBox.origin + delta;
        if (match != 0) {free(match); match = 0;}
        match = see_extractWindow(width, height, nextIm, matchBox, margin, &enlargedMatchBox);
        
        // stop if we reached a bound
        if (match == 0) {
            std::cout << "OOB with " << matchBox << " on image of " << width << "x" << height << std::endl;
            motion = motion - delta;
            result = TRACKING_STOPPEDBYBOUNDS; break;
        } 
        
        // subtract enlarged match box and template
        // vsub returns diff = match - tempIm
        vDSP_vsub(tempIm, 1, match, 1, diff, 1, tempLength);
//        vDSP_vsub(match, 1, tempIm, 1,  diff, 1, tempLength);
//#ifdef PERFORM_SANITY_CHECKS
//        float sumDiff = 0;
//        vDSP_sve (diff, 1, &sumDiff, tempLength);
//        std::cout << "SumDiff = " << sumDiff << " | ";
//#endif
        
        // update delta
        float dx = 0, dy = 0;
        vDSP_dotpr(gx, 1, diff, 1, &dx, tempLength);
        vDSP_dotpr(gy, 1, diff, 1, &dy, tempLength);
        delta.x = -invH[0][0]*dx -invH[0][1]*dy;
        delta.y = -invH[1][0]*dx -invH[1][1]*dy;
//        delta.x = invH[0][0]*dx +invH[0][1]*dy;
//        delta.y = invH[1][0]*dx +invH[1][1]*dy;
        
        iter ++;
        
//#ifdef PERFORM_SANITY_CHECKS
//        std::cout << "delta.norm() = " << delta.norm() << std::endl;
//#endif
    } while (delta.norm() > epsi && iter <= maxIter);
    
    if (ssd != 0) // compute SSD
    {
        *ssd = 0;
        // accumulate SSD per row since diff image has garbage border 
        float ssdRow = 0;
        for (int r = 0; r<tempHRound; r++)
        {
            vDSP_svesq(diff + margin + r*tempWRound, 1, &ssdRow, tempWRound);
            *ssd += ssdRow;
        }
        
    }
        
    if (leftMotion != 0) *leftMotion = delta;
    
    if (gradX == 0) free(gx); 
    else { if (*gradX != 0) free(*gradX); *gradX = gx; }
        
    if (gradY == 0) free(gy);
    else { if (*gradY != 0) free(*gradY); *gradY = gy; }
    
    if (trackedEnlarged == 0) { if(match != 0) free(match); }
    else { if (*trackedEnlarged != 0) free(*trackedEnlarged); *trackedEnlarged = match; }
    if (trackedEnlargedBox != 0) *trackedEnlargedBox = enlargedMatchBox;
    
    if (tmpl == 0) free(tempIm);
    else { if (*tmpl != 0) free(*tmpl); *tmpl = tempIm; }
    if (tmplEnlargedBox != 0) *tmplEnlargedBox = enlargedBox;
    
    free(diff); 
    
    return result;
    
}

/** Track template window in image
    \param width prev,next images width
    \param height prev,next images height
    \param prevIm normalized previous image
    \param nextIm normalized next image
    \param templateBox template in prevIm (should fit inside the image)
    \param minTracked % of the templateBox that should be tracked (value must be in (0, 1])
    \param motion template motion from prevIm to nextIm
    \param epsi motion update threshold to stop looking for the template
    \return tracking result (ok, template outside bounds or failure)

    The displacement <a>motion</a> is always initialized with (0,0), so its original 
    value doesn't matter when the function is called. If the template box
    falls outside bounds while tracking, then its dimensions get reduced, up to the point
    where its length or width are less than its original size times <a>minTracked</a>.
    For example, if the initial size of the box is 40x30 and <a>minTracked</a> is 0.5, 
    the box can get reduced up until its size is 20x15. If a smaller box is needed to 
    successfully track the template, then the procedure fails with TRACKING_STOPPEDBYBOUNDS.

    LKTemplateMatching may return one of the following codes:
    TRACKING_OK - tracking processed finished without inconvenients
    TRACKING_STOPPEDBYBOUNDS - tracking stopped because tamplate went out of bounds
    TRACKING_OUTSIDEBOUNDS - template is outside bounds
    TRACKING_EMPTY - template is seriously dark

    \note The template should lie inside the box [3 3 width-4 height-4] in prevIm, so that
    image gradients can be computed correctly
 */
TRACKINGRESULT see_FlexibleLKTemplateMatching(size_t width, size_t height, img prevIm, img nextIm,
                                              Rectangle templateBox, float minTracked, Vector2 &motion, 
                                              Vector2 *leftMotion, float *ssd, float epsi, int maxIter, 
                                              img* gradX, img* gradY, img *tmpl, Rectangle* tmplEnlargedBox,
                                              img *trackedEnlarged, Rectangle* trackedEnlargedBox)
{
//#ifdef PERFORM_SANITY_CHECKS
//    assert(minTracked > 0 && minTracked <= 1);
//#endif
    
    unsigned int margin = floor(FSIZE_GAUSDERIV7/2); 
    Vector2 centerPt = templateBox.center();
    if (centerPt.x >= width - margin || centerPt.x < margin ||
        centerPt.y >= height - margin || centerPt.y < margin)
        return TRACKING_OUTSIDEBOUNDS;
    
    Rectangle box = templateBox, trackedBox = templateBox;
//    float minWidth = box.size.x * minTracked;
//    float minHeight = box.size.y * minTracked;
    TRACKINGRESULT result;
    float outside;
    
    int iter = 0;
    while( iter < maxIter ) 
    {  
        result = see_LKTemplateMatching(width, height, prevIm, nextIm, 
                                        box, motion, leftMotion, ssd, 
                                        epsi, maxIter, gradX, gradY, 
                                        tmpl, tmplEnlargedBox,
                                        trackedEnlarged, trackedEnlargedBox);
        
//        std::cout << "tracked " << box << " with status " << result 
//            << " motion " << motion << std::endl;

        if (result == TRACKING_EMPTY || result == TRACKING_OK)
            break;
        
        // tracking stopped by bounds
        trackedBox.origin = templateBox.origin + motion;
        
        outside = round(trackedBox.left() - margin*2);
        if (outside < 0) 
        {   box.size.x += outside; 
            box.origin.x -= outside; 
//            std::cout << "shrink left outside ( " << outside << " ) " << box << std::endl;
        }
        
        outside = round((width - 1 - margin*2) - trackedBox.right());
        if (outside < 0)
        {   box.size.x += outside; 
//            std::cout << "shrink right outside ( " << outside << " ) " << box << std::endl;
        }
        
        outside = round(trackedBox.top() - margin*2);
        if (outside < 0)
        {   box.size.y += outside; 
            box.origin.y -= outside; 
//            std::cout << "shrink top outside ( " << outside << " ) " << box << std::endl;
        }
        
        outside = round((height - 1 - margin*2) - trackedBox.bottom());
        if (outside < 0)
        {   box.size.y += outside;
//            std::cout << "shrink bottom outside ( " << outside << " ) " << box << std::endl;
        }
        
        if (box.left() > centerPt.x || box.right() < centerPt.x ||
            box.top() > centerPt.y || box.bottom() < centerPt.y)
        {
            result = TRACKING_OUTSIDEBOUNDS;
            break;
        }
        
        iter++;
        
//        if (result == TRACKING_STOPPEDBYBOUNDS)
//            std::cout << box << " -> " << trackedBox << std::endl;
        
    }// while (result != TRACKING_OK && result != TRACKING_EMPTY);
    
    return result;
}

TRACKINGRESULT see_PyramidalLKTemplateMatching(size_t width, size_t height, img prevIm, img nextIm, 
                                               Rectangle templateBox, unsigned int pyrLevels, Vector2 &motion,
                                                Vector2 *leftMotion, float *ssd,
                                               float epsi, int maxIter, pyr *prevPyr, pyr *nextPyr)
{
    
    // compute pyramids
    pyr prevPyramid, nextPyramid;
    
    if (pyrLevels > 0) {
        see_pyramid(prevIm, width, height, pyrLevels+1, prevPyramid, FILTER_GAUS7, FSIZE_GAUS7, 0);
        see_pyramid(nextIm, width, height, pyrLevels+1, nextPyramid, FILTER_GAUS7, FSIZE_GAUS7, 0);
    }
    else {
        prevPyramid.push_back(prevIm);
        nextPyramid.push_back(nextIm);
    }
    
    Vector2 g(0.0,0.0);                  // template displacement in one pyr level
    Rectangle box(templateBox);          // template box in prevIm 
    size_t w, h;                         // pyr image size
    Vector2 center;
    TRACKINGRESULT result;               // tracking result
    
    // track template
    for (int l=pyrLevels; l>=0; l--)
    {
        // box in current pyr level
        center = (templateBox.center())*(1.0/pow(2.0,l));
        box.origin = center - box.size*0.5;        
//        box.origin = templateBox.origin*(1.0/pow(2.0,l));
        // curr pyr level dimensions
        w = width >> l; h = height >> l;
        
//        std::cout << "box(" << l << "): " << box << " in image of " << w << "x" << h << " ... ";
        
        // track
        img prevI = prevPyramid.at(l);
        img nextI = nextPyramid.at(l);
        
        result = see_FlexibleLKTemplateMatching(w, h, prevI, nextI,
                                                box, 0.5, g, leftMotion, (l == 0 ? ssd : 0), 
                                                epsi, maxIter);
        
//        std::cout << "TRACKING(" << result << ") g=" << g;
        
        if (result != TRACKING_OK) break;
        
        if (l > 0) g = g*2.0;
        
//        std::cout << " motion=" << motion << std::endl;
    }
    
    motion = g;
    
    if (prevPyr != 0)
    { prevPyr->swap(prevPyramid); see_freePyr(prevPyramid); }
    else 
    { see_freePyrUpToBase(prevPyramid); }
    
    if (nextPyr != 0)
    { nextPyr->swap(nextPyramid); see_freePyr(nextPyramid); }
    else
    { see_freePyrUpToBase(nextPyramid); }
    
    return result;
}


TRACKINGRESULT see_LKPyramidalLK(size_t width, size_t height, img prevIm, img nextIm,
                                 Rectangle templateBox, unsigned int pyrLevels, Vector2 &motion,
                                 float *ssd, float epsi, int maxIter, pyr *prevPyr, pyr *nextPyr)
{
    TRACKINGRESULT result = TRACKING_OK; // tracking result
    Vector2 g(0.0,0.0);                  // displacement guess
    Rectangle box(templateBox);          // template box
    size_t w, h;                         // pyr image size
    Vector2 center;                      // template box center
    unsigned int margin = floor(FSIZE_GAUSDERIV7/2);
    
    // compute pyramids
    pyr prevPyramid, nextPyramid;
    
    if (pyrLevels > 0) { // we really use pyrLevels + 1 levels
        see_pyramid(prevIm, width, height, pyrLevels+1, prevPyramid, FILTER_GAUS7, FSIZE_GAUS7, 0);
        see_pyramid(nextIm, width, height, pyrLevels+1, nextPyramid, FILTER_GAUS7, FSIZE_GAUS7, 0);
    }
    else {
        prevPyramid.push_back(prevIm);
        nextPyramid.push_back(nextIm);
    }
    
    // track template along pyramid levels
    for (int l=pyrLevels; l>=0; l--)
    {
        // get template dimensions
        int tempWRound = int(templateBox.width()), tempHRound = int(templateBox.height());
        
        // re-localize box in current pyr level
        center = (templateBox.center())*(1.0/pow(2.0,l));
        box.origin = center - box.size*0.5;
        std::cout << "l = " << l << " box = " << box << " | ";
        
        w = width >> l; h = height >> l;
        
        // reference images to process
        img prevI = prevPyramid.at(l);
        img nextI = nextPyramid.at(l);

        // extract template window
        Rectangle enlargedBox;
        img tempIm =  see_extractWindow(w, h, prevI, box, margin, &enlargedBox);
        if (tempIm == 0) return TRACKING_OUTSIDEBOUNDS;
        int enlargedWRound = int(enlargedBox.width()), enlargedHRound = int(enlargedBox.height());
        int tempLength = enlargedWRound * enlargedHRound;
        
        // estimate the gradient of the template
        Vector2 gxSize(0,0), gySize(0,0);
        img gx = see_convolveHor(tempIm + margin*enlargedWRound, enlargedWRound, tempHRound, enlargedWRound, 
                                 FILTER_GAUSDERIV7, FSIZE_GAUSDERIV7, &gxSize, margin);
        img gy = see_convolveVer(tempIm + margin, tempWRound, enlargedHRound, enlargedWRound, 
                                 FILTER_GAUSDERIV7, FSIZE_GAUSDERIV7, &gySize, margin);
        
        // compute the Hessian matrix
        // H = [Hxx Hxy; Hyx Hyy] = [gx gy]'*[gx gy]
        float Hxx = 0, Hxy = 0, Hyy = 0;
        vDSP_dotpr(gx, 1, gx, 1, &Hxx, tempLength);
        vDSP_dotpr(gx, 1, gy, 1, &Hxy, tempLength); // same as Hyx
        vDSP_dotpr(gy, 1, gy, 1, &Hyy, tempLength);
        // find H^{-1} because we will end up using 
        // -inv(H)*[gx gy]' as constant update step 
        float detH = Hxx*Hyy - Hxy*Hxy;
        float invH[2][2] = {{ Hyy/detH, -Hxy/detH},
                            {-Hxy/detH,  Hxx/detH}};
        
        // iterative LK
        int iter = 0;
        Vector2 delta(0,0), v(0,0);
        Rectangle matchBox = box, enlargedMatchBox;
        matchBox.origin = matchBox.origin + g;
        img match = 0;
        img diff = (float *)calloc(sizeof(float), tempLength);
        do {
            
            // extract window from new image
            if (match != 0) {free(match); match = 0;}
            match = see_extractWindow(w, h, nextI, matchBox, margin, &enlargedMatchBox);
            if (match == 0) { result = TRACKING_STOPPEDBYBOUNDS; break; }
            
            // image difference
            vDSP_vsub(match, 1, tempIm, 1,  diff, 1, tempLength);
            
            // update delta
            float dx = 0, dy = 0;
            vDSP_dotpr(gx, 1, diff, 1, &dx, tempLength);
            vDSP_dotpr(gy, 1, diff, 1, &dy, tempLength);
            delta.x = invH[0][0]*dx + invH[0][1]*dy;
            delta.y = invH[1][0]*dx + invH[1][1]*dy;
            
            // update match box
            matchBox.origin = matchBox.origin + delta;
            
            // accumulate displacement
            v = v + delta;
            
            iter++;
        } while (delta.norm() > epsi && iter <= maxIter);
        
        if (result != TRACKING_OK) break;
        
        if (l > 0) g = (g + v)*2; 
        else g = g + v;
        
        free(diff);
        free(gx); free(gy);
        free(tempIm);
        
    }
    
    motion = g;
    
    if (prevPyr != 0)
    { prevPyr->swap(prevPyramid); see_freePyr(prevPyramid); }
    else 
    { see_freePyrUpToBase(prevPyramid); }
    
    if (nextPyr != 0)
    { nextPyr->swap(nextPyramid); see_freePyr(nextPyramid); }
    else
    { see_freePyrUpToBase(nextPyramid); }

    return result;
}
