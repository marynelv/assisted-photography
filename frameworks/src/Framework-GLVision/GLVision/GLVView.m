//
//  GLView.m
//  AudiballMix
//
//    Created by Marynel Vazquez on 10/1/11.
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

#import "GLVView.h"

@implementation GLVView
@synthesize glvEngine;
@synthesize eaglLayer;
@synthesize eaglContext;

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

/**
    Initializer
    @param frame frame
    @return GLView object
    Sets up the framebuffer and the colorRenderBuffer
 */
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        // Initialization code
        self.eaglLayer = (CAEAGLLayer*)self.layer;
        [self.eaglLayer setOpaque:YES];        
        self.eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                             [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking,
                                             kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
        self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if (!self.eaglContext || ![EAGLContext setCurrentContext:self.eaglContext])
        {
            GLVDebugLog(@"Could not set up OpenGLES 2 context.");
            self = nil;
        }
        else
        {
            rbColorScreen = 0;
            fboScreen = 0;
            
            // set up render buffer (storage is as needed by the custom EAGLLayer)
            glGenRenderbuffers(1, &rbColorScreen);
            glBindRenderbuffer(GL_RENDERBUFFER, rbColorScreen);
            [self.eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
            
            // set up frame buffer
            glGenFramebuffers(1, &fboScreen);
            glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
            glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, 
                                      GL_RENDERBUFFER, fboScreen);
            
            if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) 
            {
                GLVDebugLog(@"ERROR: Could not set up frame buffer for screen rendering.");
                self = nil;
                return self;
            }
            
            self.glvEngine = [[GLVEngine alloc] initWithFrameBuffer:fboScreen colorRenderBuffer:rbColorScreen];
        }  
        
    }
    return self;
}

/**
    Cleans up OpenGLES 2.0 
 */
-(void) dealloc
{    
    if (rbColorScreen != 0) glDeleteRenderbuffers(1, &rbColorScreen);
    if (fboScreen != 0) glDeleteFramebuffers(1, &fboScreen);
    
    // discard GLVision engine
    [self.glvEngine clear];
}

/**
    Main frame buffer (set up by default)
    @return frame buffer id
 */
-(GLuint) mainFrameBuffer
{
    return fboScreen;
}

/**
    Main render buffer (to be displayed on the screen)
    @return color render buffer id
 */
-(GLuint) colorRenderBuffer
{
    return rbColorScreen;
}

@end
