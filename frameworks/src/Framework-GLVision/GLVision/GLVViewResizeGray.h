//
//  GLVViewResizeGray.h
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 3/1/12.
//  Copyright (c) 2012 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVViewCam.h"
#import "GLVCommon.h"
#import "GLVProgramGray.h"
#import "GLVProgramTexture.h"
#import <BasicMath/Matrix4.h>

@interface GLVViewResizeGray : GLVViewCam
{
    GLuint pScreenRender_attr_position;     //!< position attribute for screen render program
    GLuint pScreenRender_attr_texCoord;     //!< texture coordinate attribute for screen render program
    GLuint pScreenRender_uni_projection;    //!< projection uniform for screen render program 
    GLuint pScreenRender_uni_texture;       //!< texture uniform for screen render program

    GLuint viewRect;                        //!< view rectangle array
    GLuint viewRectIdx;                     //!< view rectangle element id
    
    Matrix4 renderProjection;               //!< screen render projection matrix

    GLuint fboResize;                       //!< framebuffer object for resizing (GLView has fboScreen)
       
    GLuint pResize_attr_position;           //!< position attribute for resize program
    GLuint pResize_attr_texCoord;           //!< texture coordinate attribute for resize program
    GLuint pResize_uni_projection;          //!< projection uniform for resize program
    GLuint pResize_uni_texture;             //!< texture uniform for resize program
    
    GLuint resizeRect;                      //!< resize rectangle array (uses same indices as viewRect)
    
    Matrix4 resizeProjection;               //!< resize program projection matrix
    
    TexImage resizeTexture;                 //!< resize program texture
    
    GLVSize maxProcessingSize;              //!< maximum processing size

}

@property (nonatomic, retain) GLVProgramGray *pResize;
@property (nonatomic, retain) GLVProgramTexture *pScreenRender;
@property (nonatomic, assign) GLVSize maxProcessingSize;                    //!< maximum processing size

- (id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize;
- (void) setUpBufferObjects;

- (BOOL) resizePixelBufferAndConvertToGray:(CVPixelBufferRef)pixelBufferRef;
- (BOOL) drawResizedGrayOnScreen;
- (void) processPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;

@end
