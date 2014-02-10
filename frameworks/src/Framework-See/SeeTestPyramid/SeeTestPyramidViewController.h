//
//  SeeTestPyramidViewController.h
//  SeeTestPyramid
//
//  Created by Marynel Vazquez on 11/15/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <See/ImageSource.h>
#import <DataLogging/DLFramesPerSecond.h>

#define IMAGE_QUALITYPRESET     AVCaptureSessionPreset640x480   //!< back camera image quality
#define IMAGE_WIDTH             640.0                           //!< back camera image width
#define IMAGE_HEIGHT            480.0                           //!< back camera image height
#define LEVELS                  7

@interface SeeTestPyramidViewController : UIViewController <ImageSourceDelegate>
{
    FPSTracker fpsTracker;
    int levels;
}
@property (nonatomic, retain) ImageSource *imageSource;
@property (nonatomic, retain) NSMutableArray *pyrLevelLayers;
@property (nonatomic, retain) IBOutlet UILabel *fpsLabel;

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time;
@end
