//
//  SBViewController.m
//  SeeBlurry
//
//  Created by Marynel Vazquez on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SBViewController.h"
#import <See/ImageBlurriness.h>

#define IMAGE_QUALITYPRESET     AVCaptureSessionPreset640x480   //!< back camera image quality
#define IMAGE_WIDTH             640.0                           //!< back camera image width
#define IMAGE_HEIGHT            480.0                           //!< back camera image height

#define IMAGE_DOWNSIZE_FACTOR   1

@implementation SBViewController
@synthesize imageSource;
@synthesize renderView;
@synthesize fpsLabel;
@synthesize blurryBar;
@synthesize blurryBarLabel;
@synthesize userRatingLabel;

- (void) setUpRenderView
{
    // set up view
    CGRect renderViewFrame = self.view.frame;
    renderViewFrame.size.height = round(renderViewFrame.size.width*IMAGE_WIDTH/IMAGE_HEIGHT);
    Matrix4 projectionMat = Matrix4::orthographic(0, renderViewFrame.size.width, 
                                                  renderViewFrame.size.height, 0, 
                                                  0, 1);
    GLVSize maxProcSize = MakeGLVSize(((int)IMAGE_WIDTH) >> IMAGE_DOWNSIZE_FACTOR,
                                      ((int)IMAGE_HEIGHT) >> IMAGE_DOWNSIZE_FACTOR);
    self.renderView = [[RenderView alloc] initWithFrame:renderViewFrame 
                                      maxProcessingSize:maxProcSize];
    NSLog(@"Max. processing size: %ux%u", maxProcSize.width, maxProcSize.height);
          
    self.renderView.delegate = self;
    self.renderView.eaglLayer.contentsGravity = kCAGravityResizeAspect;
    [self.view insertSubview:self.renderView atIndex:0]; 
    
    self.blurryBar = [[BlurryBar alloc] initWithFrame:renderViewFrame];
    self.blurryBar.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.blurryBar];
    
    self.blurryBarLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, renderViewFrame.size.height - 18, 320, 18)];
    self.blurryBarLabel.text = @"blur metric";
    self.blurryBarLabel.font = [UIFont fontWithName:@"TrebuchetMS" size:14];
    self.blurryBarLabel.textColor = [UIColor whiteColor];
    self.blurryBarLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.blurryBarLabel];
}

- (void) setUpCaptureSessionAndWriter
{        
    self.imageSource = [[ImageSource alloc] init];
    self.imageSource.delegate = self;
    
    NSError *error = nil;
    if (![self.imageSource setupCaptureSessionWithPreset:IMAGE_QUALITYPRESET error:&error])
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
    
    [self setUpCaptureSessionAndWriter];
    [self setUpRenderView];
    
    // always start capture session after setting preview layer
	[self.imageSource startCaptureSession];
    
    [self.imageSource autofocus];

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
            @autoreleasepool {        
                [self.fpsLabel setText:[NSString stringWithFormat:@" %u fps", fpsTracker.rate()]];
            }
        });
    }
}


- (void) updateBlurryEstimation:(float)blurry
{
    float rating = blurMetricToUserRating(blurry);
//    NSLog(@"blurry lev: %.4f \t rating: %.2f", blurry, rating);
    
    [self.blurryBar setBlurryLevel:blurry];
    [self.blurryBar setNeedsDisplay];
    
    @autoreleasepool {        
        self.blurryBarLabel.text = [NSString stringWithFormat:@"blur metric: %.4f", blurry];
        self.userRatingLabel.text = [NSString stringWithFormat:@"User Rating: %.2f", rating];
    }

}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1) {
        UITouch *touch = [touches anyObject];
        if ([touch tapCount] == 1) {
            [self.imageSource autofocus];
        }         
    }
}


@end
