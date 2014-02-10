//
//  GLVViewSaliency.h
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 11/7/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVViewCam.h"
#import "GLVCommon.h"
#import "GLVProgramSaliencyFeatures.h"


typedef enum {
    GLVVSAL_FBO_TEXTURE_1,      //!< used for saliency features computation
    GLVVSAL_FBO_TEXTURE_2,      //!< user for center surround operations
    GLVVSAL_FBO_TEXTURE_COUNT
} GLVVSALIENCY_FBO_TEXTURE;


@interface GLVViewSaliency : GLVViewCam
{    
@protected
    GLuint *fboTexture;                 //!< framebuffer for texture rendering
    
    GLuint pFeatures_attr_position;     //!< position attribute in pFeatures
    GLuint pFeatures_attr_texCoord;     //!< texture coordinate attribute in pFeatures
    GLuint pFeatures_uni_projection;    //!< projection matrix in pFeatures
    GLuint pFeatures_uni_texture;       //!< texture uniform in pFeatures
    
    GLuint imageRect;                   //!< image rectangle
    GLuint imageRectIdx;                //!< image rectangle indices
    
    float *pFeatures_projection_mat;    //!< pFeatures projection matrix
    
    TexImage featuresTexture;
    
    GLVSize maxProcessingSize;          //!< maximum processing size
    GLVSize maxProcessingSize2;         //!< next square of two for maximum processing size
}
    
@property (nonatomic, retain) GLVProgramSaliencyFeatures *pFeatures;        //!< saliency features program
@property (nonatomic, assign) GLVSize maxProcessingSize;                    //!< maximum processing size
@property (nonatomic, assign) GLVSize maxProcessingSize2;                   //!< maximum processing size (power of 2)

-(id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize;

-(BOOL) featuresFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef pixelFormat:(GLenum)pixelFormat textureFormat:(GLint)textureFormat;
-(BOOL) generateFeaturesPyramid;
@end
