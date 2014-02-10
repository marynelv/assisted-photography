//
//  ImageSource.m
//  Framework-See
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
#import "SeeCommon.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreVideo/CoreVideo.h>
#import <ImageIO/CGImageDestination.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface ImageSource ()
@property (nonatomic, retain) AVCaptureDeviceInput *cameraInput;
@property (nonatomic, retain) AVCaptureVideoDataOutput *cameraOutput;
//@property (nonatomic, retain) AVCaptureStillImageOutput *stillCameraOutput;

@property (nonatomic, retain) AVAssetWriter *writer;
@property (nonatomic, retain) AVAssetWriterInput *writerInput;
@property (nonatomic, retain) NSURL *videoPath;
@property (nonatomic, assign) BOOL record;

@property (nonatomic, assign) CMTime recordTime;


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection;
@end

@interface ImageSource (Private)
- (BOOL) startVideoWriter:(NSError **)error;
- (BOOL) stopVideoWriter;
+ (void) moveVideoToLib:(NSURL *)url;
- (AVCaptureDevice *)backCamera;
@end

@implementation ImageSource

@synthesize delegate;
@synthesize session;

@synthesize cameraInput;
@synthesize cameraOutput;
//@synthesize stillCameraOutput;

@synthesize writer;
@synthesize writerInput;
@synthesize videoPath;
@synthesize recordTime;
@synthesize record;
@synthesize frameGrabberQueue;

/*! Initialize ImageSource
 */
- (id) init
{
	if ( (self = [super init]) != nil )
	{
		self.session = nil;
		self.cameraInput = nil;
		self.cameraOutput = nil;
		self.writer = nil;
		self.writerInput = nil;
		self.videoPath = nil;
		
		self.recordTime = kCMTimeZero;
		self.record = NO;
	}
	
	return self;
}

/*! Deallocate ImageSource
 */
- (void) dealloc
{
	if ([self writer])
	{
		[self stopVideoWriter];
		[self setWriter:nil];
		[self setWriterInput:nil];
		[self setVideoPath:nil];
	}
	
	if ([self session])
	{ 
		[self.session stopRunning];
		[self setSession:nil];
	}
	
	[self setCameraInput:nil];
	[self setCameraOutput:nil];
    
//    if (frameGrabberQueue) dispatch_release(frameGrabberQueue);
}

/*! Set up capture session with default video orientation and pixel format type 32BGRA (recommended by Apple)
    \param preset capture setting preset
    \param error error
    \return <a>YES</a> if setup was successful
 
    Sets up capture session with orientation AVCaptureVideoOrientationLandscapeRight, specified output quality and pixel format type 32BGRA.
    Notice that kCVPixelFormatType_32RGBA isn't available as a capture format on the iPhone 4 (at least in iOS 4.2.1. BGRA is fully implemented).
    BGRA is recommended by Apple, apparently because of performance considerations.

    \note <a>preset</a> can be one of the following: AVCaptureSessionPresetPhoto, AVCaptureSessionPresetHigh,
    AVCaptureSessionPresetMedium, AVCaptureSessionPresetLow, AVCaptureSessionPreset640x480, AVCaptureSessionPreset1280x720
 */
- (BOOL) setupCaptureSessionWithPreset:(NSString *)preset error:(NSError **)error
{
    return [self setupCaptureSessionWithPreset:preset videoOrientation:AVCaptureVideoOrientationLandscapeRight error:error];
}

/*! Set up capture session with pixel format type 32BGRA (recommended by Apple)
	\param preset capture setting preset
    \param videoOrientation video orientation (e.g., AVCaptureVideoOrientationLandscapeRight, AVCaptureVideoOrientationLandscapeLeft)
	\param error error
	\return <a>YES</a> if setup was successful
 
    Sets up capture session with the given orientation, specified output quality and pixel format type 32BGRA.
    Notice that kCVPixelFormatType_32RGBA isn't available as a capture format on the iPhone 4 (at least in iOS 4.2.1. BGRA is fully implemented).
    BGRA is recommended by Apple, apparently because of performance considerations.

    Note that we may receive physically rotated CVPixelBuffers in -captureOutput:didOutputSampleBuffer:fromConnection: delegate callback.
    Note that physically rotating buffers does come with a performance cost, so only request rotation if it's necessary. 
    If, for instance, you want rotated video written to a QuickTime movie file using AVAssetWriter, it is preferable to set 
    the -transform property on the AVAssetWriterInput rather than physically rotate the buffers in AVCaptureVideoDataOutput.
 
	\note <a>preset</a> can be one of the following: AVCaptureSessionPresetPhoto, AVCaptureSessionPresetHigh,
	AVCaptureSessionPresetMedium, AVCaptureSessionPresetLow, AVCaptureSessionPreset640x480, AVCaptureSessionPreset1280x720
 */
- (BOOL) setupCaptureSessionWithPreset:(NSString *)preset videoOrientation:(AVCaptureVideoOrientation)videoOrientation error:(NSError **)error
{
	AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (!videoDevice)
	{
		SeeDebugLog(@"Failed setting up video device.");
		return NO;
	}
	
	// try to set video device as input
	AVCaptureDeviceInput *inputDevice = [[AVCaptureDeviceInput alloc] initWithDevice:[self backCamera] error:error];
	if (!inputDevice)
	{		
		SeeDebugLog(@"Failed setting up camera input.\n%@", [*error userInfo]);
		return NO;
	}
    
    if ([[inputDevice device] isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        if ([[inputDevice device] lockForConfiguration:error]) {
            [[inputDevice device] setFocusMode:AVCaptureFocusModeAutoFocus];
            [[inputDevice device] unlockForConfiguration];
        }
        else
        {
            SeeDebugLog(@"Could not set up camera focus mode.\n%@",[*error userInfo]);
            return NO;
        }
    }
	
	[self setCameraInput:inputDevice];
	
	// configure capture session
	AVCaptureSession *captureSession = [[AVCaptureSession alloc] init];
	[captureSession setSessionPreset:preset];
	
	if (![captureSession canAddInput:self.cameraInput])
	{
		SeeDebugLog(@"Failed adding camera input.");
		[self setCameraInput:nil];
		return NO;
	}
	
	[captureSession addInput:self.cameraInput];
	
	// try to set camera outputs for online processing and saving pictures
	AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] 
															  forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	[videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    
	dispatch_queue_t output_queue = dispatch_queue_create("renderQueue", NULL);
	[videoOutput setSampleBufferDelegate:self queue:output_queue];
//	dispatch_release(output_queue);
	
//    AVCaptureStillImageOutput *stillOutput = [[AVCaptureStillImageOutput alloc] init];
//    NSDictionary *stillOutputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
//    [stillOutput setOutputSettings:stillOutputSettings];
    
    if (![captureSession canAddOutput:videoOutput])
	{
		SeeDebugLog(@"Failed adding video output.");
		[self setCameraInput:nil];
		return NO;
	}
//    if (![captureSession canAddOutput:stillOutput])
//    {
//		SeeDebugLog(@"Failed adding still image output.");
//		[self setCameraInput:nil];
//		return NO;
//    }
    
	[self setCameraOutput:videoOutput];
	[captureSession addOutput:self.cameraOutput];
//    [self setStillCameraOutput:stillOutput];
//    [captureSession addOutput:self.stillCameraOutput];
    
    // set video orientation
    [captureSession beginConfiguration];
    AVCaptureConnection *videoConnection = [videoOutput connectionWithMediaType:AVMediaTypeVideo];
    if ([videoConnection isVideoOrientationSupported])
    {
        [videoConnection setVideoOrientation:videoOrientation];
    }
    [captureSession commitConfiguration];
    
    
	// everything went well!
	[self setSession:captureSession];
	
#ifdef PRINT_DEBUG_MSG
	if ([self session])
		NSLog(@"Capture session is running? %d", [self.session isRunning]);
#endif
	
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
    
#ifdef PRINT_DEBUG_MSG
	if ([self session])
		NSLog(@"Capture session is running? %d", [self.session isRunning]);
#endif	
		
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
	if ([self record])
		[self stopVideoWriter];
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

/*! Set up video writer
	\param path video path	
	\param saveInLib save in videos library?
	\param error error
	\return <a>YES</a> if video writer was set up successfully
 */
- (BOOL) setupVideoWriter:(NSURL *)url width:(int)width height:(int)height
					error:(NSError **)error
{
    self.videoPath = url;

	AVAssetWriter *assetWriter = [[AVAssetWriter alloc] initWithURL:url
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:error];
	if (*error != nil)
	{
		SeeDebugLog(@"Could not create video writer.");
		return NO;
	}
	
	NSDictionary *settings = [NSDictionary dictionaryWithObjectsAndKeys:
							  AVVideoCodecH264, AVVideoCodecKey,
							  [NSNumber numberWithInt:width], AVVideoWidthKey,
							  [NSNumber numberWithInt:height], AVVideoHeightKey,
							  nil];
	
	AVAssetWriterInput *input = [AVAssetWriterInput 
								 assetWriterInputWithMediaType:AVMediaTypeVideo 
								 outputSettings:settings];
    
	if (!input)
	{
		SeeDebugLog(@"Could not create video writer input.");
		return NO;
	}	
    
    // rotate writer input so video looks right with protrait orientation
    [input setTransform:CGAffineTransformMakeRotation(M_PI/2.0)];
	
	if (![assetWriter canAddInput:input])
	{
		SeeDebugLog(@"Could not add writer input.");
		return NO;
	}
	
	[self setWriterInput:input];
	[assetWriter addInput:self.writerInput];
	
	[self setWriter:assetWriter];
	
	self.record = YES;
	
	return YES;
}


/*! Asset writer is saving video
 \return <a>YES</a> if video is being recorded
 */
- (BOOL)isWriting
{
	
#ifdef PRINT_DEBUG_MSG
	if ([self writer])
		NSLog(@"AssetWriterStatus = %d",[self.writer status]);
#endif	
	
	return ([self writer] != nil && 
            [self.writer status] == AVAssetWriterStatusWriting);
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
    
#ifdef PRINT_DEBUG_MSG
	NSLog(@"Got new frame.");
#endif
    
    if (!CMSampleBufferDataIsReady(sampleBuffer)){
        SeeDebugLog(@"SampleBuffer data is not ready");
        return;
    }
    
    // frame timestamp
	self.recordTime = CMSampleBufferGetPresentationTimeStamp( sampleBuffer );
    
    // process image
	if ([self.delegate respondsToSelector:@selector(processSampleBuffer:withPresentationTime:)])
    {
        [self.delegate processSampleBuffer:sampleBuffer withPresentationTime:self.recordTime];
    }
    	
    // append frame to video recording
	if ([self isWriting])
	{
#ifdef PRINT_DEBUG_MSG
		NSLog(@"Recording frame with timestamp: %f.", CMTimeGetSeconds(self.recordTime));
#endif
		if (![self.writerInput isReadyForMoreMediaData])
		{
			SeeDebugLog(@"Could not append new frame. Writer input is not ready.");
		}
		else if (![self.writerInput appendSampleBuffer:sampleBuffer])
		{
			SeeDebugLog(@"Could not append new frame. Append failed miserably.");
		}
	}
    // or start video writer? 
    else if (self.record && [self.writer status] != AVAssetWriterStatusCompleted)
    {
		NSError *error = nil;
		if (![self startVideoWriter:&error])
		{
            SeeDebugLog(@"An error occurred while trying to start the video writer.");
			NSLog(@"Error: %@", error);
			NSLog(@"%@", [error localizedDescription]);
			NSLog(@"%@", [error localizedFailureReason]); 
			NSLog(@"%@", [error localizedRecoverySuggestion]); 
			NSLog(@"%@", [error localizedRecoveryOptions]); 
		}        
    }
	
}

- (BOOL) saveCurrentFrame:(CMSampleBufferRef)frameSampleBuffer path:(NSString*)framePath
{
    if (!self.frameGrabberQueue) {
        self.frameGrabberQueue = dispatch_queue_create("edu.cmu.ri.apt.see.FrameGrabberQueue", NULL);
    }
    
    if (frameSampleBuffer == NULL) {
        SeeDebugLog(@"Error: Sample buffer is NULL.");
        return NO;
    }
    
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(frameSampleBuffer);
    
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
    CGImageRef imageRef = CGBitmapContextCreateImage(context); 
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace);
    
    dispatch_async(self.frameGrabberQueue, ^{
        CFURLRef frameURLRef = (__bridge CFURLRef)[NSURL fileURLWithPath:framePath];
        CFWriteStreamRef picLogStream = CFWriteStreamCreateWithFile(kCFAllocatorDefault,frameURLRef);
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(frameURLRef, kUTTypeJPEG, 1, NULL);
        CGImageDestinationAddImage(destination, imageRef, nil);
        
        bool success = CGImageDestinationFinalize(destination);
        if (!success) {
            SeeDebugLog(@"Failed to write image to %@", framePath);
        } else {
            SeeDebugLog(@"Saved %@", framePath);
        }
        
        CFRelease(destination);
        CFWriteStreamClose(picLogStream);
        CFRelease(picLogStream);
        CGImageRelease(imageRef);
    });
    
//    return success;
    return YES;
    
//    dispatch_async(frameGrabberQueue, ^{
//            
//        NSData *imageData = [NSData dataWithBytes:src_buff length:bytesPerRow * height];
//        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//        if (![imageData writeToFile:framePath atomically:NO]){
//            NSLog(@"Could not save image data to path %@", framePath);
//        }
//    });
//    
//    return YES;
}

//- (BOOL) saveCurrentFrameWithHandler:(void (^)(CMSampleBufferRef imageDataSampleBuffer, NSError *error))handler
//{
//    if (!self.stillCameraOutput){
//        SeeDebugLog(@"No still camera output could be found.");
//        return NO;     
//    }
//    
//    AVCaptureConnection *videoConnection = nil;
//    for (AVCaptureConnection *connection in self.stillCameraOutput.connections)
//    {
//        for (AVCaptureInputPort *port in [connection inputPorts])
//        {
//            if ([[port mediaType] isEqual:AVMediaTypeVideo] )
//            {
//                videoConnection = connection;
//                break;
//            }
//        }
//        if (videoConnection) { break; }
//    }
//    
//    if (videoConnection == nil) {
//        SeeDebugLog(@"No video connection could be found.");
//        return NO;
//    }
//    
//    [self.stillCameraOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:handler];
//    
//    return YES;
//}


/** Autofocus the camera now
    \return were we able to autofocus?
 */
- (BOOL) autofocus
{
    AVCaptureDevice *device = [[self cameraInput] device];
    if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
    {
        NSError *error;
        if ([device lockForConfiguration:&error])
        {
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
            [device unlockForConfiguration];
            return YES;
        } 
        else 
        {
            SeeDebugLog(@"Autofocus failed.\n%@", [error localizedDescription]);
        }
        
    }
    
    return NO;    
}

@end

@implementation ImageSource (Private)


/*! Start video writer
 \return <a>YES</a> if video writer was started successfully
 */
- (BOOL) startVideoWriter:(NSError **)error
{
	if ([self writer] != nil && self.record)
	{
		[self.writer startWriting];
		[self.writer startSessionAtSourceTime:self.recordTime];
		
		if ([self.writer status] == AVAssetWriterStatusFailed)
		{
			if (*error != NULL) *error = self.writer.error;
			SeeDebugLog(@"Could not start video writer!");
			return NO;
		}
		return YES;
	}
	return NO;
}

/*! Stop writing video
 \return <a>YES</a> if recording was successfully stopped or if no video is being written
 */
- (BOOL) stopVideoWriter
{
    BOOL ok = YES;
    
	if (self.record && [self isWriting])
	{
		[self.writerInput markAsFinished];
		[self.writer endSessionAtSourceTime:self.recordTime];
        [self.writer finishWritingWithCompletionHandler:^(){
            SeeDebugLog(@"finished writing");
            [ImageSource moveVideoToLib:self.videoPath];
        }];
        
        
//		ok = [self.writer finishWriting];
//        if (ok) [ImageSource moveVideoToLib:self.videoPath];
	}
	
    self.record = NO;
    
	return ok;
}

/*! Move recorded video to videos library
    \param path video path inside app bundle
 */
+ (void) moveVideoToLib:(NSURL *)url
{
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	ALAssetsLibraryWriteVideoCompletionBlock completionBlock = ^(NSURL *assetURL, NSError *error)
	{
#ifdef PRINT_DEBUG_MSG
		if (assetURL != nil)
		{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"Video AssetUrl : %@", [assetURL absoluteString]);
            });
		}
#endif
		if (error != nil)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                SeeDebugLog(@"An error occured while trying to save video: %@", [error localizedDescription]);
            });
        }
		
	};
	if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:url])
	{
		[library writeVideoAtPathToSavedPhotosAlbum:url 
									completionBlock:completionBlock];
	}
	else 
	{
		SeeDebugLog(@"Video is not compatible with library. Video could not be saved.");
	}
}

- (AVCaptureDevice *)backCamera
{
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == AVCaptureDevicePositionBack) {
#ifdef PRINT_DEBUG_MSG
			NSLog(@"Back camera is device %d",[device position]);
#endif
            return device;
        }
    }
    return nil;
}


@end
