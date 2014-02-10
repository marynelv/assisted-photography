//
//  RenderedCameraView.h
//  AudiballMix
//
//    Created by Marynel Vazquez on 9/28/11.
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

#import <UIKit/UIKit.h>
#import <GLVision/GLVViewSaliency.h>
#import <GLVision/GLVPrograms.h>
#import <BasicMath/Matrix4.h>
#import <See/ImageTypes.h>
#import <BasicMath/Rectangle.h>
#import <See/ImageMotion.h>

@protocol TrackingDelegate
@optional
- (void) alertTrackingFailure:(NSString*)message;
@end

typedef enum
{
    FEAT_INT,
    FEAT_RG,
    FEAT_BY,
    FEAT_SRC,
    FEAT_NUM
} FeatureType;

@interface RenderedCameraView : GLVViewSaliency
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
    GLuint resizeTrackingRect; // uses same indices as viewRect
    
    TexImage resizeTexture;
    
    img prevIm;
    Rectangle templateBox;
    
    GLVSize maxProcessingSizeTracking;          //!< maximum processing size when tracking
}

@property (nonatomic, assign) id<TrackingDelegate> delegate;
@property (nonatomic, retain) GLVProgramHandler *pResize;
@property (nonatomic, retain) GLVProgramTexture *pScreenRender;
@property (atomic, assign) FeatureType featureType; 
@property (atomic, assign) TRACKINGRESULT trackingStatus;
@property (nonatomic, assign) GLVSize maxProcessingSizeTracking; //!< maximum processing size when tracking

- (id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize maxSizeTracking:(GLVSize)maxSizeTrack;
- (BOOL) setUpColorResizeShader;
- (BOOL) setUpGrayResizeShader;
- (void) discardResizeShader;
- (void) setUpBufferObjects;

- (void) setTemplateBox:(Rectangle)rect;

- (img) glSaliencyFromPixelBufferRef:(CVPixelBufferRef)pixelBufferRef width:(size_t *)w height:(size_t *)h pyrLev:(int)pyrLev surrLev:(int)surrLev;
- (void) featureDifferenceForPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;

- (img) intensityFromPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;
- (Vector3) trackTemplate:(img)nextIm;

- (void) renderPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;

- (float) template_tracking_epsilon;
- (int) template_tracking_maxIter;

@end
