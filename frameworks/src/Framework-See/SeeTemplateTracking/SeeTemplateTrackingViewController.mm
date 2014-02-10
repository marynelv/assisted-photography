//
//  SeeTemplateTrackingViewController.m
//  SeeTemplateTracking
//
//  Created by Marynel Vazquez on 12/6/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "SeeTemplateTrackingViewController.h"
#import <BasicMath/Matrix4.h>

//#define IMAGE_QUALITYPRESET     AVCaptureSessionPreset1280x720   //!< back camera image quality
//#define IMAGE_WIDTH             1280.0                           //!< back camera image width
//#define IMAGE_HEIGHT            720.0                            //!< back camera image height

#define IMAGE_QUALITYPRESET     AVCaptureSessionPreset640x480   //!< back camera image quality
#define IMAGE_WIDTH             640.0                           //!< back camera image width
#define IMAGE_HEIGHT            480.0                           //!< back camera image height

//#define IMAGE_QUALITYPRESET     AVCaptureSessionPresetMedium    //!< back camera image quality
//#define IMAGE_WIDTH             480.0                           //!< back camera image width
//#define IMAGE_HEIGHT            360.0                           //!< back camera image height

//#define IMAGE_QUALITYPRESET     AVCaptureSessionPresetLow       //!< back camera image quality
//#define IMAGE_WIDTH             192.0                           //!< back camera image width
//#define IMAGE_HEIGHT            144.0                           //!< back camera image height 

#define IMAGE_DOWNSIZE_FACTOR  2

#define MOVIE_FILE_NAME         @"tracking.mov"

@implementation SeeTemplateTrackingViewController
@synthesize imageSource;
@synthesize renderView;
@synthesize alerting;
@synthesize fpsLabel;

- (NSString *) moviePath
{
	NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
	return [documentsDirectoryPath stringByAppendingPathComponent:MOVIE_FILE_NAME];
}

- (BOOL) deleteFileIfAlreadyExists:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:path])
	{
		[fileManager removeItemAtPath:path error:NULL];	
		return YES;
	}
	return NO;
}

- (void) setUpRenderView
{
    // set up view
    CGRect renderViewFrame = self.view.frame;
    renderViewFrame.size.height = round(renderViewFrame.size.width*IMAGE_WIDTH/IMAGE_HEIGHT);
    Matrix4 projectionMat = Matrix4::orthographic(0, renderViewFrame.size.width, 
                                                  renderViewFrame.size.height, 0, 
                                                  0, 1);
    self.renderView = [[RenderView alloc] initWithFrame:renderViewFrame 
                                              maxProcessingSize:MakeGLVSize(((int)IMAGE_HEIGHT) >> IMAGE_DOWNSIZE_FACTOR,
                                                                            ((int)IMAGE_WIDTH) >> IMAGE_DOWNSIZE_FACTOR)];
    self.renderView.delegate = self;
    self.renderView.eaglLayer.contentsGravity = kCAGravityResizeAspect;
    [self.view insertSubview:self.renderView atIndex:0]; 
}

- (void) setUpCaptureSessionAndWriter
{    
    NSString *path = [self moviePath];	
	[self deleteFileIfAlreadyExists:path];
    NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO]; //[[NSURL alloc] initFileURLWithPath:path];
	NSLog(@"Video file: %@", [url absoluteString]);
    
    self.imageSource = [[ImageSource alloc] init];
    self.imageSource.delegate = self;
    
    NSError *error = nil;
    if (![self.imageSource setupCaptureSessionWithPreset:IMAGE_QUALITYPRESET error:&error] ||
        ![self.imageSource setupVideoWriter:url width:IMAGE_WIDTH height:IMAGE_HEIGHT error:&error])
    {
        NSLog(@"Could not set up image source properly! Got error: %@", error);
        NSLog(@"%@", [error localizedDescription]);
        NSLog(@"%@", [error localizedFailureReason]); 
        NSLog(@"%@", [error localizedRecoverySuggestion]); 
        NSLog(@"%@", [error localizedRecoveryOptions]); 
        self.imageSource = nil;
    }           
}

- (void) discardCaptureSessionAndWriter
{
    self.imageSource = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.alerting = NO;
    
    [self setUpCaptureSessionAndWriter];
    [self setUpRenderView];
    
    // always start capture session after setting preview layer
	[self.imageSource startCaptureSession];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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

- (void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time
{
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);     
    [self.renderView processPixelBufferRef:pixelBufferRef];
    
    if (fpsTracker.update())
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fpsLabel setText:[NSString stringWithFormat:@" %u fps", fpsTracker.rate()]];
        });
    }
}

- (IBAction) resetTracking:(id)sender
{
    [self.renderView setDoNotProcess:YES];
    [self.renderView setResetWhenPossible:YES];
}


- (void) alertTrackingFailure:(NSString*)message
{
    if (!self.alerting)
    {
        [self.renderView setDoNotProcess:YES];
        self.alerting = YES;
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Missed target" message:message 
                                                       delegate:self 
                                              cancelButtonTitle:@"Reset Tracking" otherButtonTitles:nil];
//                                              cancelButtonTitle:@"Reset Tracking" otherButtonTitles:@"Continue", nil];
        [alert show];         
    }
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex 
{
    if (buttonIndex == 0)
    {
        // reset tracking 
        [self.renderView setResetWhenPossible:YES];
    }
    else
    {
        // continue
    }
    
    self.alerting = NO;
}

@end
