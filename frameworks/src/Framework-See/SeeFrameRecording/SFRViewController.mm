//
//  SFRViewController.m
//  Framework-See
//
//  Created by Marynel Vazquez on 1/19/12.
//  Copyright (c) 2012 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "SFRViewController.h"
#import <BasicMath/Matrix4.h>
#import <DataLogging/DLLog.h>
#import <DataLogging/DLTiming.h>

#define IMAGE_QUALITYPRESET     AVCaptureSessionPreset640x480   //!< back camera image quality
#define IMAGE_WIDTH             640.0                           //!< back camera image width
#define IMAGE_HEIGHT            480.0                           //!< back camera image height

#define INFOLABEL_NOTRECORDING  @"Tap to start recording"
#define INFOLABEL_RECORDING     @"Recording"

@implementation SFRViewController
@synthesize imageSource;
@synthesize cameraView;
@synthesize frameLog;
@synthesize saveFrames;
@synthesize infoLabel;
@synthesize frameCount;
@synthesize prevFrameTimeStamp;
@synthesize framesSlider;
@synthesize sliderLabel;
@synthesize frameDurationInSec;


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // set up frame log
    self.frameLog = [[DLFrameLog alloc] initWithName:@"camera"];
    
    // set up image source
    self.imageSource = [[ImageSource alloc] init];
    [self.imageSource setDelegate:self];
    
    NSError *error = nil;
    if (![self.imageSource setupCaptureSessionWithPreset:IMAGE_QUALITYPRESET error:&error])
    {
        NSLog(@"Could not set up capture session! Got error: %@", error);
        NSLog(@"%@", [error localizedDescription]);
        NSLog(@"%@", [error localizedFailureReason]); 
        NSLog(@"%@", [error localizedRecoverySuggestion]); 
        NSLog(@"%@", [error localizedRecoveryOptions]); 
        self.imageSource = nil;
    }       
    
    // set up camera view frame size
    CGRect cameraViewFrame = self.view.frame;
    cameraViewFrame.size.height = round(cameraViewFrame.size.width*IMAGE_WIDTH/IMAGE_HEIGHT);
    
    // set up projection matrix
    Matrix4 projection = Matrix4::orthographic(0, cameraViewFrame.size.width, cameraViewFrame.size.height, 0, 0, 1);
    //    Matrix4 projection = Matrix4::orthographic(0, IMAGE_HEIGHT, IMAGE_WIDTH, 0, 0, 1);
    
    // set up camera view (and set up the texture program with initializer)
    self.cameraView = [[GLVViewCam alloc] initWithFrame:cameraViewFrame 
                                              ImageSize:CGSizeMake(IMAGE_HEIGHT, IMAGE_WIDTH)
                                          projectionMat:&projection];
    
    // display camera view
    self.cameraView.eaglLayer.contentsGravity = kCAGravityResizeAspect;
    [self.view insertSubview:self.cameraView atIndex:0]; 
    
    // set up attributes and uniforms
    [self.cameraView setUpAttributesAndUniforms];
    
    // set up VBA
    [self.cameraView setUpVertexBufferObjects];
    
    // start camera session
    [self.imageSource startCaptureSession];  
    
    self.frameCount = 0;
    fpsTracker = new FPSTracker();
    cameraTracker = new FPSTracker();
    self.prevFrameTimeStamp = 0;
    self.frameDurationInSec = 1/30.0; // 30Hz
        
     if (!isMachTimeValid()) initMachTime();
}

- (void) dealloc 
{
    if (fpsTracker) delete fpsTracker;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1) {
        UITouch *touch = [touches anyObject];
        if ([touch tapCount] == 1) {
            self.saveFrames = !self.saveFrames;
            fpsTracker->reset();
            cameraTracker->reset();
            [self updateInfoLabelText];
            self.prevFrameTimeStamp = 0;
        } 
        
    }
}

-(void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time {
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer); 
    
    [self.cameraView renderCVPixelBufferRef:pixelBufferRef];
    
    uint64_t newTimeStamp = mach_absolute_time();
    if (self.saveFrames && 
        (self.prevFrameTimeStamp == 0 || 
        (double)(newTimeStamp - self.prevFrameTimeStamp)*machTimeFreqNanoSec > NANOS_IN_SEC*self.frameDurationInSec))
    {
        [self.frameLog saveFrame:sampleBuffer presentationTime:time];
        
        self.prevFrameTimeStamp = newTimeStamp;
        self.frameCount = self.frameCount + 1;
                
        fpsTracker->update();
    }
    
    cameraTracker->update();
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateInfoLabelText];
    });
}

-(void) updateInfoLabelText {
    if (self.saveFrames) {
        self.infoLabel.text = [[NSString alloc] initWithFormat:@"%@ at %d fps (current frame = %d)\nCamera fps: %d", INFOLABEL_RECORDING, fpsTracker->rate(), self.frameCount, cameraTracker->rate()];
    } else {
        self.infoLabel.text = INFOLABEL_NOTRECORDING;
    }
}

-(IBAction) sliderChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    self.frameDurationInSec = 1/slider.value;   
    
    self.sliderLabel.text = [[NSString alloc] 
                             initWithFormat:@"Number of frames to save per second: %f", slider.value];
}


@end


