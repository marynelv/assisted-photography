//
//  RenderView.m
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "RenderView.h"
#import <GLVision/GLVCommon.h>
#import <Accelerate/Accelerate.h>
#import <See/ImageConversion.h>
#import <DataLogging/DLTiming.h>

//#define TIME_FEATURE_COMPUTATION
//#define TIME_FEATURE_DATA_EXTRACTION
//#define TIME_FEATURE_DATA_COPYING

static Matrix4 projection;
static Matrix4 resizeProjection;

@implementation RenderView
@synthesize pResize;
@synthesize pScreenRender;
@synthesize featureType;

- (id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize
{
    self = [super initWithFrame:frame maxProcessingSize:maxSize]; 
    if (self)
    {        
        // set up rectangled to be rendered
        [self setUpBufferObjects];
        
//        glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
        
        self.pResize = [[GLVProgramTexture alloc] init];
        if (!self.pResize)
        {
            NSLog(@"ERROR: Could not set up texture program shader to resize image.");
            self = nil;
            return self;            
        }
        [self.pResize useProgram];
        [self.pResize enableAttributes];
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
    [GLVEngine glError:GLVDebugFile];
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    [GLVEngine glError:GLVDebugFile];
    
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
    [GLVEngine glError:GLVDebugFile];
    
    // pass texture uniform
    glUniform1i(pScreenRender_uni_texture, 2); // GL_TEXTURE0
    [GLVEngine glError:GLVDebugFile];
    
    // pass projection uniform
    glUniformMatrix4fv(pScreenRender_uni_projection, 1, 0, projection.elem);
    [GLVEngine glError:GLVDebugFile];
    
    // pass vertex shader attributes
    glBindBuffer(GL_ARRAY_BUFFER, viewRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, viewRectIdx);
    glVertexAttribPointer(pScreenRender_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pScreenRender_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    [GLVEngine glError:GLVDebugFile];
    
    // draw image
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    [GLVEngine glError:GLVDebugFile];
    
    glBindTexture(GL_TEXTURE_2D, 0);   
    glDeleteTextures(1, &diffID);
    [GLVEngine glError:GLVDebugFile];
    
    // present rendered buffer on screen
    glBindRenderbuffer(GL_RENDERBUFFER, rbColorScreen);
    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER];     
    [GLVEngine glError:GLVDebugFile];
}

- (void) processPixelBufferRef:(CVPixelBufferRef)pixelBufferRef allGPU:(BOOL)allGPU
{
    FeatureType displayFeature = self.featureType; 
    if (displayFeature == FEAT_SRC) return;

    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return;
    }
    
    GLubyte *data = (GLubyte *)malloc(self.maxProcessingSize.width*self.maxProcessingSize.height*4*sizeof(GLubyte));
    int featuresLenght;
    GLuint featID;
    
    { // compute features
        
        if (allGPU)
        {
    
#ifdef TIME_FEATURE_COMPUTATION
            double tFeatFromPix = tic();
#endif
    
            if (![self featuresFromPixelBuffer:pixelBufferRef pixelFormat:GL_BGRA textureFormat:GL_RGBA])
            {
                GLVDebugLog(@"ERROR: Could not build up features." );
                return;
            }
        
#ifdef TIME_FEATURE_COMPUTATION
            tFeatFromPix = toc(tFeatFromPix);
            tFeatFromPix = tFeatFromPix / NANOS_IN_MS;
            COUT_TIME_LOG_AT("featuresFromPixelBuffer", tFeatFromPix);
#endif

#ifdef TIME_FEATURE_DATA_EXTRACTION
            double tFeatData = tic();
#endif
        
            // set up drawable texture
            // NOTE: We don't need glEnable(GL_TEXTURE_2D) because we are writing the shader so we decide
            // directly which texture units we are going to reference!
            float *features = getFloatDataFromFBOTexture(0, featuresTexture.size.height - self.maxProcessingSize.height, 
                                                         self.maxProcessingSize.width, self.maxProcessingSize.height);

#ifdef TIME_FEATURE_DATA_EXTRACTION
            tFeatData = toc(tFeatData);
            tFeatData = tFeatData / NANOS_IN_MS;
            COUT_TIME_LOG_AT("getFloatDataFromFBOTexture", tFeatData);
#endif
        
#ifdef TIME_FEATURE_DATA_COPYING
            double tFeatDataCopy = tic();
#endif
    
            featuresLenght = self.maxProcessingSize.width*self.maxProcessingSize.height;
            img featChannel = features;
            
            switch (displayFeature) {
                case FEAT_INT:
                    break;
                case FEAT_RG:
                    featChannel = featChannel + 1;
                    break;
                case FEAT_BY:
                    featChannel = featChannel + 2;
                    break;
                default:
                    GLVDebugLog(@"WARNING: Unknown feature type.");
                    break;
            }
            see_scaleTo(featChannel, featuresLenght, 255.0, 4);   
            
            for (int r=0; r<self.maxProcessingSize.height; r++)
            {
                float * src = featChannel + (self.maxProcessingSize.height - 1 - r)*4*self.maxProcessingSize.width + self.maxProcessingSize.width*4 - 4;
                long srcStride = -4;
                GLubyte * dst = data + r*4;
                long dstStride = self.maxProcessingSize.height*4;
                vDSP_Length length = self.maxProcessingSize.width; 
                
                vDSP_vfixru8(src  , srcStride, dst  ,  dstStride, length);
                vDSP_vfixru8(src  , srcStride, dst+1,  dstStride, length);
                vDSP_vfixru8(src  , srcStride, dst+2,  dstStride, length);
            }
    
#ifdef TIME_FEATURE_DATA_EXTRACTION
                tFeatDataCopy = toc(tFeatDataCopy);
                tFeatDataCopy = tFeatDataCopy / NANOS_IN_MS;
                COUT_TIME_LOG_AT("copyFloatData", tFeatDataCopy);
#endif
        
            free(features);
        
//            if (![self generateFeaturesPyramid])
//            {
//                GLVDebugLog(@"ERROR: generateFeaturesPyramid failed." );
//                return;        
//            }
       
        }
        else
        {
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
            // and assign it to saliency features shader uniform
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
            
            featuresLenght = resizeTexture.size.width*resizeTexture.size.height;
            
#ifdef TIME_FEATURE_DATA_EXTRACTION
            double tFeatData = tic();
#endif
            
            GLubyte *resizedData = getUByteDataFromFBOTexture(0, 0, resizeTexture.size.width, resizeTexture.size.height);
            
#ifdef TIME_FEATURE_DATA_EXTRACTION
            tFeatData = toc(tFeatData);
            tFeatData = tFeatData / NANOS_IN_MS;
            COUT_TIME_LOG_AT("getUcharDataFromFBOTexture", tFeatData);
#endif
            
            img red = (float *) malloc(sizeof(float)*featuresLenght);
            img green = (float *) malloc(sizeof(float)*featuresLenght);
            img blue = (float *) malloc(sizeof(float)*featuresLenght);
            for (int r=0; r<resizeTexture.size.height; r++)
            {
                GLubyte * src = resizedData + (resizeTexture.size.height - r)*4*resizeTexture.size.width - 4;
                long srcStride = -4;
                long dstStride = resizeTexture.size.height;
                vDSP_Length length = resizeTexture.size.width; 
                
                vDSP_vfltu8(src, srcStride, red + r, dstStride, length);
                vDSP_vfltu8(src + 1, srcStride, green + r, dstStride, length);
                vDSP_vfltu8(src + 2, srcStride, blue + r, dstStride, length);
            }
            
            img featInt = see_intensity(red, green, blue, featuresLenght);
            img featRG = 0, featBY = 0;  
            see_opponency(red, green, blue, featuresLenght, &featRG, &featBY);
                        
            img featChannel = 0;
            
            switch (displayFeature) {
                case FEAT_INT:
                    featChannel = featInt; 
                    break;
                case FEAT_RG:
                    featChannel = featRG;
                    break;
                case FEAT_BY:
                    featChannel = featBY;
                    break;
                default:
                    GLVDebugLog(@"WARNING: Unknown feature type.");
                    break;
            }
            see_scaleTo(featChannel, featuresLenght, 255.0, 1);
            
            vDSP_vfixru8(featChannel, 1, data,   4,featuresLenght);
            vDSP_vfixru8(featChannel, 1, data+1, 4,featuresLenght);
            vDSP_vfixru8(featChannel, 1, data+2, 4,featuresLenght);
            
            free(red); free(green); free(blue);
            free(featInt); free(featRG); free(featBY);
            free(resizedData);
            
        }
            
        // set up the view
        glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
        glClearColor(1.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        [GLVEngine glError:GLVDebugFile];
        
        glViewport(0, 0, self.frame.size.width, self.frame.size.height);
        [GLVEngine glError:GLVDebugFile];
        
        [self.pScreenRender useProgram];
        
        glGenTextures(1, &featID);
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, featID);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, featuresTexture.size.width, featuresTexture.size.height, 0, GL_RGBA,
    //                 GL_UNSIGNED_BYTE, data);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA,  self.maxProcessingSize.height,  self.maxProcessingSize.width, 0, GL_RGBA,
                     GL_UNSIGNED_BYTE, data);
        free(data);
        [GLVEngine glError:GLVDebugFile];
        
    }
        
    // pass texture uniform
    glUniform1i(pScreenRender_uni_texture, 2); // GL_TEXTURE0
    [GLVEngine glError:GLVDebugFile];
    
    // pass projection uniform
    glUniformMatrix4fv(pScreenRender_uni_projection, 1, 0, projection.elem);
    [GLVEngine glError:GLVDebugFile];
    
    // pass vertex shader attributes
    glBindBuffer(GL_ARRAY_BUFFER, viewRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, viewRectIdx);
    glVertexAttribPointer(pScreenRender_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pScreenRender_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    [GLVEngine glError:GLVDebugFile];
    
    
    // draw image
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    [GLVEngine glError:GLVDebugFile];

        
    glBindTexture(GL_TEXTURE_2D, 0);   
    glDeleteTextures(1, &featID);
    [GLVEngine glError:GLVDebugFile];
    
    // present rendered buffer on screen
    glBindRenderbuffer(GL_RENDERBUFFER, rbColorScreen);
    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER];     
    [GLVEngine glError:GLVDebugFile];
    
    //glUseProgram(0);
    //glFinish();
    
}

- (void) renderPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return;
    }
    
    GLuint featID;
    
    // set up the view
    glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [GLVEngine glError:GLVDebugFile];
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    [GLVEngine glError:GLVDebugFile];
    
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
    [GLVEngine glError:GLVDebugFile];
    
    // pass projection uniform
    glUniformMatrix4fv(pScreenRender_uni_projection, 1, 0, projection.elem);
    [GLVEngine glError:GLVDebugFile];
    
    // pass vertex shader attributes
    glBindBuffer(GL_ARRAY_BUFFER, viewRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, viewRectIdx);
    glVertexAttribPointer(pScreenRender_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pScreenRender_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    [GLVEngine glError:GLVDebugFile];
    
    
    // draw image
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    [GLVEngine glError:GLVDebugFile];
    
    
    glBindTexture(GL_TEXTURE_2D, 0);   
    [GLVEngine glError:GLVDebugFile];
    
    // present rendered buffer on screen
    glBindRenderbuffer(GL_RENDERBUFFER, rbColorScreen);
    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER];     
    [GLVEngine glError:GLVDebugFile];
}

@end
