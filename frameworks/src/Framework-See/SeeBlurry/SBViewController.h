//
//  SBViewController.h
//  SeeBlurry
//
//  Created by Marynel Vazquez on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <See/ImageSource.h>
#import <DataLogging/DLFramesPerSecond.h>
#import "RenderView.h"
#import "BlurryBar.h"

@interface SBViewController : UIViewController <RenderViewDelegate, ImageSourceDelegate>
{
    FPSTracker fpsTracker;
}

@property (nonatomic, retain) ImageSource *imageSource;
@property (nonatomic, retain) RenderView *renderView;
@property (nonatomic, retain) IBOutlet UILabel *fpsLabel;
@property (nonatomic, retain) BlurryBar *blurryBar;
@property (nonatomic, retain) UILabel *blurryBarLabel;
@property (nonatomic, retain) IBOutlet UILabel *userRatingLabel;

- (void) setUpRenderView;
- (void) setUpCaptureSessionAndWriter;
- (void) discardCaptureSessionAndWriter;

- (void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time;

- (void) updateBlurryEstimation:(float)blurry;
@end
