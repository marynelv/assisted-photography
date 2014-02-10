//
//  GLVViewController.m
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 10/22/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "GLVViewController.h"

@implementation GLVViewController
@synthesize imageSource;
@synthesize cameraView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    // set up image source
    self.imageSource = [[ImageSource alloc] init];
    [self.imageSource setDelegate:self];

    NSError *error = nil;
    if (![self.imageSource setupCaptureSessionWithPreset:IMAGE_QUALITYPRESET error:&error])
    {
        GLVDebugLog(@"Could not set up capture session! Got error: %@", error);
        GLVDebugLog(@"%@", [error localizedDescription]);
        GLVDebugLog(@"%@", [error localizedFailureReason]); 
        GLVDebugLog(@"%@", [error localizedRecoverySuggestion]); 
        GLVDebugLog(@"%@", [error localizedRecoveryOptions]); 
        self.imageSource = nil;
    }              
    
    // set up camera view frame size
    CGRect cameraViewFrame = self.view.frame;
    cameraViewFrame.size.height = round(cameraViewFrame.size.width*IMAGE_WIDTH/IMAGE_HEIGHT);
    
    // set up projection matrix
    Matrix4 projection = Matrix4::orthographic(0, cameraViewFrame.size.width, cameraViewFrame.size.height, 0, 0, 1);
    //    Matrix4 projection = Matrix4::orthographic(0, IMAGE_HEIGHT, IMAGE_WIDTH, 0, 0, 1);
//    std::cout << projection << std::endl;
    
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


-(void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time
{
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer); 
    [self.cameraView renderCVPixelBufferRef:pixelBufferRef];
}

@end
