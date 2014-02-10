//
//  GLVProgramGray.h
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

#import "GLVProgramHandler.h"

/**
    Gray shader program attributes
 */
typedef enum {
    PROG_GRAY_ATTR_POSITION,    //!< position attribute for the vertex shader (@see texturedProjection.vsh)
    PROG_GRAY_ATTR_TEXCOORD,    //!< texture coordinate attribute for the vertex shader (@see texturedProjection.vsh)
    PROG_GRAY_ATTR_NUM          //!< number of attributes
} GLVPROG_GRAY_ATTR;    

/**
    Gray shader program attributes
 */
typedef enum {
    PROG_GRAY_UNI_PROJECTION,   //!< projection matrix for vertex shader (@see texturedProjection.vsh)
    PROG_GRAY_UNI_TEXTURE,      //!< texture uniform for the fragment shader (@see gray.fsh)
    PROG_GRAY_UNI_NUM           //!< number of uniforms
} GLVPROG_GRAY_UNI;

/**
    Gray shader program
    Loads up a texture set up by the user and renders a gray version of it on a custom VBO.
 */
@interface GLVProgramGray : GLVProgramHandler
{        
    GLuint *attr;               //!< attributes
    GLuint *uni;                //!< uniforms
}

-(int) allAttributeIndices:(GLuint **)indices;
-(int) allUniformIndices:(GLuint **)indices;
-(GLuint) attributeWithIndex:(int)index;
-(GLuint) uniformWithIndex:(int)index;
-(void) setUpAttributesAndUniforms;
-(void) enableAttributes;
-(void) disableAttributes;
-(void) renderToTextureStorage:(GLuint*)storage size:(CGSize*)size;

@end
