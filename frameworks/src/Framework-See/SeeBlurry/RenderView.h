//
//  RenderView.h
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <GLVision/GLVViewResizeGray.h>
#import <See/ImageTypes.h>
#import <See/ImageMotion.h>

@protocol RenderViewDelegate
@optional
- (void) updateBlurryEstimation:(float)blurry;
@end

@interface RenderView : GLVViewResizeGray
{}

@property (nonatomic, assign) id<RenderViewDelegate> delegate;

- (img) intensityFromResizedGray;
- (void) processPixelBufferRef:(CVPixelBufferRef)pixelBufferRef;

@end
