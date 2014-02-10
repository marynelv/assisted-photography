//
//  GLVProgramTexture.h
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 10/25/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVProgramHandler.h"

/**
    Texture shader program attributes
 */
typedef enum {
    PROG_TEXTURE_ATTR_POSITION,    //!< position attribute for the vertex shader (@see texturedProjection.vsh)
    PROG_TEXTURE_ATTR_TEXCOORD,    //!< texture coordinate attribute for the vertex shader (@see texturedProjection.vsh)
    PROG_TEXTURE_ATTR_NUM          //!< number of attributes
} GLVPROG_TEXTURE_ATTR;

/**
    Texture shader program uniforms
 */
typedef enum {
    PROG_TEXTURE_UNI_PROJECTION,   //!< projection matrix uniform (@see texturedProjection.vsh)
    PROG_TEXTURE_UNI_TEXTURE,      //!< texture uniform for the fragment shader (@see texture.fsh)
    PROG_TEXTURE_UNI_NUM           //!< number of uniforms
} GLVPROG_TEXTURE_UNI;

/**
    Texture shader program
    Loads up a texture and pastes it over a VBO set up by the user.
 */
@interface GLVProgramTexture : GLVProgramHandler
{        
    GLuint *attr;       //!< attributes
    GLuint *uni;        //!< uniforms
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
