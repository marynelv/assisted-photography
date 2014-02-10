//
//  GVLCommon.h
//  Framework-GLVision
//
//    Created by Marynel Vazquez on 10/22/11.
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

#ifndef Framework_GLVision_GVLCommon_h
#define Framework_GLVision_GVLCommon_h

//---------------------------------------------------------------------------------//

#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

//---------------------------------------------------------------------------------//

#define PERFORM_GL_CHECKS               //!< check for gl errors? Comment out to disable checks in GLV framework
#define PERFORM_GLV_INTERNAL_CHECKS     //!< check internal GLV processes (to be commented once code works!)

//---------------------------------------------------------------------------------//


#if __cplusplus
extern "C" {
#endif	

/**
    Vertex with color component
 */
typedef struct {
    float position[3];          //!< (x,y,z) position
    float color[4];             //!< (r,g,b,a) color
} Vertex3Col;

/**
    Vertex with texture coordinate compoenent
 */
typedef struct {    
    float position[3];          //!< (x,y,z) position
    float texCoord[2];          //!< 2D texture coordinate
} Vertex3Tex;

    
/**
    Image size
 */
typedef struct GLVImageSize {
    uint width;                     //!< image width
    uint height;                    //!< image height
} GLVSize;

/**
    Make image size
    \param w width
    \param h height
    \return image size
 */
static inline GLVSize MakeGLVSize(uint w, uint h)
{
    GLVSize size; size.width = w; size.height = h; return size;
}

/**
    Reduce image size to half
    \param size image size
 */
static inline void reduceGLVSizeToHalf(GLVSize *size)
{
    size->width = size->width >> 1;
    size->height = size->height >> 1;
}


/**
    Image point (can be thought of pixel location)
 */
typedef struct GLVImagePoint {
    int x;                      //!< x coordinate
    int y;                      //!< y coordinate
} GLVPoint;

/**
    Make image point
    \param a x coordinate
    \param b y coordinate
    \return point
 */
static inline GLVPoint MakeGLVPoint(int a, int b)
{
    GLVPoint point; point.x = a; point.y = b; return point;
}


/**
    Texture image
 */
typedef struct TexureImage {
    GLuint textureID;           //!< texture ID in FBO
    GLVSize size;               //!< image size
} TexImage;

/**
    Create texture image
    \param identifier texture ID
    \param w width
    \param h height
    \return texture image
 */
static inline TexImage MakeTexImage(GLuint identifier, uint w, uint h)
{
    TexImage textureImage;
    textureImage.textureID = identifier;
    textureImage.size = MakeGLVSize(w, h);
    return textureImage;
}
    
typedef struct TextureData {
    float *data;
    uint nchannels;
    GLVSize size;
} TexData;
    
static inline TexData MakeTexData(uint w, uint h, uint c)
{
    TexData textureData;
    textureData.data = (float *)malloc(w*h*c*sizeof(float));
    textureData.size.width = w;
    textureData.size.height = h;
    textureData.nchannels = c;
    return textureData;
}
    
static inline void ReleaseTexData(TexData *texData)
{
    free(texData->data);
}
    
typedef TexData * TexDataRef;
    
static inline void ReleaseTexDataRef(TexDataRef texDataRef)
{
    if (texDataRef == 0 || texDataRef == NULL) return;
    ReleaseTexData(texDataRef);
}
    
#if __cplusplus
}
#endif
    

//---------------------------------------------------------------------------------//

/**
    Read float data from rendered scene (pixels format is GL_RGBA and type is GL_FLOAT)
    \param x horizontal coordinate of lower left corner in the screen
    \param y vertical coordinate of lower left corner in the screen
    \param width pixel rectangle width
    \param height pixel rectangle  height
    \return data from rendered FBO
 */
static inline float* getFloatDataFromFBOTexture(int x, int y, int width, int height)
{
    int length = width*height*4;
    float* data = (float *) malloc(length*sizeof(float));
    glReadPixels(x, y, width, height, GL_RGBA, GL_FLOAT, data);    
    return data;
}

/**
    Read float data from rendered scene (pixels format is GL_RGBA and type is GL_UNSIGNED_BYTE)
    \param x horizontal coordinate of lower left corner in the screen
    \param y vertical coordinate of lower left corner in the screen
    \param width pixel rectangle width
    \param height pixel rectangle height
    \return data from rendered FBO
 */
static inline GLubyte *getUByteDataFromFBOTexture(int x, int y, int width, int height)
{
    int length = width*height*4;
    GLubyte *data = (GLubyte *) malloc(length*sizeof(GLubyte));
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);    
    return data;
}

/**
    Read float data from rendered scene (pixels from is GL_RED_EXT and type is GL_UNSIGNED_BYTE)
    \param x horizontal coordinate of lower left corner in the screen
    \param y vertical coordinate of lower left corner in the screen
    \param width pixel rectangle width
    \param height pixel rectangle height
    \return data from rendered FBO
 */
static inline GLubyte *getRedUByteDataFromFBOTexture(int x, int y, int width, int height)
{
    GLubyte *data = (GLubyte *) malloc(width*height*sizeof(GLubyte));
    glReadPixels(x, y, width, height, GL_RED_EXT, GL_UNSIGNED_BYTE, data);    
    return data;
}
                                         
//---------------------------------------------------------------------------------//

/**
    Find next power of 2 for a given unsigned int
    @param x input value
    @return next power of 2 for x
    @note Caution if arquitecture is 64-bit (we would need one more shift-or operation!). We've added a special case for this using the __LP64__ macro, but this hasn't been tested.
 */
static inline unsigned int nextPowerOf2(unsigned int x)
{
    x--;
    x = (x >> 1) | x;
    x = (x >> 2) | x;
    x = (x >> 4) | x;
    x = (x >> 8) | x;
    x = (x >> 16) | x;
#if __LP64__
    x = (x >> 32) | x;
#endif
    x++;
    return x;
}

//---------------------------------------------------------------------------------//


#define GLVDebugFile [NSString stringWithFormat:@"%@: %d",[[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__]
#define GLVDebugLog( s, ... ) NSLog( @"<%p %@:(%d)> %@", self, [[NSString stringWithUTF8String:__FILE__] lastPathComponent], __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )

#endif
