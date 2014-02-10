//
//  RenderedCameraView.m
//  AudiballMix
//
//    Created by Marynel Vazquez on 9/28/11.
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

#import "RenderedCameraView.h"

#import <GLVision/GLVCommon.h>
#import <Accelerate/Accelerate.h>
#import <See/ImageConversion.h>
#import <See/ImageSaliency.h>
#import <See/ImageBlurriness.h>
#import <DataLogging/DLTiming.h>

#define TIME_FEATURE_COMPUTATION
#define TIME_FEATURE_DATA_EXTRACTION
#define TIME_FEATURE_DATA_COPYING

#define TEMPLATE_EPSILON  0.005 //0.00003 // 0.05
#define TEMPLATE_MAX_ITER 300 //1000 // 50

inline float maxi(int a, int b){ return (a > b ? a : b); }
inline float mini(int a, int b){ return (a < b ? a : b); }


static Matrix4 projection;
static Matrix4 resizeProjection;

@implementation RenderedCameraView
@synthesize delegate;
@synthesize pResize;
@synthesize pScreenRender;
@synthesize featureType;
@synthesize trackingStatus;
@synthesize maxProcessingSizeTracking;

- (id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize maxSizeTracking:(GLVSize)maxSizeTrack;
{
    self = [super initWithFrame:frame maxProcessingSize:maxSize]; 
    if (self)
    {        
        if (maxSizeTrack.width > 2048 || maxSizeTrack.height > 2048)
        {
            GLVDebugLog(@"ERROR: Processing size for tracking exceeds limits.");
            self = nil;
            return self;
        }
        
        self.maxProcessingSizeTracking = maxSizeTrack;
        
        // set up rectangled to be rendered
        [self setUpBufferObjects];
        
        //        glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
                
        // creates and links the screen renderer program
        self.pScreenRender = [[GLVProgramTexture alloc] init];
        if (!self.pScreenRender)
        {
            NSLog(@"ERROR: Could not set up texture program shader to render on screen.");
            self = nil;
            return self;
        }
        [self.pScreenRender useProgram];
        [self.pScreenRender enableAttributes];
        pScreenRender_attr_position = [self.pScreenRender attributeWithIndex:PROG_TEXTURE_ATTR_POSITION];
        pScreenRender_attr_texCoord = [self.pScreenRender attributeWithIndex:PROG_TEXTURE_ATTR_TEXCOORD];
        pScreenRender_uni_projection = [self.pScreenRender uniformWithIndex:PROG_TEXTURE_UNI_PROJECTION];
        pScreenRender_uni_texture = [self.pScreenRender uniformWithIndex:PROG_TEXTURE_UNI_TEXTURE];
        //        [self.pScreenRender enableAttributes];
        //        [self.glvEngine storeProgramHandler:programTexture];
        
        projection = Matrix4::orthographic(0, self.frame.size.width, self.frame.size.height, 0, 0, 1); 
        
        self.featureType = FEAT_INT;
    }
    return self;
}

- (void) dealloc
{
    if (resizeTexture.textureID)
        glDeleteTextures(1, &(resizeTexture.textureID));
}

- (void) setUpBufferObjects
{
    viewRect = 0, viewRectIdx = 0;
    [GLVEngine setUpGenericRectTexWithSize:self.frame.size origin:CGPointMake(0,0) 
                                     array:&viewRect idxElementArray:&viewRectIdx]; 
    //    [GLVEngine setUpGenericRectTexWithSize:CGSizeMake(self.frame.size.width, self.frame.size.width) origin:CGPointMake(0,0) 
    //                                     array:&viewRect idxElementArray:&viewRectIdx]; 
    //    [self.glvEngine storeBufferObjectID:camRect];
    //    [self.glvEngine storeBufferObjectID:rectIdx];  
    
    [GLVEngine setUpGenericRectTexWithSize:CGSizeMake(self.maxProcessingSize.width, self.maxProcessingSize.height) 
                                    origin:CGPointMake(0, 0) 
                                     array:&resizeRect idxElementArray:NULL];
    
    
    [GLVEngine setUpGenericRectTexWithSize:CGSizeMake(self.maxProcessingSizeTracking.width, self.maxProcessingSizeTracking.height) 
                                    origin:CGPointMake(0, 0) 
                                     array:&resizeTrackingRect idxElementArray:NULL];
}

- (BOOL) setUpColorResizeShader
{    
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return 0;
    }
    
//    [GLVEngine glError:GLVDebugFile];
    
    self.pResize = [[GLVProgramTexture alloc] init];
    if (!self.pResize)
    {
        NSLog(@"ERROR: Could not set up texture program shader to resize image.");
        return NO;            
    }
    
    
//    [GLVEngine glError:GLVDebugFile];
    
    [self.pResize useProgram];
    
//    [GLVEngine glError:GLVDebugFile];
    [self.pResize enableAttributes];
    
//    [GLVEngine glError:GLVDebugFile];
    pResize_attr_position = [self.pResize attributeWithIndex:PROG_TEXTURE_ATTR_POSITION];
    pResize_attr_texCoord = [self.pResize attributeWithIndex:PROG_TEXTURE_ATTR_TEXCOORD];
    pResize_uni_projection = [self.pResize uniformWithIndex:PROG_TEXTURE_UNI_PROJECTION];
    pResize_uni_texture = [self.pResize uniformWithIndex:PROG_TEXTURE_UNI_TEXTURE];
    
    resizeProjection = Matrix4::orthographic(0, self.maxProcessingSize.width, 
                                             self.maxProcessingSize.height, 0, 0, 1);
    
    resizeTexture.textureID = 0;
    resizeTexture.size = self.maxProcessingSize;
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &(resizeTexture.textureID));
    glBindTexture(GL_TEXTURE_2D, resizeTexture.textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)(resizeTexture.size.width), (int)(resizeTexture.size.height),
                 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);
    
//    [GLVEngine glError:GLVDebugFile];
    
    return YES;
}

- (BOOL) setUpGrayResizeShader
{
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return 0;
    }
    
    
//    [GLVEngine glError:GLVDebugFile];
    
    self.pResize = [[GLVProgramGray alloc] init];
    if (!self.pResize)
    {
        NSLog(@"ERROR: Could not set up texture program shader to resize image.");
        return NO;
    }
    [self.pResize useProgram];
    
//    [GLVEngine glError:GLVDebugFile];
    [self.pResize enableAttributes];
    
//    [GLVEngine glError:GLVDebugFile];
    pResize_attr_position = [self.pResize attributeWithIndex:PROG_TEXTURE_ATTR_POSITION];
    pResize_attr_texCoord = [self.pResize attributeWithIndex:PROG_TEXTURE_ATTR_TEXCOORD];
    pResize_uni_projection = [self.pResize uniformWithIndex:PROG_TEXTURE_UNI_PROJECTION];
    pResize_uni_texture = [self.pResize uniformWithIndex:PROG_TEXTURE_UNI_TEXTURE];
    
    resizeProjection = Matrix4::orthographic(0, self.maxProcessingSizeTracking.width, 
                                             self.maxProcessingSizeTracking.height, 0, 0, 1);
    
    resizeTexture.textureID = 0;
    resizeTexture.size = self.maxProcessingSizeTracking;
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &(resizeTexture.textureID));
    glBindTexture(GL_TEXTURE_2D, resizeTexture.textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, (int)(resizeTexture.size.width), (int)(resizeTexture.size.height),
                 0, GL_RED_EXT, GL_UNSIGNED_BYTE, NULL);
    glBindTexture(GL_TEXTURE_2D, 0);
    
//    [GLVEngine glError:GLVDebugFile];
    
    return YES;
}

- (void) discardResizeShader
{
//    glBindFramebuffer(GL_FRAMEBUFFER, 0);
//    [GLVEngine glError:GLVDebugFile];
//    glBindTexture(GL_TEXTURE_2D, 0);
//    [GLVEngine glError:GLVDebugFile];
//    glUseProgram(0);
    
//    [GLVEngine glError:GLVDebugFile];
    if (resizeTexture.textureID != 0) glDeleteTextures(1, &resizeTexture.textureID);
//    [GLVEngine glError:GLVDebugFile];
    if (self.pResize != nil) {self.pResize = nil;}
//    [GLVEngine glError:GLVDebugFile];
}

// Resets tracking status to TRACKING_OK
- (void) setTemplateBox:(Rectangle)rect
{
    templateBox = rect;
    self.trackingStatus = TRACKING_OK;
}

- (img) glSaliencyFromPixelBufferRef:(CVPixelBufferRef)pixelBufferRef width:(size_t *)w height:(size_t *)h pyrLev:(int)pyrLev surrLev:(int)surrLev
{
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return 0;
    }
    
    if (![self featuresFromPixelBuffer:pixelBufferRef pixelFormat:GL_BGRA textureFormat:GL_RGBA])
    {
        GLVDebugLog(@"ERROR: Could not build up features." );
        return 0;
    }
    
    img saliency = 0;
    *w = self.maxProcessingSize.height;
    *h = self.maxProcessingSize.width;
    
    float *features = getFloatDataFromFBOTexture(0, featuresTexture.size.height - self.maxProcessingSize.height,
                                                 self.maxProcessingSize.width, self.maxProcessingSize.height);
    
    img featInt = (float *)malloc(self.maxProcessingSize.width*self.maxProcessingSize.height*sizeof(float));
    img featRG  = (float *)malloc(self.maxProcessingSize.width*self.maxProcessingSize.height*sizeof(float));
    img featBY  = (float *)malloc(self.maxProcessingSize.width*self.maxProcessingSize.height*sizeof(float));
    
    for (int r=0; r<self.maxProcessingSize.height; r++)
    {
        // NOTE: For negative strides, cblas_scopy gets the i-th element as (N-i)*|incx| for incx < 0.
        //       In our case N in [1,self.maxProcessingSize.width], incx = -4
        float * src = features + (self.maxProcessingSize.height - 1 - r)*4*self.maxProcessingSize.width;
        cblas_scopy(self.maxProcessingSize.width, src  , -4, featInt+r,  self.maxProcessingSize.height);
        cblas_scopy(self.maxProcessingSize.width, src+1, -4, featRG +r,  self.maxProcessingSize.height);
        cblas_scopy(self.maxProcessingSize.width, src+2, -4, featBY +r,  self.maxProcessingSize.height);
    }
    
    see_saliencyIttiWithFeatures(featInt, featRG, featBY, *w, *h, pyrLev, surrLev, saliency);
    
    free(featInt);
    free(featRG);
    free(featBY);
    
    free(features);
    
    return saliency;
        
}

- (void) featureDifferenceForPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{
    FeatureType displayFeature = self.featureType; 
    if (displayFeature == FEAT_SRC) return;
    
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return;
    }
    
    GLuint diffID = 0;
    int featuresLenght = self.maxProcessingSize.width*self.maxProcessingSize.height;
    img featureGPU = (float *) malloc(sizeof(float)*featuresLenght), 
    featureCPU = 0;
    
    // compute feature using shaders
    if (![self featuresFromPixelBuffer:pixelBufferRef pixelFormat:GL_BGRA textureFormat:GL_RGBA])
    { GLVDebugLog(@"ERROR: Could not build up features." ); return; }
    float *featuresDataGPU = getFloatDataFromFBOTexture(0, featuresTexture.size.height - self.maxProcessingSize.height, 
                                                        self.maxProcessingSize.width, self.maxProcessingSize.height);
    img featureChannel = (displayFeature == FEAT_INT ? featuresDataGPU : 
                          (displayFeature == FEAT_RG ? featuresDataGPU + 1 : featuresDataGPU + 2));    
    for (int r=0; r<self.maxProcessingSize.height; r++)
    {
        cblas_scopy(self.maxProcessingSize.width, 
                    featureChannel + (self.maxProcessingSize.height - 1 - r)*4*self.maxProcessingSize.width, -4, 
                    featureGPU+r,  self.maxProcessingSize.height);
    }
    free(featuresDataGPU);
    
    // compute feature through the accelerate framework
    glBindFramebuffer(GL_FRAMEBUFFER, fboTexture[GLVVSAL_FBO_TEXTURE_1]); 
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 
                           resizeTexture.textureID, 0); 
    glViewport(0, 0, (int)(resizeTexture.size.width), (int)(resizeTexture.size.height));
    [self.pResize useProgram];
    glBindBuffer(GL_ARRAY_BUFFER, resizeRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, imageRectIdx);
    glVertexAttribPointer(pResize_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pResize_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    glUniformMatrix4fv(pResize_uni_projection, 1, 0, resizeProjection.elem);
    glActiveTexture(GL_TEXTURE1);
    [self textureFromPixelBuffer:pixelBufferRef pixelFormat:GL_BGRA textureFormat:GL_RGBA];
    GLuint pixelBufferTexture = CVOpenGLESTextureGetName(pbTexture);
    glBindTexture(GL_TEXTURE_2D, pixelBufferTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
    glUniform1i(pResize_uni_texture, 1); // GL_TEXTURE1
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
    GLubyte *resizedData = getUByteDataFromFBOTexture(0, 0, resizeTexture.size.width, resizeTexture.size.height);
    img red = (float *) malloc(sizeof(float)*featuresLenght), 
    green = (float *) malloc(sizeof(float)*featuresLenght),
    blue = (float *) malloc(sizeof(float)*featuresLenght);
    for (int r=0; r<resizeTexture.size.height; r++)
    {   GLubyte * src = resizedData + (resizeTexture.size.height - r)*4*resizeTexture.size.width - 4;
        long srcStride = -4;
        long dstStride = resizeTexture.size.height;
        vDSP_Length length = resizeTexture.size.width;
        vDSP_vfltu8(src, srcStride, red + r, dstStride, length);
        vDSP_vfltu8(src + 1, srcStride, green + r, dstStride, length);
        vDSP_vfltu8(src + 2, srcStride, blue + r, dstStride, length); }
    if (displayFeature == FEAT_INT) featureCPU = see_intensity(red, green, blue, featuresLenght); 
    else if (displayFeature == FEAT_RG) see_opponency(red, green, blue, featuresLenght, &featureCPU, NULL);
    else /* (displayFeature == FEAT_BY) */ see_opponency(red, green, blue, featuresLenght, NULL, &featureCPU);
    free(red); free(green); free(blue);
    free(resizedData);
    
    // store diff in featureGPU
    vDSP_vsub(featureCPU, 1, featureGPU, 1, featureGPU, 1, featuresLenght);
    vDSP_vabs(featureGPU, 1, featureGPU, 1, featuresLenght);
    // and scale if necessary
    float maximum = 0.0, sumerr = 0.0;
	vDSP_maxv(featureGPU, 1, &maximum, featuresLenght);
    vDSP_sve(featureGPU, 1, &sumerr, featuresLenght);
    NSLog(@"max(diff) = %f sum(diff) = %f", maximum, sumerr);
    if (maximum > 255.0)
    {
        maximum = 255.0/maximum;
        vDSP_vsmul(featureGPU, 1, &maximum, featureGPU, 1, featuresLenght);
    }
    
    GLubyte *data = (GLubyte *)malloc(self.maxProcessingSize.width*self.maxProcessingSize.height*4*sizeof(GLubyte));
    vDSP_vfixru8(featureGPU, 1, data,   4,featuresLenght);
    vDSP_vfixru8(featureGPU, 1, data+1, 4,featuresLenght);
    vDSP_vfixru8(featureGPU, 1, data+2, 4,featuresLenght);
    
    free(featureCPU); free(featureGPU);
    
    // set up the view
    glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
//    [GLVEngine glError:GLVDebugFile];
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
//    [GLVEngine glError:GLVDebugFile];
    
    [self.pScreenRender useProgram];
    
    glGenTextures(1, &diffID);
    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, diffID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, featuresTexture.size.width, featuresTexture.size.height, 0, GL_RGBA,
    //                 GL_UNSIGNED_BYTE, data);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,  self.maxProcessingSize.height,  self.maxProcessingSize.width, 0, GL_RGBA,
                 GL_UNSIGNED_BYTE, data);
    free(data);
//    [GLVEngine glError:GLVDebugFile];
    
    // pass texture uniform
    glUniform1i(pScreenRender_uni_texture, 2); // GL_TEXTURE0
//    [GLVEngine glError:GLVDebugFile];
    
    // pass projection uniform
    glUniformMatrix4fv(pScreenRender_uni_projection, 1, 0, projection.elem);
//    [GLVEngine glError:GLVDebugFile];
    
    // pass vertex shader attributes
    glBindBuffer(GL_ARRAY_BUFFER, viewRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, viewRectIdx);
    glVertexAttribPointer(pScreenRender_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pScreenRender_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
//    [GLVEngine glError:GLVDebugFile];
    
    // draw image
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
//    [GLVEngine glError:GLVDebugFile];
    
    glBindTexture(GL_TEXTURE_2D, 0);   
    glDeleteTextures(1, &diffID);
//    [GLVEngine glError:GLVDebugFile];
    
    // present rendered buffer on screen
    glBindRenderbuffer(GL_RENDERBUFFER, rbColorScreen);
    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER];     
//    [GLVEngine glError:GLVDebugFile];
}

- (Vector3) trackTemplate:(img)nextIm
{
    if (self.trackingStatus != TRACKING_OK)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSObject *del = (NSObject*)self.delegate;
            if ([del respondsToSelector:@selector(alertTrackingFailure:)])
            {
                [self.delegate alertTrackingFailure:[[NSString alloc] initWithFormat:@"Tracking status is not OK (status = %d)", self.trackingStatus]];
            }
        });        
        return Vector3(0, 0, 0);
    }
    
    size_t imSize = resizeTexture.size.width*resizeTexture.size.height;
    
    img nextImNorm = (float *)malloc(sizeof(float)*imSize);
    cblas_scopy(imSize, nextIm, 1,  nextImNorm, 1);
    see_scaleTo(nextImNorm, imSize, 1.0);
    
    Vector2 motion(0,0);
    
    img trackedIm = 0; Rectangle trackedRect; float blur = -1.0;
    size_t templateWidth = resizeTexture.size.height, templateHeight = resizeTexture.size.width;  
    
    if (prevIm == 0) 
    { 
        prevIm = nextImNorm; 
        
        Rectangle enlargedBox;
        img tempIm =  see_extractWindow(templateWidth, templateHeight, prevIm, templateBox, 
                                        floor(FSIZE_GAUSDERIV7/2), &enlargedBox);
        if (tempIm != 0) 
        {
            blur = perceptualBlurMetric(tempIm, int(enlargedBox.width()), int(enlargedBox.height()), 
                                        int(enlargedBox.width()), FILTER_AVERAGE3, FSIZE_AVERAGE3);
            free(tempIm);
        }
    }
    else
    {
              
        self.trackingStatus = see_FlexibleLKTemplateMatching(templateWidth, templateHeight, prevIm, nextImNorm, templateBox, 
                                                             0.4, motion, 0, 0, TEMPLATE_EPSILON, TEMPLATE_MAX_ITER, 0, 0, 0, 0, 
                                                             &trackedIm, &trackedRect);
        
        if (self.trackingStatus != TRACKING_OK)
        {
            NSLog(@"Tracking result = %d", self.trackingStatus);
            free(nextImNorm);
            
            NSString *message;
            switch (self.trackingStatus) {
                case TRACKING_EMPTY:
                    message = @"Empty template.";
                    break;
                case TRACKING_OUTSIDEBOUNDS:
                    message = @"Template went outside bounds.";
                    break;
                case TRACKING_STOPPEDBYBOUNDS:
                    message = @"Don't know how to handle bounds.";
                    break;
                default:
                    message = @"?";
                    break;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSObject *del = (NSObject*)self.delegate;
                if ([del respondsToSelector:@selector(alertTrackingFailure:)])
                {
                    [self.delegate alertTrackingFailure:message];
                }
            });
        }
        else 
        {
            templateBox.origin.x += motion.x;
            templateBox.origin.y += motion.y;
            
            free(prevIm);
            prevIm = nextImNorm;
        }
        
        if (trackedIm != 0)
        {
            blur = perceptualBlurMetric(trackedIm, int(trackedRect.width()), int(trackedRect.height()), 
                                        int(trackedRect.width()), FILTER_AVERAGE3, FSIZE_AVERAGE3);
            
            free(trackedIm);
        }
        
    }
    
    return Vector3(motion.x, motion.y, blur);
}


- (img) intensityFromPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{    
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return 0;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, fboTexture[GLVVSAL_FBO_TEXTURE_1]); 
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 
                           resizeTexture.textureID, 0); 
    
    glViewport(0, 0, (int)(resizeTexture.size.width), (int)(resizeTexture.size.height));
    
    [self.pResize useProgram];
    
    glBindBuffer(GL_ARRAY_BUFFER, resizeTrackingRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, imageRectIdx);
    glVertexAttribPointer(pResize_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pResize_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    
    glUniformMatrix4fv(pResize_uni_projection, 1, 0, resizeProjection.elem);
    
    glActiveTexture(GL_TEXTURE1);
    [self textureFromPixelBuffer:pixelBufferRef pixelFormat:GL_BGRA textureFormat:GL_RGBA];
    // and assign it to saliency features shader uniform
    GLuint pixelBufferTexture = CVOpenGLESTextureGetName(pbTexture);
    glBindTexture(GL_TEXTURE_2D, pixelBufferTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
    glUniform1i(pResize_uni_texture, 1); // GL_TEXTURE1
//    [GLVEngine glError:GLVDebugFile];
    
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
//    [GLVEngine glError:GLVDebugFile];
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
    
    GLubyte *resizedData = getRedUByteDataFromFBOTexture(0, 0, resizeTexture.size.width, resizeTexture.size.height);
//    [GLVEngine glError:GLVDebugFile];
    
    img resizedImg = (float *)malloc(sizeof(float)*resizeTexture.size.width*resizeTexture.size.height);
    for (int r=0; r<resizeTexture.size.height; r++)
    {   
        GLubyte * src = resizedData + (resizeTexture.size.height - r)*resizeTexture.size.width - 1;
        long srcStride = -1;
        long dstStride = resizeTexture.size.height;
        vDSP_Length length = resizeTexture.size.width;
        vDSP_vfltu8(src, srcStride, resizedImg + r, dstStride, length);
    }
    
    free(resizedData);
    return resizedImg;
}


- (void) renderPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return;
    }
    
    
//    [GLVEngine glError:GLVDebugFile];
    
    GLuint featID;
    
    // set up the view
    glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
    
    
//    [GLVEngine glError:GLVDebugFile];
    
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
//    [GLVEngine glError:GLVDebugFile];
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
//    [GLVEngine glError:GLVDebugFile];
    
    [self.pScreenRender useProgram];
    
    // get pixelbuffer texture
    glActiveTexture(GL_TEXTURE2);
    [self textureFromPixelBuffer:pixelBufferRef pixelFormat:GL_BGRA textureFormat:GL_RGBA];
    // and assign it to saliency features shader uniform
    featID = CVOpenGLESTextureGetName(pbTexture);
    glBindTexture(GL_TEXTURE_2D, featID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR); 
    
    // pass texture uniform
    glUniform1i(pScreenRender_uni_texture, 2); // GL_TEXTURE0
//    [GLVEngine glError:GLVDebugFile];
    
    // pass projection uniform
    glUniformMatrix4fv(pScreenRender_uni_projection, 1, 0, projection.elem);
//    [GLVEngine glError:GLVDebugFile];
    
    // pass vertex shader attributes
    glBindBuffer(GL_ARRAY_BUFFER, viewRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, viewRectIdx);
    glVertexAttribPointer(pScreenRender_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pScreenRender_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
//    [GLVEngine glError:GLVDebugFile];
    
    
    // draw image
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
//    [GLVEngine glError:GLVDebugFile];
    
    
    glBindTexture(GL_TEXTURE_2D, 0);   
//    [GLVEngine glError:GLVDebugFile];
    
    // present rendered buffer on screen
    glBindRenderbuffer(GL_RENDERBUFFER, rbColorScreen);
    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER];     
//    [GLVEngine glError:GLVDebugFile];
    
}

- (float) template_tracking_epsilon {
    return (float)TEMPLATE_EPSILON;
}
- (int) template_tracking_maxIter {
    return (int)TEMPLATE_MAX_ITER;
}

@end
