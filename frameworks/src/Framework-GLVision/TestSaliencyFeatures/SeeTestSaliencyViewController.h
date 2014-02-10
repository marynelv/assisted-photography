//
//  SeeTestSaliencyViewController.h
//  TestSaliencyFeatures
//
//  Created by Marynel Vazquez on 11/7/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <See/ImageSource.h>
#import <DataLogging/DLFramesPerSecond.h>
#import "RenderView.h"

#define IMAGE_QUALITYPRESET     AVCaptureSessionPreset640x480   //!< back camera image quality
#define IMAGE_WIDTH             640.0                           //!< back camera image width
#define IMAGE_HEIGHT            480.0                           //!< back camera image height

@interface SeeTestSaliencyViewController : UIViewController <ImageSourceDelegate>
{
    FPSTracker fpsTracker;
    BOOL computeSaliencyDiff;
    BOOL useGPU;
}

@property (nonatomic, retain) ImageSource *imageSource;
@property (nonatomic, retain) RenderView *renderView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic, retain) IBOutlet UILabel *infoLabel;
@property (nonatomic, retain) IBOutlet UILabel *gpuSwitchLabel;
@property (nonatomic, retain) IBOutlet UISwitch *gpuSwitch;
@property (nonatomic, retain) IBOutlet UILabel *diffSwitchLabel;
@property (nonatomic, retain) IBOutlet UISwitch *diffSwitch;

- (void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time;
- (IBAction) segmentedControlIndexChanged;
- (IBAction) DifferenceSwitchChanged:(id)sender;
- (IBAction) GPUSwitchChanged:(id)sender;

@end
