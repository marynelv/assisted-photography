//
//  RenderView.h
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <GLVision/GLVViewSaliency.h>
#import <GLVision/GLVProgramGray.h>
#import <GLVision/GLVProgramTexture.h>
#import <BasicMath/Matrix4.h>
#import <BasicMath/Rectangle.h>
#import <See/ImageTypes.h>
#import <See/ImageMotion.h>

#define TEMPLATE_MAX_SIZE 40
#define TEMPLATE_EPSILON  0.001 //0.00005 // 0.05
#define TEMPLATE_MAX_ITER 500 //1500 // 50
#define PYRAMID_LEVELS    2

@protocol RenderViewDelegate
@optional
- (void) alertTrackingFailure:(NSString*)message;
@end

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
    
    // template tracking
    img prevIm;
    Rectangle templateBox;
}

@property (nonatomic, assign) id<RenderViewDelegate> delegate;
@property (nonatomic, retain) GLVProgramGray *pResize;
@property (nonatomic, retain) GLVProgramTexture *pScreenRender;
@property (atomic, assign) BOOL resetWhenPossible;
@property (atomic, assign) BOOL doNotProcess;

- (id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize;
- (void) setUpBufferObjects;
- (void) setUpTracker;

- (img) intensityFromPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;
- (unsigned char*) trackTemplate:(img)nextIm;
- (void) renderRGBImage:(unsigned char *)image width:(int)width height:(int)height;

- (void) processPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;

@end
