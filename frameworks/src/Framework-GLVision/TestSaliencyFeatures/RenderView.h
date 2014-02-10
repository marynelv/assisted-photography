//
//  RenderView.h
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <GLVision/GLVViewSaliency.h>
#import <GLVision/GLVProgramTexture.h>
#import <BasicMath/Matrix4.h>
#import <See/ImageTypes.h>

typedef enum
{
    FEAT_INT,
    FEAT_RG,
    FEAT_BY,
    FEAT_SRC,
    FEAT_NUM
} FeatureType;

@interface RenderView : GLVViewSaliency
{
    GLuint pScreenRender_attr_position;
    GLuint pScreenRender_attr_texCoord;
    GLuint pScreenRender_uni_projection;
    GLuint pScreenRender_uni_texture;    
    
    GLuint viewRect;
    GLuint viewRectIdx;
    
    GLuint pResize_attr_position;
    GLuint pResize_attr_texCoord;
    GLuint pResize_uni_projection;
    GLuint pResize_uni_texture;
    
    GLuint resizeRect; // uses same indices as viewRect
    
    TexImage resizeTexture;
}

@property (nonatomic, retain) GLVProgramTexture *pResize;
@property (nonatomic, retain) GLVProgramTexture *pScreenRender;
@property (atomic, assign) FeatureType featureType; 

- (id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize;
- (void) setUpBufferObjects;

- (void) featureDifferenceForPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;
- (void) processPixelBufferRef:(CVPixelBufferRef)pixelBufferRef allGPU:(BOOL)allGPU;
- (void) renderPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;

@end
