//
//  RenderedCameraView+Shaders.h
//  AudiballMix
//
//  Created by Marynel Vazquez on 10/25/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "RenderedCameraView.h"




@interface RenderedCameraView (Shaders)

//-(BOOL) renderCameraViewWithPixelBuffer:(CVPixelBufferRef)pixelBufferRef;//-(BOOL) renderCameraView;//WithTexture:(GLuint)texture;
-(BOOL) setUpGrayShader;
-(void) renderGray;

@end
