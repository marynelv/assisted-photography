//
//  GLVViewCam.h
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 11/9/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVView.h"

@interface GLVViewCam : GLVView
{
    CVOpenGLESTextureRef pbTexture;                 //!< pixel buffer texture
    CVOpenGLESTextureCacheRef pbTextureCacheRef;    //!< pixel buffer texture cache
}


-(BOOL) havePixelBufferTextureCache;
-(BOOL) createPixelBufferTextureCache;
-(BOOL) havePixelBufferTexture;
-(void) cleanUpPixelBufferTexture;
-(BOOL) textureFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef pixelFormat:(GLenum)pixelFormat textureFormat:(GLint)textureFormat;

@end
