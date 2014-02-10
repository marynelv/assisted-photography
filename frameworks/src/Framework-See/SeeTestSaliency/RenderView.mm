//
//  RenderView.m
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "RenderView.h"
#import <See/ImageSaliency.h>
#import <Accelerate/Accelerate.h>

static Matrix4 projection;

@implementation RenderView 
@synthesize pTexture;

- (id) initWithFrame:(CGRect)frame imageSize:(CGSize)size projectionMat:(Matrix4 *)mat
{
    self = [super initWithFrame:frame maxProcessingSize:MakeGLVSize(size.width, size.height)];
    if (self)
    {
        
        // set up rectangled to be rendered
        camRect = 0; rectIdx = 0;
        [self setUpBufferObjects];
        
        // creates and links shaders program
        self.pTexture = [[GLVProgramTexture alloc] init];
        if (!self.pTexture)
        {
            NSLog(@"ERROR: Could not set up texture program shader.");
            self = nil;
            return self;
        }
        [self.pTexture useProgram];
        attr_position = [self.pTexture attributeWithIndex:PROG_TEXTURE_ATTR_POSITION];
        attr_texCoord = [self.pTexture attributeWithIndex:PROG_TEXTURE_ATTR_TEXCOORD];
        uni_projection = [self.pTexture uniformWithIndex:PROG_TEXTURE_UNI_PROJECTION];
        uni_texture = [self.pTexture uniformWithIndex:PROG_TEXTURE_UNI_TEXTURE];
        [self.pTexture enableAttributes];
        
        if (mat != NULL && mat != 0)
            projection = *mat; 
        else
            NSLog(@"ERROR: Invalid projection matrix");
    }
    return self;
}

- (void) setUpBufferObjects
{
    [GLVEngine setUpGenericRectTexWithSize:self.frame.size origin:CGPointMake(0,0) 
                                     array:&camRect idxElementArray:&rectIdx]; 
    [self.glvEngine storeBufferObjectID:camRect];
    [self.glvEngine storeBufferObjectID:rectIdx];     
}

- (img) glSaliencyFromPixelBufferRef:(CVPixelBufferRef)pixelBufferRef width:(size_t *)w height:(size_t *)h 
                              pyrLev:(int)pyrLev surrLev:(int)surrLev
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
// Keep the non-optimized version of the copying procedure for debugging purposes...
//        float * src = features + (featuresTexture.size.height - 1 - r)*4*featuresTexture.size.width + 
//                      self.maxProcessingSize.width*4 - 4;
//        for(int i=0; i<self.maxProcessingSize.width; i++)
//        {
//            img tmp = src + i*(-4);
//            featInt[r + self.maxProcessingSize.height*i] = *tmp;
//            tmp = tmp + 1;
//            featRG[r + self.maxProcessingSize.height*i] = *tmp;
//            tmp = tmp + 1;
//            featBY[r + self.maxProcessingSize.height*i] = *tmp;
//        }
        
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

- (void) renderCVPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{
    //[GLVEngine glError:GLVDebugFile];

    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return;
    }
    
    // clear frame buffer
//    glBindRenderbuffer(GL_RENDERBUFFER, [self colorRenderBuffer]);
    glBindFramebuffer(GL_FRAMEBUFFER, [self mainFrameBuffer]);
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT); //glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    //[GLVEngine glError:GLVDebugFile];
    
    // set view
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    //[GLVEngine glError:GLVDebugFile];

    [self.pTexture useProgram];
    
    // set up view
    glUniformMatrix4fv(uni_projection, 1, 0, projection.elem);
    //[GLVEngine glError:GLVDebugFile];
    
    glBindBuffer(GL_ARRAY_BUFFER, camRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, rectIdx);
    glVertexAttribPointer(attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    //[GLVEngine glError:GLVDebugFile];
    
    // work with camera texture
    glActiveTexture(GL_TEXTURE1);
    if (![self textureFromPixelBuffer:pixelBufferRef 
                          pixelFormat:GL_BGRA textureFormat:GL_RGBA])
    {
        GLVDebugLog(@"An error ocurred while trying to create texture from pixel buffer.");
    }
    //[GLVEngine glError:GLVDebugFile];
    
    GLuint texture = CVOpenGLESTextureGetName(pbTexture);
    if (texture == 0)
    {
        GLVDebugLog(@"ERROR: Invalid GL texture from camera image.");
        return;
    }
    //[GLVEngine glError:GLVDebugFile];
    
    // set up texture to be drawn
    // NOTE: We don't need glEnable(GL_TEXTURE_2D) because we are writing the shader so we decide
    // directly which texture units we are going to reference!
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //[GLVEngine glError:GLVDebugFile];
    
    // set up texture uniform
    glUniform1i(uni_texture, 1); // GL_TEXTURE0
    //[GLVEngine glError:GLVDebugFile];
    
    // draw image
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    //[GLVEngine glError:GLVDebugFile];
    
    // unbind texture
    glBindTexture(GL_TEXTURE_2D, 0);   
    //[GLVEngine glError:GLVDebugFile];
        
    // present rendered buffer on screen
    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER]; 
    //[GLVEngine glError:GLVDebugFile];
}

@end
