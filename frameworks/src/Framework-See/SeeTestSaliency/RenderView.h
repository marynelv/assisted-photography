//
//  RenderView.h
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <GLVision/GLVViewSaliency.h>
#import <BasicMath/Matrix4.h>
#import <See/ImageTypes.h>
#import <GLVision/GLVProgramTexture.h>

@interface RenderView : GLVViewSaliency
{
    GLuint attr_position;
    GLuint attr_texCoord;
    GLuint uni_projection;
    GLuint uni_texture;
    
    GLuint camRect;
    GLuint rectIdx;
}

@property (nonatomic, retain) GLVProgramTexture *pTexture;  //!< simple texture rendering program

- (id) initWithFrame:(CGRect)frame imageSize:(CGSize)size projectionMat:(Matrix4 *)mat;
- (void) setUpBufferObjects;
- (img) glSaliencyFromPixelBufferRef:(CVPixelBufferRef)pixelBufferRef width:(size_t *)w height:(size_t *)h
                              pyrLev:(int)pyrLev surrLev:(int)surrLev;
- (void) renderCVPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;


@end
