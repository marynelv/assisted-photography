//
//  saliencyFeatures.fsh (saliency features fragment shader)
//  AudiballMix
//
//    Created by Marynel Vazquez on 11/07/11.
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

varying lowp vec2 texCoordOut;  // texture coordinate
uniform sampler2D texture;      // texture

// Merges R,G,B colors from texture into a single intensity channel and renders a 
// 3-channel gray image
void main(void)
{
    // get color from texture
    highp vec3 col = texture2D(texture, texCoordOut).rgb;       
    
    // merge colors for intensity
    highp float intensity = col.r + col.g + col.b;    
    intensity = intensity*255.0/3.0;           
    
    // compute r-g and b-y (but avoid fluctuations)
    highp float rg = 0.0;
    highp float by = 0.0;
    highp float maxcol = max(max(col.r, col.g), col.b);
    if (maxcol >= 0.1)
    {
        rg = (col.r - col.g)/maxcol;
        by = (col.b - min(col.r, col.g))/maxcol;
    }   
    
    gl_FragColor = vec4(intensity,rg,by, 1.0);    // set features
}