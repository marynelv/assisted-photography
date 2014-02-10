//
//  SeeTestSaliencyViewController.m
//  SeeTestSaliency
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "SeeTestSaliencyViewController.h"
#import "SeeTestSaliencyViewController+FileHandling.h"
#import <BasicMath/Matrix4.h>
#import <See/ImageConversion.h>
#import <See/ImageSegmentation.h>
#import <See/ImageSaliency.h>

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

#define SALIENCY_OFFSET        1
#define SALIENCY_PYRLEV        3
#define SALIENCY_SURRLEV       2

//#define TIME_PROCESSBUFFER

@implementation SeeTestSaliencyViewController
@synthesize imageSource;
@synthesize renderView;
@synthesize fpsLabel;
@synthesize pyrOffset;
@synthesize pyrSize;
@synthesize surrLev;
@synthesize pyrOffsetLabel;
@synthesize pyrSizeLabel;
@synthesize surrLevLabel;
@synthesize pyrOffsetSlider;
@synthesize pyrSizeSlider;
@synthesize surrLevSlider;
@synthesize blockedView;
@synthesize showROI;
@synthesize segmentedControl;

- (void) setUpRenderView
{
    // set up view
    CGRect renderViewFrame = self.view.frame;
    renderViewFrame.size.height = round(renderViewFrame.size.width*IMAGE_WIDTH/IMAGE_HEIGHT);
    Matrix4 projectionMat = Matrix4::orthographic(0, renderViewFrame.size.width, 
                                                  renderViewFrame.size.height, 0, 
                                                  0, 1);
    self.renderView = [[RenderView alloc] initWithFrame:renderViewFrame 
                                              imageSize:CGSizeMake(((int)IMAGE_HEIGHT) >> self.pyrOffset,
                                                                   ((int)IMAGE_WIDTH) >> self.pyrOffset) 
                                          projectionMat:&projectionMat];
    self.renderView.eaglLayer.contentsGravity = kCAGravityResizeAspect;
    [self.view insertSubview:self.renderView atIndex:0]; 
}

- (void) setUpCaptureSessionAndWriter
{
    self.showROI = FALSE;
    
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
    NSLog(@"Received memory warning!");
    
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [self.blockedView setHidden:NO]; 
    [self setUpCaptureSessionAndWriter];
    
    useGPU = NO;
    self.segmentedControl.selectedSegmentIndex = MODE_ALLCPU;
    
    self.pyrOffsetSlider.value = SALIENCY_OFFSET; self.pyrOffset = SALIENCY_OFFSET+1; // random value so it gets updated
    [self sliderPyrOffsetChanged:self.pyrOffsetSlider]; // this sets up renderView
    self.pyrSizeSlider.value = SALIENCY_PYRLEV;
    self.surrLevSlider.value = SALIENCY_SURRLEV;
    [self sliderPyrSizeChanged:self.pyrSizeSlider];
    [self sliderSurrLevChanged:self.surrLevSlider];

    // always start capture session after setting preview layer
	[self.imageSource startCaptureSession];
    [self.blockedView setHidden:YES]; 
    
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

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if ([touches count] == 1) {
        UITouch *touch = [touches anyObject];
        if ([touch tapCount] == 1) {
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            self.showROI = !self.showROI;
            
        } else if ([touch tapCount] == 2) {
            
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            if ([self.imageSource isWriting]) [self.imageSource stopCapturingSession];
            else {[self discardCaptureSessionAndWriter]; [self setUpCaptureSessionAndWriter];};
            
        } 
        
    }
}

- (void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time
{    
    
#ifdef TIME_PROCESSBUFFER
    double t = tic();
#endif
    
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer); 
    
    img saliency = 0; 
    size_t w = 0, h = 0;
    unsigned char *rowBase = 0;
    
    if (!useGPU) // don't use opengl for saliency computation  --------------------------------------------------------- //
    {
       
        CVPixelBufferLockBaseAddress( pixelBufferRef, 0 );
        
        int height = CVPixelBufferGetHeight(pixelBufferRef);
        int width = CVPixelBufferGetWidth(pixelBufferRef);
        rowBase = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBufferRef);
    
#ifdef TIME_PROCESSBUFFER
        double tSaliency = tic();
#endif
    
        see_saliencyItti( rowBase, width, height, self.pyrSize, self.pyrOffset, self.surrLev, saliency, w, h, NULL, NULL, NULL);
            
#ifdef TIME_PROCESSBUFFER
        tSaliency = toc(tSaliency);
        tSaliency = tSaliency / NANOS_IN_MS;
        COUT_TIME_LOG_AT("compute saliency", tSaliency);
#endif
        
    }
    else // use opengl for saliency computation --------------------------------------------------------------------------------- //
    {
        if (!self.renderView) {return;}
    
#ifdef TIME_PROCESSBUFFER
        double tSaliency = tic();
#endif
            
        saliency = [self.renderView glSaliencyFromPixelBufferRef:pixelBufferRef width:&w height:&h 
                                                          pyrLev:self.pyrSize surrLev:self.surrLev];
    
#ifdef TIME_PROCESSBUFFER
        tSaliency = toc(tSaliency);
        tSaliency = tSaliency / NANOS_IN_MS;
        COUT_TIME_LOG_AT("compute saliency (OpenGL)", tSaliency);
#endif
    
        CVPixelBufferLockBaseAddress( pixelBufferRef, 0 );
        rowBase = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBufferRef);
    
    }
    
	int bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBufferRef);
    
    if (!self.showROI)
    {
        
#ifdef TIME_PROCESSBUFFER
        double tPaintSaliency = tic();
#endif

        see_scaleTo(saliency, w*h, 255.0);
        for ( int row = 0; row < h; row += 1 )
        {		
            vDSP_vfixru8(saliency + (row*w),1,rowBase + (row * bytesPerRow),4,w);
            vDSP_vfixru8(saliency + (row*w),1,rowBase + (row * bytesPerRow) + 1,4,w);
            vDSP_vfixru8(saliency + (row*w),1,rowBase + (row * bytesPerRow) + 2,4,w);
        }    
        
#ifdef TIME_PROCESSBUFFER
        tPaintSaliency = toc(tPaintSaliency);
        tPaintSaliency = tPaintSaliency / NANOS_IN_MS;
        COUT_TIME_LOG_AT("paint saliency", tPaintSaliency);
#endif
        
    }
    else
    {
        
#ifdef TIME_PROCESSBUFFER
        double tROI = tic();
#endif
        
        see_uniformThresh(&saliency, w*h);
        
        int nlabels = 0;
		img labels = see_labelBlobs(saliency, w, h, nlabels);
        
		float selected = see_selectMostMeaningfulBlob(saliency, w*h, labels, nlabels, 
                                                      true, 0, 0, 0, 0);
        float wx = 0, wy = 0;
		see_weightedMean( saliency, w, h, labels, selected, wx, wy);
        
#ifdef TIME_PROCESSBUFFER
        tROI = toc(tROI);
        tROI = tROI / NANOS_IN_MS;
        COUT_TIME_LOG_AT("find ROI", tROI);
#endif
        
#ifdef TIME_PROCESSBUFFER
        double tPaintROI = tic();
#endif
        
        img highlight = 0;
        see_highlightBlob( labels, w*h, selected, &highlight, 255.0 );
        
        for ( int row = 0; row < h; row += 1 )
		{
            vDSP_vfixru8(highlight + (row*w),1,rowBase + (row * bytesPerRow),4,w);
			vDSP_vfixru8(highlight + (row*w),1,rowBase + (row * bytesPerRow) + 1,4,w);
			vDSP_vfixru8(highlight + (row*w),1,rowBase + (row * bytesPerRow) + 2,4,w);
        }
        
		int top = (floor)(wy-3); if (top < 0) top = 0;
		int bottom = (floor)(wy+3); if (bottom > h) bottom = h;
		int left = (floor)(wx-3); if (left < 0) left = 0;
		int right = (floor)(wx+3); if (right > w) right = w;
		for ( int row = top; row < bottom; row++ )
		{
			for ( int col = left; col < right; col++ )
			{
				rowBase[col*4 + (row * bytesPerRow)] = 255;
				rowBase[col*4 + (row * bytesPerRow)+1] = 0;
				rowBase[col*4 + (row * bytesPerRow)+2] = 0;
			}
		}
        
#ifdef TIME_PROCESSBUFFER
        tPaintROI = toc(tPaintROI);
        tPaintROI = tPaintROI / NANOS_IN_MS;
        COUT_TIME_LOG_AT("paint ROI", tPaintROI);
#endif
        
        free(highlight);
		free(labels);
    }
    
    free(saliency);
    
    CVPixelBufferUnlockBaseAddress( pixelBufferRef, 0 );
    
#ifdef TIME_PROCESSBUFFER
    double tGLRender = tic();
#endif
    
    [self.renderView renderCVPixelBufferRef:pixelBufferRef];
    
#ifdef TIME_PROCESSBUFFER
    tGLRender = toc(tGLRender);
    tGLRender = tGLRender / NANOS_IN_MS;
    COUT_TIME_LOG_AT("render", tGLRender);
#endif
    
    [self updateFrameCount];
    
#ifdef TIME_PROCESSBUFFER
    t = toc(t);
    t = t / NANOS_IN_MS;
    COUT_TIME_LOG(t);
#endif

}

- (void) updateFrameCount
{
    
    if (fpsTracker.update())
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fpsLabel setText:[NSString stringWithFormat:@"%u fps for %.0fx%.0f image", fpsTracker.rate(), IMAGE_WIDTH, IMAGE_HEIGHT]];
        });
    }
}

- (IBAction) segmentedControlIndexChanged
{
    switch (self.segmentedControl.selectedSegmentIndex) {
        case MODE_ALLCPU:
            useGPU = NO;
            break;
        case MODE_WITHGPU:
            useGPU = YES;
            break;
        default:
            NSLog(@"WARNING: Unknown app mode!");
            break;
    }
}


- (IBAction) sliderPyrOffsetChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    int val = round(slider.value);
    slider.value = val;
    
    if (val != self.pyrOffset)
    {
        [self.blockedView setHidden:NO]; 
        [self.view setNeedsDisplay];
        [self.renderView removeFromSuperview];
        [self.imageSource stopCapturingSession];
        self.imageSource = nil;
        self.renderView = nil;
        
        self.pyrOffsetLabel.text = [NSString stringWithFormat:@"%d", val];
        self.pyrOffset = val;
        
        [self setUpCaptureSessionAndWriter];
        [self setUpRenderView];
        [self.imageSource startCaptureSession];
        [self.blockedView setHidden:YES]; 
    }
}

- (IBAction) sliderPyrSizeChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    int val = round(slider.value);
    slider.value = val;
    self.pyrSizeLabel.text = [NSString stringWithFormat:@"%d", val];
    self.pyrSize = val;    
}

- (IBAction) sliderSurrLevChanged:(id)sender
{
    UISlider *slider = (UISlider *)sender;
    int val = round(slider.value);
    slider.value = val;
    self.surrLevLabel.text = [NSString stringWithFormat:@"%d", val];
    self.surrLev = val;        
}

@end
