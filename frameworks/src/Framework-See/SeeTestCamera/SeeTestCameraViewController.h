//
//  SeeTestCameraViewController.h
//  SeeTestCamera
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <See/ImageSource.h>

#define IMAGE_QUALITYPRESET     AVCaptureSessionPreset640x480   //!< back camera image quality
#define IMAGE_WIDTH             640.0                           //!< back camera image width
#define IMAGE_HEIGHT            480.0                           //!< back camera image height
#define MOVIE_FILE_NAME         @"camvideo.mov"

@interface SeeTestCameraViewController : UIViewController

@property (nonatomic, retain) ImageSource *imageSource;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *preview;

- (NSString *) moviePath;
- (void) setUpCaptureSessionAndWriter;
- (void) discardCaptureSessionAndWriter;
- (BOOL) deleteFileIfAlreadyExists:(NSString *)path;

@end
