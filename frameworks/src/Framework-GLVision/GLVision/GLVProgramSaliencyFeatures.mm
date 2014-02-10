//
//  GLVProgramSaliencyFeatures.m
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 11/7/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVProgramSaliencyFeatures.h"
#import "GLVEngine.h"
#import "GLVCommon.h"

@implementation GLVProgramSaliencyFeatures

/**
 Creates shader and stores internal reference to attributes and uniforms
 */
-(id) init
{
    self = [super initWithVertexShaderFilename:@"texturedProjection" 
                        fragmentShaderFilename:@"saliencyFeatures"];
    if (self)
    {
        attr = new GLuint[PROG_SALIENCYFEAT_ATTR_NUM];
        uni = new GLuint[PROG_SALIENCYFEAT_UNI_NUM];
        memset(attr, 0, sizeof(GLuint)*PROG_SALIENCYFEAT_ATTR_NUM);
        memset(uni, 0, sizeof(GLuint)*PROG_SALIENCYFEAT_UNI_NUM);
        
        BOOL linkOK;
#ifdef PERFORM_GL_CHECKS
        linkOK = [self linkProgamAndValidate:YES];
#else
        linkOK = [self linkProgamAndValidate:NO];
#endif
        if (!linkOK)
        {
            GLVDebugLog(@"ERROR: Could not link %@'s program.", [[self class] description]);
            self = nil;
        }
        
        //[self useProgram];
        [self setUpAttributesAndUniforms];
    }
    return self;
}

/**
 Discards attributes/uniforms array
 */
-(void) dealloc
{
    if (attr) delete[] attr;
    if (uni) delete[] uni;
}

/**
 Set up program's attribues and uniforms
 */
-(void) setUpAttributesAndUniforms
{    
    [self useProgram];
    
    // attributes
    attr[PROG_SALIENCYFEAT_ATTR_POSITION] = [self attributeIndex:"position"];
    //glEnableVertexAttribArray(attr[PROG_TEXTURE_ATTR_POSITION]);
    attr[PROG_SALIENCYFEAT_ATTR_TEXCOORD] = [self attributeIndex:"texCoordIn"];
    //glEnableVertexAttribArray(attr[PROG_TEXTURE_ATTR_TEXCOORD]);
    
    // uniforms
    uni[PROG_SALIENCYFEAY_UNI_PROJECTION] = [self uniformIndex:"projection"];
    uni[PROG_SALIENCYFEAT_UNI_TEXTURE] = [self uniformIndex:"texture"];
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

/**
 Enable program attributes
 */
-(void) enableAttributes
{  
    //    NSLog(@"attr_pos=%u | attr_texcoord=%u", attr[PROG_TEXTURE_ATTR_POSITION], attr[PROG_TEXTURE_ATTR_TEXCOORD]);
    glEnableVertexAttribArray(attr[PROG_SALIENCYFEAT_ATTR_POSITION]);
    glEnableVertexAttribArray(attr[PROG_SALIENCYFEAT_ATTR_TEXCOORD]);
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

/**
    Disable program attributes
 */
-(void) disableAttributes
{
    glDisableVertexAttribArray(attr[PROG_SALIENCYFEAT_ATTR_POSITION]);
    glDisableVertexAttribArray(attr[PROG_SALIENCYFEAT_ATTR_TEXCOORD]);
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

/**
 Array with all attribute indices
 @param indices output parameter with attribute indices according to <a>GLVPROG_TEXTURE_ATTR</a>
 @return number of elements in attribute indices array
 
 The output parameter <a>indices</a> will point to the internal array of attributes.
 
 @note Do NOT modify the elements of the indices array ever! Do not delete the array. 
 */
-(int) allAttributeIndices:(GLuint **)indices
{
    if (indices == NULL || indices == 0)
    {
        GLVDebugLog(@"Warning: pointer to indices array is invalid.");
        return 0;
    }
    
    *indices = attr;
    return PROG_SALIENCYFEAT_ATTR_NUM;
}

/**
 Array with all uniform indices
 @param indices output parameter with uniform indices according to <a>GLVPROG_TEXTURE_UNI</a>
 @return number of elements in uniform indices array
 
 The output parameter <a>indices</a> will point to the internal array of attributes.
 
 @note Do NOT modify the elements of the indices array ever! Do not delete the array.
 */
-(int) allUniformIndices:(GLuint **)indices
{
    if (indices == NULL || indices == 0)
    {
        GLVDebugLog(@"Warning: pointer to indices array is invalid.");
        return 0;
    }
    
    *indices = uni;    
    return PROG_SALIENCYFEAT_UNI_NUM;
}

/**
 Get attribute id for a given index in the attributes array
 @param index attribute index in attributes array
 @return attribute id
 @note 0 should be returned by the subclass if <a>index</a> is invalid
 */
-(GLuint) attributeWithIndex:(int)index
{
    if (index < 0 || index > PROG_SALIENCYFEAT_ATTR_NUM)
        return 0;
    return attr[index];
}

/**
 Get uniform id for a given index in the uniforms array
 @param index uniform index in attributes array
 @return uniform id
 @note 0 should be returned by the subclass if <a>index</a> is invalid
 */
-(GLuint) uniformWithIndex:(int)index
{
    if (index < 0 || index > PROG_SALIENCYFEAT_UNI_NUM)
        return 0;
    return uni[index]; 
}

/**
 Render texture to another texture (this sounds like copying a texture to another texture)
 @param storage reserved texture space id, or 0 if new texture needs allocation
 @param size storage size (or NULL if storage is 0)
 
 Two attributes need to be set before hand: <a>attr_position</a> and <a>attr_texCoord</a>, each 
 corresponding to the array buffer (rectangle vertices) and element array (vertices indices)
 of the image structure to be rendered. 
 
 The uniform <a>projection</a> must be set  with an orthographic projection that allows to 
 draw the image through the GPU. Likewise, the uniform <a>texture</a> must be set with the
 incoming image to be processed.
 
 @todo implement
 */
-(void) renderToTextureStorage:(GLuint*)storage size:(CGSize*)size
{  
    
    [NSException raise:NSInternalInconsistencyException 
                format:@"Method %@ has not been implemented yet.", NSStringFromSelector(_cmd)];
}

@end
