//
//  GLVView+Camera.h
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 10/30/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <GLVision/GLVViewCam.h>
#import <GLVision/GLVProgramHandler.h>
#import <BasicMath/Matrix4.h>
#import <CoreVideo/CoreVideo.h>

@interface GLVViewCam (Render)

-(id) initWithFrame:(CGRect)frame ImageSize:(CGSize)size projectionMat:(Matrix4 *)mat;
-(void) setUpImageSize:(CGSize)size;
-(void) setUpProjectionMat:(Matrix4 *)mat;
-(GLVProgramHandler *) programTexture;
-(void) setUpAttributesAndUniforms;
-(void) setUpVertexBufferObjects;
-(BOOL) renderCVPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;

@end
