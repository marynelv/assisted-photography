//
//  SeeTestSaliencyViewController.m
//  TestSaliencyFeatures
//
//  Created by Marynel Vazquez on 11/7/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "SeeTestSaliencyViewController.h"
#import <See/ImageTypes.h>

@implementation SeeTestSaliencyViewController
@synthesize imageSource;
@synthesize renderView;
@synthesize segmentedControl;
@synthesize infoLabel;
@synthesize gpuSwitchLabel;
@synthesize gpuSwitch;
@synthesize diffSwitchLabel;
@synthesize diffSwitch;

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
    
    computeSaliencyDiff = NO;
    useGPU = YES;
    
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
    
    // set up view
    CGRect renderViewFrame = self.view.frame;
//    renderViewFrame.size.height = renderViewFrame.size.width;
    renderViewFrame.size.height = round(renderViewFrame.size.width*IMAGE_WIDTH/IMAGE_HEIGHT);
    GLVSize processingSize = MakeGLVSize(IMAGE_HEIGHT/2, IMAGE_WIDTH/2);
    self.renderView = [[RenderView alloc] initWithFrame:renderViewFrame 
                                      maxProcessingSize:processingSize];
    self.renderView.eaglLayer.contentsGravity = kCAGravityResizeAspect;
    [self.view insertSubview:self.renderView atIndex:0]; 

    
    self.infoLabel.text = [NSString stringWithFormat:@"Proc. Size: %ux%u\nFPS: %u",  
                           processingSize.width, processingSize.height, fpsTracker.rate()];
    
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

    if (self.segmentedControl.selectedSegmentIndex == FEAT_SRC)
    {
        [self.renderView renderPixelBufferRef:pixelBufferRef];
    }
    else
    {
        if (computeSaliencyDiff) [self.renderView featureDifferenceForPixelBufferRef:pixelBufferRef];
        else [self.renderView processPixelBufferRef:pixelBufferRef allGPU:useGPU];
    }
        
    if (fpsTracker.update())
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.infoLabel.text = [NSString stringWithFormat:@"Proc. Size: %ux%u\nFPS: %u",  
                                   self.renderView.maxProcessingSize.width, self.renderView.maxProcessingSize.height, 
                                   fpsTracker.rate()];
        });
    }
}

- (IBAction) segmentedControlIndexChanged
{
    switch (self.segmentedControl.selectedSegmentIndex) {
        case FEAT_INT:
            [self.diffSwitchLabel setHidden:NO]; [self.diffSwitch setHidden:NO];
            if (computeSaliencyDiff && ![self.gpuSwitch isHidden]) 
            {[self.gpuSwitch setHidden:YES]; [self.gpuSwitchLabel setHidden:YES];}
            else
            {[self.gpuSwitch setHidden:NO]; [self.gpuSwitchLabel setHidden:NO];}
            self.renderView.featureType = FEAT_INT;
            break;
        case FEAT_RG:
            [self.diffSwitchLabel setHidden:NO]; [self.diffSwitch setHidden:NO];
            if (computeSaliencyDiff && ![self.gpuSwitch isHidden]) 
            {[self.gpuSwitch setHidden:YES]; [self.gpuSwitchLabel setHidden:YES];}
            else
            {[self.gpuSwitch setHidden:NO]; [self.gpuSwitchLabel setHidden:NO];}
            self.renderView.featureType = FEAT_RG;
            break;
        case FEAT_BY:
            [self.diffSwitchLabel setHidden:NO]; [self.diffSwitch setHidden:NO];
            if (computeSaliencyDiff && ![self.gpuSwitch isHidden]) 
            {[self.gpuSwitch setHidden:YES]; [self.gpuSwitchLabel setHidden:YES];}
            else
            {[self.gpuSwitch setHidden:NO]; [self.gpuSwitchLabel setHidden:NO];}
            self.renderView.featureType = FEAT_BY;
            break;
        case FEAT_SRC:
            [self.diffSwitchLabel setHidden:YES]; [self.diffSwitch setHidden:YES];
            [self.gpuSwitch setHidden:YES]; [self.gpuSwitchLabel setHidden:YES];
            self.renderView.featureType = FEAT_SRC;
            break;
        default:
            NSLog(@"Unknown segment control option: %d", self.segmentedControl.selectedSegmentIndex);
            break;
    }
}


- (IBAction) DifferenceSwitchChanged:(id)sender
{
    BOOL val = [diffSwitch isOn];
    if (computeSaliencyDiff != val)
    {
        computeSaliencyDiff = val;
        if (computeSaliencyDiff)
        {    [self.gpuSwitch setHidden:YES]; [self.gpuSwitchLabel setHidden:YES]; }
        else
        {    [self.gpuSwitch setHidden:NO]; [self.gpuSwitchLabel setHidden:NO]; }
    }
}


- (IBAction) GPUSwitchChanged:(id)sender
{
    useGPU = [self.gpuSwitch isOn];
}

@end
