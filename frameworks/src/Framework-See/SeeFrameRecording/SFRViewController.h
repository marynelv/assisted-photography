//
//  SFRViewController.h
//  Framework-See
//
//  Created by Marynel Vazquez on 1/19/12.
//  Copyright (c) 2012 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GLVViewCam+Render.h"
#import <See/ImageSource.h>
#import <DataLogging/DLFramesPerSecond.h>
#import <DataLogging/DLFrameLog.h>

@interface SFRViewController : UIViewController <ImageSourceDelegate>
{
    FPSTracker *fpsTracker;
    FPSTracker *cameraTracker;
}

@property (retain, nonatomic) ImageSource *imageSource; // image source (camera)
@property (retain, nonatomic) GLVViewCam *cameraView;   // render
@property (assign, nonatomic) BOOL saveFrames;          // save frames to app bundle?
@property (retain, nonatomic) DLFrameLog *frameLog;     // frame recorder
@property (assign, atomic) unsigned int frameCount;     // frame count
@property (assign, atomic) float frameDurationInSec;    // desired frame duration in seconds
@property (assign, atomic) uint64_t prevFrameTimeStamp; // time stamp of the last saved frame
@property (retain, nonatomic) IBOutlet UILabel *infoLabel;
@property (retain, nonatomic) IBOutlet UILabel *sliderLabel;
@property (retain, nonatomic) IBOutlet UISlider *framesSlider;

-(void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time;
-(void) updateInfoLabelText;
-(IBAction)sliderChanged:(id)sender;

@end
