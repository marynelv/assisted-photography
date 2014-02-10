//
//  GLVProgramSaliencyFeatures.h
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 11/7/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVProgramHandler.h"

/**
 Gray shader program attributes
 */
typedef enum {
    PROG_SALIENCYFEAT_ATTR_POSITION,    //!< position attribute for the vertex shader (@see texturedProjection.vsh)
    PROG_SALIENCYFEAT_ATTR_TEXCOORD,    //!< texture coordinate attribute for the vertex shader (@see texturedProjection.vsh)
    PROG_SALIENCYFEAT_ATTR_NUM          //!< number of attributes
} GLVPROG_SALIENCYFEAT_ATTR;    

/**
 Gray shader program attributes
 */
typedef enum {
    PROG_SALIENCYFEAY_UNI_PROJECTION,   //!< projection uniform for the texturedProjection sahder (@see texturedProjection)
    PROG_SALIENCYFEAT_UNI_TEXTURE,      //!< texture uniform for the fragment shader (@see saliencyFeatures.fsh)
    PROG_SALIENCYFEAT_UNI_NUM           //!< number of uniforms
} GLVPROG_SALIENCYFEAT_UNI;


@interface GLVProgramSaliencyFeatures : GLVProgramHandler
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
