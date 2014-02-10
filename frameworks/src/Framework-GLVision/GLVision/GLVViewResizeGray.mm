//
//  GLVViewResizeGray.m
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 3/1/12.
//  Copyright (c) 2012 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVViewResizeGray.h"
#import "GLVEngine.h"

@implementation GLVViewResizeGray
@synthesize pResize;
@synthesize pScreenRender;
@synthesize maxProcessingSize;

/** Init View Resize Gray with a given frame and maximum processing size
    \param frame view frame
    \param maxSize maximum processing size
    \return GLVViewResizeGray instance
 */
- (id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize
{
    self = [super initWithFrame:frame]; 
    if (self)
    {        
        if (maxSize.width > 2048 || maxSize.height > 2048)
        {
            GLVDebugLog(@"ERROR: Processing size exceeds limits.");
            self = nil;
            return self;
        }

        // set up maximum processing size (and its power of 2 equivalent)
        self.maxProcessingSize = maxSize;
        
        // set up buffer objects
        [self setUpBufferObjects];
        
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
        
        renderProjection = Matrix4::orthographic(0, self.frame.size.width, self.frame.size.height, 0, 0, 1); 
        
        glGenFramebuffers(1, &fboResize);
        
        self.pResize = [[GLVProgramGray alloc] init];
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
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, (int)(resizeTexture.size.width), (int)(resizeTexture.size.height),
                     0, GL_RED_EXT, GL_UNSIGNED_BYTE, NULL);
        
        
        // set up rectangled to be rendered
        [self setUpBufferObjects];

        
    }
    return self;

}

- (void) dealloc
{
    if (fboResize) glDeleteFramebuffers(1, &fboResize);
    
}

- (void) setUpBufferObjects
{
    viewRect = 0, viewRectIdx = 0;
    [GLVEngine setUpGenericRectTexInvWithSize:self.frame.size origin:CGPointMake(0,0) 
                                     array:&viewRect idxElementArray:&viewRectIdx]; 

    [GLVEngine setUpGenericRectTexWithSize:CGSizeMake(self.maxProcessingSize.width, self.maxProcessingSize.height) 
                                    origin:CGPointMake(0, 0) 
                                     array:&resizeRect idxElementArray:NULL];
}

- (BOOL) resizePixelBufferAndConvertToGray:(CVPixelBufferRef)pixelBufferRef;
{    
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return NO;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, fboResize); 
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 
                           resizeTexture.textureID, 0); 
    
    glViewport(0, 0, (int)(resizeTexture.size.width), (int)(resizeTexture.size.height));
    
    [self.pResize useProgram];
    
    glBindBuffer(GL_ARRAY_BUFFER, resizeRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, viewRectIdx);
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
    [GLVEngine glError:GLVDebugFile];
    
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    [GLVEngine glError:GLVDebugFile];
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
    
    return YES;
}

-(BOOL) drawResizedGrayOnScreen
{
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return NO;
    }

    // set up the view
    glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [GLVEngine glError:GLVDebugFile];
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    [GLVEngine glError:GLVDebugFile];
    
    [self.pScreenRender useProgram];
    
    // pass texture uniform
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, resizeTexture.textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(pScreenRender_uni_texture, 0); // GL_TEXTURE0
    [GLVEngine glError:GLVDebugFile];
    
    // pass projection uniform
    glUniformMatrix4fv(pScreenRender_uni_projection, 1, 0, renderProjection.elem);
    [GLVEngine glError:GLVDebugFile];
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
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
    
    // be good and unbind
    glBindTexture(GL_TEXTURE_2D, 0);   
    [GLVEngine glError:GLVDebugFile];
    
    // present rendered buffer on screen
    glBindRenderbuffer(GL_RENDERBUFFER, rbColorScreen);
    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER];     
    [GLVEngine glError:GLVDebugFile];
    
    return YES;
}


- (void) processPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{
    [self resizePixelBufferAndConvertToGray:pixelBufferRef];
    [self drawResizedGrayOnScreen];
}

@end
