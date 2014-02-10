//
//  GLVViewSaliency.m
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 11/7/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVViewSaliency.h"
#import "GLVEngine.h"

/** 4x4 Ortographic projection matrix (column-major order)
    @param left left border of the near area
    @param right right border of the near area
    @param bottom bottom border of the near area
    @param top top border of the near area
    @param near start of the depth of field
    @param far end of the depth of field
    @return ortographic camera matrix

    The rectanle formed by <a>left</a>, <a>right</a>, <a>bottom</a> and <a>top</a>
    will be size of the visible image area.
 
    @note matrix should be released by user with free
 */
static inline float * orthographic(float left, float right, float bottom, float top, float near, float far)
{
    float *matrix = (float *)malloc(sizeof(float)*16); // column-major order
    
    float r_l = right - left;
	float t_b = top - bottom;
	float f_n = far - near;
	float tx = - (right + left) / (right - left);
	float ty = - (top + bottom) / (top - bottom);
	float tz = - (far + near) / (far - near);
    
	matrix[0] = 2.0f / r_l;
	matrix[1] = 0.0f;
	matrix[2] = 0.0f;
	matrix[3] = 0.0f;
	
	matrix[4] = 0.0f;
	matrix[5] = 2.0f / t_b;
	matrix[6] = 0.0f;
	matrix[7] = 0.0f;
	
	matrix[8] = 0.0f;
	matrix[9] = 0.0f;
	matrix[10] = -2.0f / f_n;
	matrix[11] = 0.0f;
	
	matrix[12] = tx;
	matrix[13] = ty;
	matrix[14] = tz;
	matrix[15] = 1.0f;
    
    return matrix;
}

@implementation GLVViewSaliency
@synthesize pFeatures;
@synthesize maxProcessingSize;
@synthesize maxProcessingSize2;

/**
    \note Any dimension of <a>maxSize</a> should not exceed 2048 because of OpenGL limitations 
 */
-(id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize
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
        
        // create features program
        self.pFeatures = [[GLVProgramSaliencyFeatures alloc] init];
        if (!self.pFeatures)
        {
            GLVDebugLog(@"ERROR: Could not set up GLVProgramSaliencyFeatures.");
            self = nil;
            return self;
        }
        [self.pFeatures useProgram];
        [self.pFeatures enableAttributes];
        pFeatures_attr_position = [self.pFeatures attributeWithIndex:PROG_SALIENCYFEAT_ATTR_POSITION];
        pFeatures_attr_texCoord = [self.pFeatures attributeWithIndex:PROG_SALIENCYFEAT_ATTR_TEXCOORD];
        pFeatures_uni_projection = [self.pFeatures uniformWithIndex:PROG_SALIENCYFEAY_UNI_PROJECTION];
        pFeatures_uni_texture = [self.pFeatures uniformWithIndex:PROG_SALIENCYFEAT_UNI_TEXTURE];

        // set up maximum processing size (and its power of 2 equivalent)
        self.maxProcessingSize = maxSize;
//        self.maxProcessingSize2 = maxSize;
        unsigned int tmp1 = nextPowerOf2(maxSize.width), tmp2 = nextPowerOf2(maxSize.height);
        unsigned int greatestMaxSize2 = (tmp1 > tmp2 ? tmp1 : tmp2);
        self.maxProcessingSize2 = MakeGLVSize(greatestMaxSize2,greatestMaxSize2);
        
        // set up projection matrix
        pFeatures_projection_mat = orthographic(0, (int)self.maxProcessingSize2.width, (int)self.maxProcessingSize2.height, 0, 0, 1);
        
        // create image rectangle
        [GLVEngine setUpGenericRectTexWithSize:CGSizeMake(self.maxProcessingSize.width, self.maxProcessingSize.height) 
                                        origin:CGPointMake(0, 0) 
                                         array:&imageRect idxElementArray:&imageRectIdx];
        
        // set up frame buffer objects
        fboTexture = (GLuint *)calloc(GLVVSAL_FBO_TEXTURE_COUNT, sizeof(GLuint));
        glGenFramebuffers(GLVVSAL_FBO_TEXTURE_COUNT, fboTexture);
        
        // create features texture (level 0)
        featuresTexture.textureID = 0;
        featuresTexture.size = self.maxProcessingSize2; //self.maxProcessingSize;
        glActiveTexture(GL_TEXTURE0);
        glGenTextures(1, &(featuresTexture.textureID));
        glBindTexture(GL_TEXTURE_2D, featuresTexture.textureID);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)(featuresTexture.size.width), (int)(featuresTexture.size.height),
                     0, GL_RGBA, GL_HALF_FLOAT_OES, NULL);
        //glGenerateMipmap(GL_TEXTURE_2D);
        
//        if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) 
//        {
//            GLVDebugLog(@"ERROR: Could not set up saliency frame buffer (GLVVSAL_FBO_TEXTURE_1).");
//            self = nil;
//            return self;
//        }
        
        glBindTexture(GL_TEXTURE_2D, 0);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        
    }
    return self;
}

-(void) dealloc
{
    if (featuresTexture.textureID != 0)
    {
        glDeleteTextures(1, &(featuresTexture.textureID));
    }
    
    if (fboTexture)
    {
        glDeleteFramebuffers(GLVVSAL_FBO_TEXTURE_COUNT, fboTexture);
        free(fboTexture);
    }
    
    if (pFeatures_projection_mat)
        free(pFeatures_projection_mat);
}

-(BOOL) featuresFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef 
                        pixelFormat:(GLenum)pixelFormat textureFormat:(GLint)textureFormat
{    
    
#ifdef PERFORM_GL_CHECKS
    if ([GLVEngine glError:GLVDebugFile]) 
    {
        GLVDebugLog(@"ERROR: Error right after calling featuresFromPixelBuffer");
        return NO;
    }
#endif
    
    // set up floating point FBO for saliency feature computation
    glBindFramebuffer(GL_FRAMEBUFFER, fboTexture[GLVVSAL_FBO_TEXTURE_1]); 
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 
                           featuresTexture.textureID, 0); 
    
    glViewport(0, 0, (int)(featuresTexture.size.width), (int)(featuresTexture.size.height));
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
    
    [self.pFeatures useProgram];
    
    glBindBuffer(GL_ARRAY_BUFFER, imageRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, imageRectIdx);
    glVertexAttribPointer(pFeatures_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pFeatures_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    
    glUniformMatrix4fv(pFeatures_uni_projection, 1, 0, pFeatures_projection_mat);
    
#ifdef PERFORM_GL_CHECKS
    if ([GLVEngine glError:GLVDebugFile]) 
    {
        GLVDebugLog(@"ERROR: Could not set up camera image as uniform.");
        return NO;
    }
#endif    
    
    // get pixelbuffer texture
    glActiveTexture(GL_TEXTURE1);
    [self textureFromPixelBuffer:pixelBufferRef pixelFormat:GL_BGRA textureFormat:GL_RGBA];
    // and assign it to saliency features shader uniform
    GLuint pixelBufferTexture = CVOpenGLESTextureGetName(pbTexture);
    glBindTexture(GL_TEXTURE_2D, pixelBufferTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
    glUniform1i(pFeatures_uni_texture, 1); // GL_TEXTURE1
    
#ifdef PERFORM_GL_CHECKS
    if ([GLVEngine glError:GLVDebugFile]) 
    {
        GLVDebugLog(@"ERROR: Could not set up camera image as uniform.");
        return NO;
    }
#endif
    
    // generate features 
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    //glFlush();
    
#ifdef PERFORM_GL_CHECKS
    if ([GLVEngine glError:GLVDebugFile]) 
    {
        GLVDebugLog(@"ERROR: Could not render features.");
        return NO;
    }
#endif
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
    
    return YES;
}

-(BOOL) generateFeaturesPyramid
{
    
#ifdef PERFORM_GLV_INTERNAL_CHECKS
    if (featuresTexture.textureID == 0)
    {
        GLVDebugLog(@"ERROR: Features texture does not exist.");
        return NO;
    }
#endif
    
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, featuresTexture.textureID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
//    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST_MIPMAP_NEAREST); 
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST); 
    glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
    glGenerateMipmap(GL_TEXTURE_2D);
    
#ifdef PERFORM_GL_CHECKS
    if ([GLVEngine glError:GLVDebugFile]) 
    {
        GLVDebugLog(@"ERROR: Could not generate features' mipmap.");
        return NO;
    }
#endif
    
    return YES;
}

@end
