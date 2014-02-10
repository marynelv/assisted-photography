//
//  RenderView.m
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "RenderView.h"
#import <GLVision/GLVCommon.h>
#import <See/ImageConversion.h>
#import <See/ImageBlurriness.h>
#import <DataLogging/DLTiming.h>

inline float maxi(int a, int b){ return (a > b ? a : b); }
inline float mini(int a, int b){ return (a < b ? a : b); }

@implementation RenderView
@synthesize delegate;

-(void) dealloc
{
    self.delegate = nil;
}

- (img) intensityFromResizedGray
{    
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return 0;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, fboResize); 
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 
                           resizeTexture.textureID, 0);
    
    GLubyte *resizedData = getRedUByteDataFromFBOTexture(0, 0, resizeTexture.size.width, resizeTexture.size.height);
    [GLVEngine glError:GLVDebugFile];
    
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


-(void) processPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{
    // resize pixel buffer
    [self resizePixelBufferAndConvertToGray:pixelBufferRef];
    
    // compute blurry level
    img gray = [self intensityFromResizedGray];
    if (gray == 0)
    {
        NSLog(@"ERROR: Could not convert pixelBuffer to img!");
        return;
    }
    
    float b = perceptualBlurMetric(gray, resizeTexture.size.width, resizeTexture.size.height, 
                                   resizeTexture.size.width, FILTER_AVERAGE5, FSIZE_AVERAGE5);
    
    free(gray);
    
    if ([(NSObject*)self.delegate respondsToSelector:@selector(updateBlurryEstimation:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate updateBlurryEstimation:b];
        });
    }
    
    // render result
    [self drawResizedGrayOnScreen];
}

@end
