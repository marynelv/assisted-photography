//
//  SeeTestSaliencyViewController.h
//  SeeTestSaliency
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <See/ImageSource.h>
#import <DataLogging/DLFramesPerSecond.h>
#import "RenderView.h"

typedef enum {
    MODE_ALLCPU,
    MODE_WITHGPU,
    MODE_COUNT
} AppMode;

@interface SeeTestSaliencyViewController : UIViewController <ImageSourceDelegate>
{
    FPSTracker fpsTracker;
    BOOL useGPU;
}

@property (nonatomic, assign) BOOL showROI;
@property (nonatomic, retain) IBOutlet UILabel *fpsLabel;
@property (atomic, assign) int pyrOffset;
@property (atomic, assign) int pyrSize;
@property (atomic, assign) int surrLev;
@property (nonatomic, retain) IBOutlet UILabel *pyrOffsetLabel;
@property (nonatomic, retain) IBOutlet UILabel *pyrSizeLabel;
@property (nonatomic, retain) IBOutlet UILabel *surrLevLabel;
@property (nonatomic, retain) IBOutlet UISlider *pyrOffsetSlider;
@property (nonatomic, retain) IBOutlet UISlider *pyrSizeSlider;
@property (nonatomic, retain) IBOutlet UISlider *surrLevSlider;
@property (nonatomic, retain) IBOutlet UIView *blockedView;
@property (nonatomic, retain) ImageSource *imageSource;
@property (nonatomic, retain) RenderView *renderView;
@property (nonatomic, retain) IBOutlet UISegmentedControl *segmentedControl;

- (void) setUpRenderView;
- (void) setUpCaptureSessionAndWriter;
- (void) discardCaptureSessionAndWriter;

- (void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time;
- (void) updateFrameCount;

- (IBAction) segmentedControlIndexChanged;
- (IBAction) sliderPyrOffsetChanged:(id)sender;
- (IBAction) sliderPyrSizeChanged:(id)sender;
- (IBAction) sliderSurrLevChanged:(id)sender;


@end