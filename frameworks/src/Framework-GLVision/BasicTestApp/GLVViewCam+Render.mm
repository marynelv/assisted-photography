//
//  GLVView+Camera.m
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 10/30/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVViewCam+Render.h"
#import <GLVision/GLVPrograms.h>
#import "TimeIntervalTracker.h"

static Matrix4 projection;
static CGSize imageSize;

static GLVProgramGray *program;

static GLuint attr_position;
static GLuint attr_texCoord;
static GLuint uni_projection;
static GLuint uni_texture;

static TimeIntervalTracker *timeTracker;

@implementation GLVViewCam (Render)

-(id) initWithFrame:(CGRect)frame ImageSize:(CGSize)size projectionMat:(Matrix4 *)mat
{
    self = [self initWithFrame:frame];
    if (self)
    {        
        [self setUpImageSize:size];
        [self setUpProjectionMat:mat];
        
        // creates and links shaders program
//        GLVProgramTexture *program = [[GLVProgramTexture alloc] init];
        program = [[GLVProgramGray alloc] init];
        if (!program)
        {
            GLVDebugLog(@"ERROR: Could not set up GLVProgramHandler.");
            self = nil;
            return self;
        }       
        timeTracker = new TimeIntervalTracker();
    }
    return self;
}

-(void) dealloc
{
    delete timeTracker;
}

-(void) setUpImageSize:(CGSize)size
{
    imageSize = size;
}

-(void) setUpProjectionMat:(Matrix4 *)mat
{
    if (mat != NULL && mat != 0)
        projection = *mat; 
    else
        GLVDebugLog(@"Invalid projection matrix.");
}

-(GLVProgramHandler *) programTexture
{
    return program;
}

-(void) setUpAttributesAndUniforms
{
    GLVProgramHandler *program = [self programTexture];
    [program useProgram];
    
    attr_position = [program attributeWithIndex:PROG_GRAY_ATTR_POSITION];
    attr_texCoord = [program attributeWithIndex:PROG_GRAY_ATTR_TEXCOORD];
    uni_projection = [program uniformWithIndex:PROG_GRAY_UNI_PROJECTION];
    uni_texture = [program uniformWithIndex:PROG_GRAY_UNI_TEXTURE];
//    attr_position = [program attributeWithIndex:PROG_TEXTURE_ATTR_POSITION];
//    attr_texCoord = [program attributeWithIndex:PROG_TEXTURE_ATTR_TEXCOORD];
//    uni_projection = [program uniformWithIndex:PROG_TEXTURE_UNI_PROJECTION];
//    uni_texture = [program uniformWithIndex:PROG_TEXTURE_UNI_TEXTURE];
    
    [program enableAttributes];
//    // attributes
//    attr_position = [program attributeIndex:"position"];
//    attr_texCoord = [program attributeIndex:"texCoordIn"];
//    glEnableVertexAttribArray(attr_position);
//    glEnableVertexAttribArray(attr_texCoord);
//    
//    // uniforms
//    uni_projection = [program uniformIndex:"projection"];
//    uni_texture = [program uniformIndex:"texture"];
}

-(void) setUpVertexBufferObjects
{
    // set up vertex buffer objects
    GLuint camRect = 0, rectIdx = 0;
    [GLVEngine setUpGenericRectTexWithSize:self.frame.size origin:CGPointMake(0,0) array:&camRect idxElementArray:&rectIdx]; 
    [self.glvEngine storeBufferObjectID:camRect];
    [self.glvEngine storeBufferObjectID:rectIdx];
}

-(BOOL) renderCVPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{
    [GLVEngine glError:GLVDebugFile];
    
//    NSLog(@"attr_position=%u attr_texCoord=%u uni_projection=%u uni_texture=%u", 
//          attr_position, attr_texCoord, uni_projection, uni_texture);
    
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return NO;
    }
    
    // clear frame buffer
    glBindRenderbuffer(GL_RENDERBUFFER, [self colorRenderBuffer]);
    glBindFramebuffer(GL_FRAMEBUFFER, [self mainFrameBuffer]);
    glClearColor(0.7, 0.5, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT); //glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
    [GLVEngine glError:GLVDebugFile];
    
    // set up view
    glUniformMatrix4fv(uni_projection, 1, 0, projection.elem);
    [GLVEngine glError:GLVDebugFile];
    
    // set view
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    [GLVEngine glError:GLVDebugFile];
    
    //    GLuint cameraViewRect = [self.glvEngine bufferObjectID:BO_CAMERAVIEWRECT];
    //    GLuint cameraViewRectIdx = [self.glvEngine bufferObjectID:BO_RECTIND];
    //    //glBindBuffer(GL_ARRAY_BUFFER, cameraViewRect);
    //    [GLVEngine glError:GLVDebugFile];
    
    glVertexAttribPointer(attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    [GLVEngine glError:GLVDebugFile];
    
    
    // set up texture to be drawn
    // NOTE: We don't need glEnable(GL_TEXTURE_2D) because we are writing the shader so we decide
    // directly which texture units we are going to reference!
    glActiveTexture(GL_TEXTURE0);
    [self textureFromPixelBuffer:pixelBufferRef pixelFormat:GL_BGRA textureFormat:GL_RGBA];
    GLuint texture = CVOpenGLESTextureGetName(pbTexture);
//    GLuint texture = [GLVCamera texture2DFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef
//                                             pixelFormat:GL_BGRA textureFormat:GL_RGBA 
//                                             eaglContext:self.eaglContext];
//    
    if (texture == 0)
    {
        GLVDebugLog(@"ERROR: Could not create GL texture from camera image.");
        return NO;
    }
//    else
//    {
//        NSLog(@"texture: %d", texture);
//    }
    
    glBindTexture(GL_TEXTURE_2D, texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    [GLVEngine glError:GLVDebugFile];
    
    // set up texture uniform
    glUniform1i(uni_texture, 0); // GL_TEXTURE0
    [GLVEngine glError:GLVDebugFile];
    
    // draw image
    //    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cameraViewRectIdx);
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    [GLVEngine glError:GLVDebugFile];
    
    // unbind texture
    glBindTexture(GL_TEXTURE_2D, 0);   
    [GLVEngine glError:GLVDebugFile];
    
    // present rendered buffer on screen
    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER]; 
    [GLVEngine glError:GLVDebugFile];
    
    timeTracker->update(CACurrentMediaTime());
    
    return YES;    
    
}

@end
