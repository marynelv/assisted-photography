//
//  GLVViewController.h
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 10/22/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ImageSource.h"
#import "GLVViewCam+Render.h"

#define IMAGE_QUALITYPRESET     AVCaptureSessionPreset640x480   //!< back camera image quality
#define IMAGE_WIDTH             640.0                           //!< back camera image width
#define IMAGE_HEIGHT            480.0                           //!< back camera image height

@interface GLVViewController : UIViewController <ImageSourceDelegate>

@property (nonatomic, retain) ImageSource *imageSource;
@property (nonatomic, retain) GLVViewCam *cameraView;

-(void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time;

@end
