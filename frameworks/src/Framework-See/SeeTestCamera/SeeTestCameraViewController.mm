//
//  SeeTestCameraViewController.m
//  SeeTestCamera
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "SeeTestCameraViewController.h"
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@implementation SeeTestCameraViewController
@synthesize imageSource;
@synthesize preview;

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

- (void) setUpCaptureSessionAndWriter
{
    NSString *path = [self moviePath];	
	[self deleteFileIfAlreadyExists:path];
    NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO]; //[[NSURL alloc] initFileURLWithPath:path];
	NSLog(@"Video file: %@", [url absoluteString]);
    
    self.imageSource = [[ImageSource alloc] init];
    
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
    
    self.preview = [self.imageSource layerWithSession];
    if (self.preview == nil)
    {
        NSLog(@"Could not set up video preview.");
        return;
    }
    self.preview.videoGravity = AVLayerVideoGravityResizeAspectFill;
    CGRect layerRect = [self.view.layer bounds];
    self.preview.bounds = layerRect;
    self.preview.position = CGPointMake(CGRectGetMidX(layerRect), CGRectGetMidY(layerRect));
    [self.preview setMasksToBounds:YES];
    [self.view.layer addSublayer:self.preview];
    
    // always start capture session after setting preview layer
	[self.imageSource startCaptureSession];
}

- (void) discardCaptureSessionAndWriter
{
    self.preview = nil;
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
        if ([touch tapCount] == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self];
            if ([self.imageSource isWriting]) [self.imageSource stopCapturingSession];
            else {[self discardCaptureSessionAndWriter]; [self setUpCaptureSessionAndWriter];};
        } 

    }
}

@end
