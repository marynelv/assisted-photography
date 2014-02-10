//
//  GLVProgramGray.m
//  Framework-GLVision
//
//    Created by Marynel Vazquez on 10/24/11.
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

#import "GLVProgramGray.h"
#import "GLVEngine.h"
#import "GLVCommon.h"

@implementation GLVProgramGray

/**
    Creates shader and stores internal reference to attributes and uniforms
 */
-(id) init
{
    self = [super initWithVertexShaderFilename:@"texturedProjection" 
                        fragmentShaderFilename:@"gray"];
    if (self)
    {
        attr = new GLuint[PROG_GRAY_ATTR_NUM];
        uni = new GLuint[PROG_GRAY_UNI_NUM];
        memset(attr, 0, sizeof(GLuint)*PROG_GRAY_ATTR_NUM);
        memset(uni, 0, sizeof(GLuint)*PROG_GRAY_UNI_NUM);
        
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
    attr[PROG_GRAY_ATTR_POSITION] = [self attributeIndex:"position"];
    attr[PROG_GRAY_ATTR_TEXCOORD] = [self attributeIndex:"texCoordIn"];
    
    // uniforms
    uni[PROG_GRAY_UNI_PROJECTION] = [self uniformIndex:"projection"];
    uni[PROG_GRAY_UNI_TEXTURE] = [self uniformIndex:"texture"];

#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

/**
    Enable program attributes
 */
-(void) enableAttributes
{  
    glEnableVertexAttribArray(attr[PROG_GRAY_ATTR_POSITION]);
    glEnableVertexAttribArray(attr[PROG_GRAY_ATTR_TEXCOORD]);
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

/**
    Disable program attributes
 */
-(void) disableAttributes
{
    glDisableVertexAttribArray(attr[PROG_GRAY_ATTR_POSITION]);
    glDisableVertexAttribArray(attr[PROG_GRAY_ATTR_TEXCOORD]);
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

/**
    Array with all attribute indices
    @param indices output parameter with attribute indices according to <a>GLVPROG_GRAY_ATTR</a>
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
    return PROG_GRAY_ATTR_NUM;
}

/**
    Array with all uniform indices
    @param indices output parameter with uniform indices according to <a>GLVPROG_GRAY_UNI</a>
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
    return PROG_GRAY_UNI_NUM;
}

/**
    Get attribute id for a given index in the attributes array
    @param index attribute index in attributes array
    @return attribute id
    @note 0 should be returned by the subclass if <a>index</a> is invalid
 */
-(GLuint) attributeWithIndex:(int)index
{
    if (index < 0 || index > PROG_GRAY_ATTR_NUM)
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
    if (index < 0 || index > PROG_GRAY_UNI_NUM)
        return 0;
    return uni[index]; 
}

/**
    Merge color texture channels into gray image
    @param storage reserved texture space id, or 0 if new texture needs allocation
    @param size storage size (or NULL if storage is 0)
 
    Two attributes need to be set before hand: <a>attr_position</a> and <a>attr_texCoord</a>, each 
    corresponding to the array buffer (rectangle vertices) and element array (vertices indices)
    of the image structure to be rendered. 
 
    The uniform <a>projection</a> must be set  with an orthographic projection that allows to 
    draw the image through the GPU. Likewise, the uniform <a>texture</a> must be set with the
    incoming image to be processed.
 */
-(void) renderToTextureStorage:(GLuint*)storage size:(CGSize*)size
{  
    
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

@end
