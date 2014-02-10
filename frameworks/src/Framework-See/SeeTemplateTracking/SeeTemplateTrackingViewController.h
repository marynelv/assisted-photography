//
//  SeeTemplateTrackingViewController.h
//  SeeTemplateTracking
//
//  Created by Marynel Vazquez on 12/6/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <See/ImageSource.h>
#import <DataLogging/DLFramesPerSecond.h>
#import "RenderView.h"

@interface SeeTemplateTrackingViewController : UIViewController <ImageSourceDelegate, RenderViewDelegate>
{
    FPSTracker fpsTracker;
}

@property (nonatomic, retain) ImageSource *imageSource;
@property (nonatomic, retain) RenderView *renderView;
@property (nonatomic, assign) BOOL alerting;
@property (nonatomic, retain) IBOutlet UILabel* fpsLabel;

- (NSString *) moviePath;
- (BOOL) deleteFileIfAlreadyExists:(NSString *)path;

- (void) setUpRenderView;
- (void) setUpCaptureSessionAndWriter;
- (void) discardCaptureSessionAndWriter;

- (void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time;

- (IBAction) resetTracking:(id)sender;
- (void) alertTrackingFailure:(NSString*)message;

@end
