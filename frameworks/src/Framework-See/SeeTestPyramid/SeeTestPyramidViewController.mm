//
//  SeeTestPyramidViewController.m
//  SeeTestPyramid
//
//  Created by Marynel Vazquez on 11/15/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "SeeTestPyramidViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <See/ImageConversion.h>
#import <DataLogging/DLTiming.h>

//#define SHOW_ORIGINAL_CAMERA_IMAGE
#define TIME_PYRAMID

@implementation SeeTestPyramidViewController
@synthesize imageSource;
@synthesize pyrLevelLayers;
@synthesize fpsLabel;

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
    
    self.view.backgroundColor = [UIColor blackColor];
    
    levels = LEVELS;
    
    CALayer *rootLayer = [CALayer layer];
    rootLayer.bounds = CGRectMake(0, 0, 320, 480);
    rootLayer.anchorPoint = CGPointMake(0, 0);
    rootLayer.position = CGPointMake(320, 0);
    rootLayer.transform = CATransform3DMakeRotation(0.5*M_PI, 0.0, 0.0, 1.0);
    
    self.pyrLevelLayers = [[NSMutableArray alloc] init];
    size_t width = 320.0*IMAGE_WIDTH/IMAGE_HEIGHT, height =  320;
    CGSize size = CGSizeMake(width,height);
    CGPoint position = CGPointMake(0, 0);
    float r, g, b;
    for (int i=0; i<levels; i++)
    {
        CALayer *layer = [CALayer layer];
        layer.bounds = CGRectMake(0, 0, size.width, size.height);
        layer.anchorPoint = CGPointMake(0, 0);
        layer.position = position;
        r = (arc4random() % 255) / 255.0;
        g = (arc4random() % 255) / 255.0;
        b = (arc4random() % 255) / 255.0;
        NSLog(@"color (%f, %f, %f) size %f x %f", r,g,b,size.width,size.height);
        layer.backgroundColor = [[UIColor colorWithRed:r green:g blue:b alpha:1.0] CGColor];
        
        [rootLayer insertSublayer:layer atIndex:i];
        [self.pyrLevelLayers addObject:layer];
    
        width = width >> 1; height = height >> 1;
        size = CGSizeMake(width, height);
        if (levels >= 2) position = CGPointMake(position.x, size.height);  
    }
    [self.view.layer insertSublayer:rootLayer atIndex:0];
    [rootLayer setNeedsDisplay];
    NSLog(@"Done creating %d layers.", [self.pyrLevelLayers count]);
    
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

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time
{
    
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer); 
    CVPixelBufferLockBaseAddress( pixelBufferRef, 0 );
    
    int height = CVPixelBufferGetHeight(pixelBufferRef);
	int width = CVPixelBufferGetWidth(pixelBufferRef);
	unsigned char *rowBase = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBufferRef);
        
#ifdef SHOW_ORIGINAL_CAMERA_IMAGE
    
    int bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBufferRef);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context;
    
    unsigned char* levelIm = (unsigned char*)malloc(height*bytesPerRow*sizeof(unsigned char));
    memcpy(levelIm, rowBase, height*bytesPerRow);
    
    CVPixelBufferUnlockBaseAddress( pixelBufferRef, 0 );
    
    context = CGBitmapContextCreate(levelIm, width, height, 8, bytesPerRow, colorSpace, 
                                    kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGImageRef image = CGBitmapContextCreateImage(context);
    
    for (int l=0; l<levels; l++)
    {
        CALayer *layer = (CALayer *)[self.pyrLevelLayers objectAtIndex:l];
        if (l==0) CGImageRelease((__bridge CGImageRef) layer.contents);
        dispatch_async(dispatch_get_main_queue(), ^{
            [layer setContents:(__bridge id)image];
        });
    }
    
    free(levelIm);

    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
#else
    
    int length = width*height;
    float *r = 0, *g = 0, *b = 0;
    see_decomposeBGRA(rowBase, length, &r, &g, &b);
    
    CVPixelBufferUnlockBaseAddress( pixelBufferRef, 0 );
    
    float *intensity = see_intensity(r, g, b, length);
    free(r); free(g); free(b);
    
#ifdef TIME_PYRAMID
    double tPyr = tic();
#endif
    
    pyr pyramid;
    see_pyramid(intensity, width, height, levels, pyramid, FILTER_GAUS7, FSIZE_GAUS7, 0);
    
#ifdef TIME_PYRAMID
    tPyr = toc(tPyr);
    tPyr = tPyr / NANOS_IN_MS;
    COUT_TIME_LOG_AT("see_pyramid", tPyr);
#endif
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef context;
    
    for (int l=0; l<levels; l++)
    {
        CALayer *layer = (CALayer *)[self.pyrLevelLayers objectAtIndex:l];
        CGImageRelease((__bridge CGImageRef) layer.contents);
        
        unsigned char* levelIm = see_floatArrayToUChar(pyramid.at(l), length, 0, 0, 1);
        
        context = CGBitmapContextCreate(levelIm, width, height, 8, width, colorSpace, kCGImageAlphaNone);
        CGImageRef image = CGBitmapContextCreateImage(context);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [layer setContents:(__bridge id)image];
        });
        
        CGContextRelease(context);
        
        free(levelIm);
        
        width = width >> 1;
        height = height >> 1;
        length = width*height;
    }
    
    CGColorSpaceRelease(colorSpace);
    
    see_freePyr(pyramid);
    
#endif
    
    if (fpsTracker.update())
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.fpsLabel setText:[NSString stringWithFormat:@"%u fps copying to CGImage", fpsTracker.rate()]];
        });
    }

}

@end
