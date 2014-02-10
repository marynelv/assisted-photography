//
//  RenderedCameraView+Shaders.m
//  AudiballMix
//
//  Created by Marynel Vazquez on 10/25/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "RenderedCameraView+Shaders.h"
#import <GLVision/GLVPrograms.h>
//#import <GLVision/GLVCamera.h>
#import <BasicMath/Matrix4.h>

///**
//   View rectangle
// */
//static Vertex3Tex rectangle[] = {
//    {{ 1, -1, 0}, {1,0}},   // vertex: bottom-right corner  tex: 
//    {{ 1,  1, 0}, {0,0}},   // vertex: top-right corner     tex:
//    {{-1,  1, 0}, {0,1}},   // vertex: top-left corner      tex:
//    {{-1, -1, 0}, {1,1}}    // vertex: buttom-left corner   tex:
//};
//
///**
//    Rectangle indices (for the triangles to be drawn)
// */
//static GLubyte rectangleIndices[] = {
//  0, 1, 2,
//  2, 3, 0
//};

@implementation RenderedCameraView (Shaders)



//-(BOOL) renderCameraViewWithPixelBuffer:(CVPixelBufferRef)pixelBufferRef//WithTexture:(GLuint)texture
//{
//    [GLVEngine glError:GLVDebugFile];
//    
//    if (![EAGLContext setCurrentContext:self.eaglContext])
//    {
//        DebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
//        return NO;
//    }
//    
//    GLVProgramHandler *programTexture = [self.glvEngine programHandler:SHADER_CAMERAVIEW];
//    [programTexture useProgram];
//    [programTexture enableAttributes];
////    [GLVEngine glError:GLVDebugFile];
//    
//    GLuint *progTextureAttr = 0, *progTextureUni = 0;
//    [programTexture allAttributeIndices:&progTextureAttr];
//    [programTexture allUniformIndices:&progTextureUni];
//    [GLVEngine glError:GLVDebugFile];
//    
//    // clear frame buffer
//    glBindRenderbuffer(GL_RENDERBUFFER, [self colorRenderBuffer]);
//    glBindFramebuffer(GL_FRAMEBUFFER, [self mainFrameBuffer]);
//    glClearColor(0.7, 1.0, 1.0, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT); //glClear(GL_DEPTH_BUFFER_BIT | GL_COLOR_BUFFER_BIT);
//    [GLVEngine glError:GLVDebugFile];
//    
//    // set up view
//    Matrix4 projectionMat =  Matrix4::orthographic(0, self.frame.size.width, self.frame.size.height, 0, 0, 1); 
////    Matrix4 projectionMat =  Matrix4::orthographic(0, self.imageSize.width, self.imageSize.height, 0, 0, 3); 
//    glUniformMatrix4fv(progTextureUni[PROG_TEXTURE_UNI_PROJECTION], 1, 0, projectionMat.elem);
//    [GLVEngine glError:GLVDebugFile];
//    
//    // set view
//    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
//    [GLVEngine glError:GLVDebugFile];
//    
////    GLuint cameraViewRect = [self.glvEngine bufferObjectID:BO_CAMERAVIEWRECT];
////    GLuint cameraViewRectIdx = [self.glvEngine bufferObjectID:BO_RECTIND];
////    //glBindBuffer(GL_ARRAY_BUFFER, cameraViewRect);
////    [GLVEngine glError:GLVDebugFile];
//    
//    glVertexAttribPointer(progTextureAttr[PROG_TEXTURE_ATTR_POSITION], 3, GL_FLOAT, 
//                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
//    glVertexAttribPointer(progTextureAttr[PROG_TEXTURE_ATTR_TEXCOORD], 2, GL_FLOAT, 
//                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
//    [GLVEngine glError:GLVDebugFile];
//    
//    GLuint texture = [GLVCamera texture2DFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef
//                                             pixelFormat:GL_BGRA textureFormat:GL_RGBA 
//                                             eaglContext:self.eaglContext];
//    
//    if (texture == 0)
//    {
//        DebugLog(@"ERROR: Could not create GL texture from camera image.");
//        return NO;
//    }
////    else
////    {
////        NSLog(@"texture: %d", texture);
////    }
//
//    // set up texture to be drawn
//    // NOTE: We don't need glEnable(GL_TEXTURE_2D) because we are writing the shader so we decide
//    // directly which texture units we are going to reference!
//    glActiveTexture(GL_TEXTURE0);
//    glBindTexture(GL_TEXTURE_2D, texture);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
//    [GLVEngine glError:GLVDebugFile];
//    
//    // set up texture uniform
//    glUniform1i(progTextureUni[PROG_TEXTURE_UNI_TEXTURE], 0); // GL_TEXTURE0
//    [GLVEngine glError:GLVDebugFile];
//    
//    // draw image
////    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, cameraViewRectIdx);
//    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
//    [GLVEngine glError:GLVDebugFile];
//    
//    // unbind texture
//    glBindTexture(GL_TEXTURE_2D, 0);   
//    [GLVEngine glError:GLVDebugFile];
//    
//    glDeleteTextures(1, &texture); 
//    [GLVEngine glError:GLVDebugFile];
//    
//    // present rendered buffer on screen
//    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER]; 
//    [GLVEngine glError:GLVDebugFile];
//    
//    return YES;    
//}



/**
    Set up gray shader program
    @return did we set up the gray shader appropriately?
 */
-(BOOL) setUpGrayShader
{
    // create gray shader
    GLVProgramGray *programGray = [[GLVProgramGray alloc] init];
    if (!programGray)
    {            
        DebugLog(@"ERROR: Could not set up gray shader");
        return NO;
    }
    [self.glvEngine storeProgramHandler:programGray];
    return YES;
}

-(void) renderGray
{
    GLVProgramHandler *programGray = [self.glvEngine programHandler:SHADER_GRAY];
    
    // attributes/uniforms
    GLuint *grayAttr = 0, *grayUni = 0;
    [programGray allAttributeIndices:&grayAttr];
    [programGray allUniformIndices:&grayUni];
    [programGray enableAttributes];
    
    glVertexAttribPointer(grayAttr[PROG_GRAY_ATTR_POSITION], 3, GL_FLOAT, GL_FALSE, sizeof(Vertex3Tex), 0);
    glVertexAttribPointer(grayAttr[PROG_GRAY_ATTR_TEXCOORD], 2, GL_FLOAT, GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    
    
}

@end
