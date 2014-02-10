//
//  GLVViewCam.m
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 11/9/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVViewCam.h"

@implementation GLVViewCam

/**
    Initializer
    @param frame frame
    @return GLViewCam object
 */
-(id) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        pbTexture = NULL;
        pbTextureCacheRef = NULL;  
    }
    return self;
}

/**
    Be good with the environment
 */
-(void) dealloc
{
    if ([self havePixelBufferTexture])
        CFRelease(pbTexture);
    
    if ([self havePixelBufferTextureCache])
        CFRelease(pbTextureCacheRef);
}

/**
    Check for pixel buffer texture cache
    \return Do we have a texture cache?
 */
-(BOOL) havePixelBufferTextureCache
{
    return pbTextureCacheRef != NULL;
}

/**
    Create texture cache
 */
-(BOOL) createPixelBufferTextureCache
{
    if ([self havePixelBufferTextureCache])
        CFRelease(pbTextureCacheRef);
    
    CVReturn status;
    // create texture cache
    status = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, 
                                          NULL,//nil, 
                                          (__bridge CVEAGLContext)((__bridge void *)self.eaglContext), 
                                          NULL,//nil, 
                                          &pbTextureCacheRef);
    
    if (status != kCVReturnSuccess)
    {
        GLVDebugLog(@"ERROR: Could not create CVOpenGLESTextureCache (status = %d)", status);
        if ([self havePixelBufferTextureCache]) CFRelease(pbTextureCacheRef); // and delete if there is something for some random reason
        return NO;
    }
    
    return YES;
}

/**
    Check for pixel buffer texture
    \return Do we have a pixel buffer texture?
 */
-(BOOL) havePixelBufferTexture
{
    return pbTexture != NULL;
}
         
-(void) cleanUpPixelBufferTexture
{
    if (pbTexture)
    {
        CFRelease(pbTexture);
        pbTexture = NULL;
    }
    
    // periodic texture cache flush
    CVOpenGLESTextureCacheFlush(pbTextureCacheRef, 0);
}
   
-(BOOL) textureFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef pixelFormat:(GLenum)pixelFormat textureFormat:(GLint)textureFormat
{    
    if (![self havePixelBufferTextureCache] && ![self createPixelBufferTextureCache]) // !(!have => create)
    {
        GLVDebugLog(@"ERROR: Failed to create textureCache.");
        return NO;
    }
    
    // clean up for new data
    [self cleanUpPixelBufferTexture];
    
    // get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(pixelBufferRef); 
    size_t height = CVPixelBufferGetHeight(pixelBufferRef);
    
    // get texture from image data
    CVReturn status;
    status = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, 
                                                          pbTextureCacheRef, 
                                                          pixelBufferRef, 
                                                          NULL, 
                                                          GL_TEXTURE_2D, 
                                                          textureFormat, 
                                                          (int)width,
                                                          (int)height,
                                                          pixelFormat, 
                                                          GL_UNSIGNED_BYTE, 
                                                          0, 
                                                          &pbTexture);
    
    // and check for any error
    if (status != kCVReturnSuccess)
    {
        GLVDebugLog(@"ERROR: CVOpenGLESTextureCacheCreateTextureFromImage did not succeed (return status = %d)", status);
        return NO;
    }
    
#ifdef PERFORM_GL_CHECKS
    if ([GLVEngine glError:GLVDebugFile]) 
    {
        GLVDebugLog(@"ERROR: Could not get camera texture.");
        return NO;
    }
#endif
    
    return YES;
}


@end
