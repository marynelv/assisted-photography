//
//  ImageSource.m
//  see_project
//
//	Created by Marynel Vazquez on 11/18/10.
//	Copyright 2010 Carnegie Mellon University
//
//	This work was developed under the Rehabilitation Engineering Research 
//	Center on Accessible Public Transportation (www.rercapt.org) and is funded 
//	by grant number H133E080019 from the United States Department of Education 
//	through the National Institute on Disability and Rehabilitation Research. 
//	No endorsement should be assumed by NIDRR or the United States Government 
//	for the content contained on this code.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

#import "ImageSource.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreVideo/CoreVideo.h>

//#define PRINT_DEBUG_MSG

@interface ImageSource ()

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection;
@end

@interface ImageSource (Device)
- (AVCaptureDevice *)backCamera;
@end

@implementation ImageSource

@synthesize delegate;
@synthesize session;
@synthesize cameraInput;
@synthesize cameraOutput;

/*! Initialize ImageSource
 */
- (id) init
{
	if ( (self = [super init]) != nil )
	{
		self.session = nil;
		self.cameraInput = nil;
		self.cameraOutput = nil;
	}
	
	return self;
}

/*! Deallocate ImageSource
 */
- (void) dealloc
{
	if ([self session])
	{ 
		[self.session stopRunning];
	}
}

/*! Set up capture session with specified output quality (preset) and pixel format type 32BGRA
	\param preset capture setting preset
	\param error error
	\return <a>YES</a> if setup was successful
 
	\note <a>preset</a> is one of the following: AVCaptureSessionPresetPhoto, AVCaptureSessionPresetHigh,
	AVCaptureSessionPresetMedium, AVCaptureSessionPresetLow, AVCaptureSessionPreset640x480, AVCaptureSessionPreset1280x720
 */
- (BOOL) setupCaptureSessionWithPreset:(NSString *)preset error:(NSError **)error
{
	AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (!videoDevice)
	{
		NSLog(@"(%s) Failed setting up video device","setupCaptureSessionWithPreset:error");
		return NO;
	}
	
	// try to set video device as input
	AVCaptureDeviceInput *inputDevice = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:error];
	if (!inputDevice)
	{		
		NSLog(@"(%s) Failed setting up camera input\n%@","setupCaptureSessionWithPreset:error", [*error userInfo]);
		return NO;
	}
	
	[self setCameraInput:inputDevice];
	
	// configure capture session
	AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
	[captureSession setSessionPreset:preset];
	
	if (![captureSession canAddInput:self.cameraInput])
	{
		NSLog(@"(%s) Failed adding camera input","setupCaptureSessionWithPreset:error");
		[self setCameraInput:nil];
        return NO;
	}
	
	[captureSession addInput:self.cameraInput];
	
	// try to set camera output for online processing
	AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
															  forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	[videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    // \@todo check if kCVPixelFormatType_32BGRA causes trouble when recording!
    [videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
                                                              forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	dispatch_queue_t output_queue = dispatch_queue_create("renderQueue", NULL);
	[videoOutput setSampleBufferDelegate:self queue:output_queue];
//	dispatch_release(output_queue);
	if (![captureSession canAddOutput:videoOutput])
	{
		NSLog(@"(%s) Failed setting video output","setupCaptureSessionWithPreset:error");
		[self setCameraInput:nil];
		return NO;
	}
	
	[self setCameraOutput:videoOutput];
	[captureSession addOutput:self.cameraOutput];
	
	// everything went well!
	[self setSession:captureSession];
	
	return YES;
}


/*! Start capture session
	\return <a>YES</a> if session exists
	\note If preview layer is desired, it should be set up before starting the session
 */
- (BOOL) startCaptureSession
{
	if ([self session] == nil)
		return NO;
	
	if (![self.session isRunning])
		[self.session startRunning];
		
	return YES;
}

/*! Stop capturing session
	\return <a>YES</a> if session exists
 */
- (BOOL) stopCapturingSession
{
	if ([self session] == nil)
		return NO;
	if ([self.session isRunning])
		[self.session stopRunning];
	return YES;
}

/*! Get preview layer for current session
	\return preview layer or nil if no session has been set up
	\note Session should be started after setting up preview layer for effective display
 */
- (AVCaptureVideoPreviewLayer*) layerWithSession
{
	if ([self session])
	{
		return [AVCaptureVideoPreviewLayer layerWithSession:[self session]];
	}
	return nil;
}

/*! Process most recent sample buffer 
	\param captureOutput video output
	\param sampleBuffer	data buffer
	\param connection connection
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection 
{
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)){
        NSLog(@"sampleBuffer data is not ready");
        return;
    }
    
	CMTime time = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
    
    // PROCESS IMAGE
	if ([self.delegate respondsToSelector:@selector(processImageBuffer:)])
	{
        CVImageBufferRef pixelBuffer = CMSampleBufferGetImageBuffer( sampleBuffer );
		[self.delegate processImageBuffer:pixelBuffer];        
    }
    else if ([self.delegate respondsToSelector:@selector(processSampleBuffer:withPresentationTime:)])
    {
        [self.delegate processSampleBuffer:sampleBuffer withPresentationTime:time];
    }
}

@end

@implementation ImageSource (Device)

- (AVCaptureDevice *)backCamera
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
            return device;
        }
    }
    return nil;
}

@end
