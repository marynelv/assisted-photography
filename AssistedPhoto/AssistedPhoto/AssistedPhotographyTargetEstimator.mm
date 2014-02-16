//
//  AssistedPhotographyTargetEstimator.m
//  AudiballMix
//
//    Created by Marynel Vazquez on 9/22/11.
//    Copyright 2011 Carnegie Mellon University.
//
//    This work was developed under the Rehabilitation Engineering Research 
//    Center on Accessible Public Transportation (www.rercapt.org) and is funded 
//    by grant number H133E080019 from the United States Department of Education 
//    through the National Institute on Disability and Rehabilitation Research. 
//    No endorsement should be assumed by NIDRR or the United States Government 
//    for the content contained on this code.
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in
//    all copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//    THE SOFTWARE.
//

#import "AssistedPhotographyTargetEstimator.h"
#import <Foundation/NSAutoreleasePool.h>
#import <See/ImageConversion.h>
#import <See/ImageSegmentation.h>
#import <Accelerate/Accelerate.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <ImageIO/CGImageProperties.h>
#import <DataLogging/DLTiming.h>
#import <BasicMath/Vector3.h>
#import <See/ImageMotion.h>
#import <ImageIO/CGImageDestination.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <ImageIO/CGImageProperties.h>
#import <CoreFoundation/CFDictionary.h>
#import <math.h>

#define PYR_SIZE     2 // 3
#define PYR_OFFSET   2 // 2
#define PYR_SURRLEV  2
#define TRACK_PYR_LEV 2

#define TEMPLATE_MIDSIZE 24

#define MAX_DISTANCE       288.0

inline float absf(float a){ return (a > 0 ? a : -a); }


inline float frameScore(CGPoint target, CGPoint goal)
{ 
    Vector2 diff(goal.x - target.x, goal.y - target.y);    
    return exp(-((diff.x*diff.x + diff.y*diff.y)/64800.0)) * 150;
}

@implementation AssistedPhotographyTargetEstimator
@synthesize imageSource;
@synthesize cameraView;
@synthesize inertialLog;
@synthesize computeROI;
@synthesize frameLog;
@synthesize motionManager;
@synthesize picture;
@synthesize startProcessing;

@synthesize bestFrameImageRef;
@synthesize bestFrameScore;
@synthesize bestFrameBlur;
//@synthesize bestFrameGravity;
@synthesize saveEveryBestFrame;
@synthesize minSeparationForNewBestFrame;
//@synthesize maxRunningTime;

/**
    Take care of specific view setting up
 */
-(void) viewDidLoad
{
    [super viewDidLoad];
    
    self.computeROI =YES;
    
    CGRect cameraViewFrame = self.view.frame;
    cameraViewFrame.size.height = round(cameraViewFrame.size.width*IMAGE_WIDTH/IMAGE_HEIGHT);
    
    self.cameraView = [[RenderedCameraView alloc] initWithFrame:cameraViewFrame 
                                              maxProcessingSize:MakeGLVSize((int)IMAGE_HEIGHT >> PYR_OFFSET, 
                                                                            (int)IMAGE_WIDTH >> PYR_OFFSET)
                                                maxSizeTracking:MakeGLVSize((int)IMAGE_HEIGHT >> TRACK_PYR_LEV, 
                                                                            (int)IMAGE_WIDTH >> TRACK_PYR_LEV)];
    self.cameraView.eaglLayer.contentsGravity = kCAGravityResizeAspect;
    self.cameraView.delegate = self;
//   [self.view addSubview:self.cameraView];
    [self.view insertSubview:self.cameraView atIndex:0];  
    
#ifdef LOG_EXPERIMENT_DATA
    [self.targetLog appendString:[NSString stringWithFormat:@"# tracker %d %f %d\n", (int)TEMPLATE_MIDSIZE,
                                  self.cameraView.template_tracking_epsilon, self.cameraView.template_tracking_maxIter]];
#endif

}

/**
    Release subviews
 */
-(void) viewDidUnload
{
    [super viewDidUnload];
        
    [self stopEstimatingMotion];
    [self stopLogging];
    self.cameraView = nil;
}

/**
    Generate new target using saliency estimation method
 */
-(void) newTarget
{
    self.computeROI = TRUE;
    [self.targetMarkerView setNeedsDisplay];
}

/**
 Start app and logging but, don't process data yet
 */
-(void) start
{
    [super start];    
    
    // custom init
    self.startProcessing = NO;
    self.picture = nil;
    self.bestFrameScore = -1;
    self.saveEveryBestFrame = YES;
    self.bestFrameImageRef = NULL;
    self.minSeparationForNewBestFrame = MIN_SEPARATION;
//    self.maxRunningTime = MAX_RUNNING_TIME;
    
    self.targetMarkerView.hidden = YES;
    
    self.imageSource = [[ImageSource alloc] init];
    [self.imageSource setDelegate:self];
    
    NSError *error = nil;
    if (![self.imageSource setupCaptureSessionWithPreset:IMAGE_QUALITYPRESET error:&error])
    {
        DebugLog(@"Could not set up capture session! Got error: %@", error);
        DebugLog(@"%@", [error localizedDescription]);
        DebugLog(@"%@", [error localizedFailureReason]); 
        DebugLog(@"%@", [error localizedRecoverySuggestion]); 
        DebugLog(@"%@", [error localizedRecoveryOptions]); 
        self.imageSource = nil;
    }                       
    
    [self.imageSource startCaptureSession];

}

/**
    Do what is necessary to start estimating motion
 */
-(void) startEstimatingMotion
{    
//    self.picture = nil;
//    self.bestFrameScore = -1;
//    self.saveEveryBestFrame = YES;
//    self.bestFrameImageRef = NULL;
//    self.minSeparationForNewBestFrame = MIN_SEPARATION;
//    self.maxRunningTime = MAX_RUNNING_TIME;
    
    if (self.done == YES || self.processingTime != 0) return;
    
    if (self.audioFeedbackType == AUDIOFEEDBACK_SILENT) {
        [self.startAudioClip play];
    }
    
    self.startInfoLabel.hidden = YES;
    
    [self.targetMarkerView startAnimation:CGPointMake(-1.0f,-1.0f)];
    [self.targetMarkerView setTargetGoal:CGPointMake(self.cameraView.frame.size.width/2.0,
                                                     self.cameraView.frame.size.height/2.0)];
    
    self.targetMarkerView.hidden = NO;
    
    [self newTarget];
    self.startProcessing = YES;
    
    
    self.processingTime = tic();
}

/**
    Do what is necessary to stop estimating motion
 */
-(void) stopEstimatingMotion
{    
    [self.imageSource stopCapturingSession];
    [self.audioFeedback stop];
    [self.targetMarkerView stopAnimation];
}


/**
    Declare successful run after the target reached the goal
 */
-(void) declareSuccessfulRun
{
#ifdef LOG_EXPERIMENT_DATA
    NSConditionLock* lock = [[NSConditionLock alloc] initWithCondition:0];
    [lock lock];
    [lock unlockWithCondition:self.targetLog == nil];
#endif
  
    UIImageView *imageView = [[UIImageView alloc] initWithImage:self.picture];
    imageView.backgroundColor = [UIColor blackColor];
//    CGAffineTransform transform = CGAffineTransformMakeRotation(M_PI/2.0);
//    imageView.transform = transform;
//    imageView.frame = self.view.frame;
    imageView.frame = self.cameraView.frame;
//    imageView.bounds = self.view.bounds;
//    NSLog(@"bounds: %f %f %f %f", imageView.bounds.origin.x, imageView.bounds.origin.y, 
//          imageView.bounds.size.width, imageView.bounds.size.height);
//    NSLog(@"frame: %f %f %f %f", imageView.frame.origin.x, imageView.frame.origin.y, 
//          imageView.frame.size.width, imageView.frame.size.height);
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:imageView];
    
    [self saveFinalPic];
    
//    [self dismissModalViewControllerAnimated:YES];
    
    [super declareSuccessfulRun];
}

/**
    Is motion being estimated?
 */
-(BOOL) isEstimatingMotion
{
    return [self.imageSource.session isRunning];
}


/**
    Start logging common data accross all target estimators
    @return are we logging?
 */
-(BOOL) startLogging
{
    BOOL ok = [super startLogging];
    // \todo add more logs here
    
    NSString *frameStr = [NSString stringWithFormat:@"%@_camera", self.logIdentifier];
    self.frameLog = [[DLFrameLog alloc] initWithName:frameStr];
    
    self.motionManager = [[CMMotionManager alloc] init];
    if (!self.motionManager.isDeviceMotionAvailable)
    { /* should not continue without sensors */
        [NSException raise:NSInternalInconsistencyException 
                    format:@"DeviceMotion is not available"];
    } 
    NSString *accelStr = [NSString stringWithFormat:@"%@_accel", self.logIdentifier];
    NSString *gyroStr = [NSString stringWithFormat:@"%@_gyro", self.logIdentifier];
    self.inertialLog = [[DLInertialLog alloc] initWithAccelFile:accelStr 
                                                       GyroFile:gyroStr 
                                                  motionManager:self.motionManager];
    
    ok = ok && (self.frameLog != nil);
    return ok;
}

/**
    Stop logging common data accross all target estimators
 */
-(void) stopLogging
{
    [super stopLogging];
    
    self.inertialLog = nil;
    if (self.motionManager != nil)
    {
        if ([self.motionManager isDeviceMotionActive])
            [self.motionManager stopDeviceMotionUpdates];
        
        self.motionManager = nil;
    }
    
    self.frameLog = nil;
}

/**
    String description of target estimator
    @return string description
 */
-(NSString *)targetEstimatorDescription
{
    NSString *str = [[NSString alloc] initWithFormat:@"%@ %s %d %d", [super targetEstimatorDescription],
                     TO_STRING(IMAGE_QUALITYPRESET), (int)IMAGE_WIDTH, (int)IMAGE_HEIGHT];
    return str;
}

- (void) alertTrackingFailure:(NSString*)message
{
    NSLog(@"Out of bounds");
}

@end

@implementation AssistedPhotographyTargetEstimator (ImageSourceDelegate)

/**
    Process sample buffer coming from video input
    @param sampleBuffer sample buffer
 */
-(void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time
{ 
    if (self.done)
    {
        return; // stop processing
    }
    
    // ------------------------------------------------------------------------ //
    // Get a CMSampleBuffer's Core Video image buffer
    CVPixelBufferRef pixelBufferRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    BOOL saveFrame = self.frameLog.frameCount % 5 == 0;
    // ------------------------------------------------------------------------ //
    // Only log and display if we are not ready to start
    if (!self.startProcessing){
#ifdef LOG_EXPERIMENT_DATA
        [self.frameLog saveFrame:sampleBuffer presentationTime:time appendStrToName:@"_aiming"];
#endif
        [self.cameraView renderPixelBufferRef:pixelBufferRef];
        return;
    }
    // ------------------------------------------------------------------------ //
    // Process otherwise

    else if (saveFrame)
    {
#ifdef LOG_EXPERIMENT_DATA
        [self.frameLog saveFrame:sampleBuffer presentationTime:time];
#else
        [self.frameLog skipFrameWithPresentationTime:time];
#endif
    }
    else
    {
        [self.frameLog skipFrameWithPresentationTime:time];
    }
    
    if (self.frameLog.frameCount == 0)
    {
        return; // stop processing because first image is always bad (seems like the shutter is not ready)
    }
    
    float distance = 0, radians = 0, blur = 1;
    TRACKINGRESULT trackingStatus = TRACKING_OK;
    Vector3 trackingResult; // x is motion.x, y is motion.y, and z is blur of tracked region in nextIm
    img nextIm;
    NSString *str;
    
    if (self.computeROI)
    {            
        
        [self.cameraView discardResizeShader];
        [self.cameraView setUpColorResizeShader];
        
        size_t w = 0, h = 0;
        float wx = 0, wy = 0;
        
        // ------------------------------------------------------------------------ //
        // Compute Saliency
        img saliency = 0; 
        saliency = [self.cameraView glSaliencyFromPixelBufferRef:pixelBufferRef width:&w height:&h 
                                                          pyrLev:PYR_SIZE surrLev:PYR_SURRLEV];
            
        // save saliency image
        NSString *imageName = [NSString stringWithFormat:@"%@_saliency.jpeg", self.logIdentifier];
#ifdef LOG_EXPERIMENT_DATA
        if (![self saveGrayImg:saliency width:w height:h withName:imageName])
        {
            NSLog(@"Could not save saliency image");
        }
#endif
        
        see_uniformThresh(&saliency, w*h);
        
        int nlabels = 0;
        img labels = see_labelBlobs(saliency, w, h, nlabels);
        
        float selected = see_selectMostMeaningfulBlob(saliency, w*h, labels, nlabels, 
                                                      true, 0, 0, 0, 0);
        see_weightedMean( saliency, w, h, labels, selected, wx, wy);
            
        // ------------------------------------------------------------------------ //
        // Update target-related variables    
        goal = Vector2(wx*self.cameraView.maxProcessingSizeTracking.height/w,wy*self.cameraView.maxProcessingSizeTracking.width/h);
        [self.cameraView setTemplateBox:Rectangle(wx - TEMPLATE_MIDSIZE, wy - TEMPLATE_MIDSIZE,
                                                  wx + TEMPLATE_MIDSIZE, wy + TEMPLATE_MIDSIZE)];
        self.targetMarkerView.targetPoint = CGPointMake(self.cameraView.frame.size.width - 
                                                            wy*self.cameraView.frame.size.width/h,
                                                        wx*self.cameraView.frame.size.height/w);

    
    
//        // ------------------------------------------------------------------------ //
//        // Manually draw target
//        CVPixelBufferLockBaseAddress( pixelBufferRef, 0 );
//        unsigned char *rowBase = (unsigned char *)CVPixelBufferGetBaseAddress(pixelBufferRef);
//        int bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBufferRef);
//        size_t pixelBuffWidth = CVPixelBufferGetWidth( pixelBufferRef );
//        size_t pixelBuffHeight = CVPixelBufferGetHeight( pixelBufferRef ); 
//
//        Vector2 goal2(((int)wy)<<PYR_OFFSET, ((int)wx)<<PYR_OFFSET);
//        size_t goalSizeDiv2 = 40;
//        
//        for ( int row = (goal2.x < goalSizeDiv2 ? 0 : goal2.x - goalSizeDiv2); 
//                  row < (goal2.x > pixelBuffWidth - 1 - goalSizeDiv2 ? pixelBuffWidth - 1 : goal2.x + goalSizeDiv2); 
//                  row += 1 )
//        {
//            for (int col = (goal2.y < goalSizeDiv2 ? 0 : goal2.y - goalSizeDiv2); 
//                     col < (goal2.y > pixelBuffHeight - 1 - goalSizeDiv2 ? pixelBuffHeight - 1 : goal2.y + goalSizeDiv2); 
//                     col += 1 )
//            {
//                rowBase[col*4 + (row * bytesPerRow)] = 0;
//                rowBase[col*4 + (row * bytesPerRow)+1] = 0;
//                rowBase[col*4 + (row * bytesPerRow)+2] = 255;
//            }
//        }
//       
//        // ------------------------------------------------------------------------ //
//        // Draw highlight and mini target
//        img highlight = 0;
//        see_highlightBlob( labels, w*h, selected, &highlight, 255.0 );    
//        
//        for ( int row = 0; row < h; row += 1 )
//        {
//            vDSP_vfixru8(highlight + (row*w),1,rowBase + (row * bytesPerRow),4,w);
//            vDSP_vfixru8(highlight + (row*w),1,rowBase + (row * bytesPerRow) + 1,4,w);
//            vDSP_vfixru8(highlight + (row*w),1,rowBase + (row * bytesPerRow) + 2,4,w);
//        }
//        
//        int top = (floor)(wy-3); if (top < 0) top = 0;
//        int bottom = (floor)(wy+3); if (bottom > h) bottom = h;
//        int left = (floor)(wx-3); if (left < 0) left = 0;
//        int right = (floor)(wx+3); if (right > w) right = w;
//        for ( int row = top; row < bottom; row++ )
//        {
//            for ( int col = left; col < right; col++ )
//            {
//                rowBase[col*4 + (row * bytesPerRow)] = 255;
//                rowBase[col*4 + (row * bytesPerRow)+1] = 0;
//                rowBase[col*4 + (row * bytesPerRow)+2] = 0;
//            }
//        }
//
//        free(highlight);
//        
//        // ------------------------------------------------------------------------ //
//        // Draw saliency
//        see_scaleTo(saliency, w*h, 255.0);
//        for ( int row = 0; row < h; row += 1 )
//        {		
//            vDSP_vfixru8(saliency + (row*w),1,rowBase + (row * bytesPerRow),4,w);
//            vDSP_vfixru8(saliency + (row*w),1,rowBase + (row * bytesPerRow) + 1,4,w);
//            vDSP_vfixru8(saliency + (row*w),1,rowBase + (row * bytesPerRow) + 2,4,w);
//        }    
//        CVPixelBufferUnlockBaseAddress( pixelBufferRef, 0 );
//        // ------------------------------------------------------------------------ //

        imageName = [NSString stringWithFormat:@"%@_saliencyLabels.jpeg", self.logIdentifier];
#ifdef LOG_EXPERIMENT_DATA
        if (![self saveGrayImg:labels width:w height:h withName:imageName])
        {
            NSLog(@"Could not save saliency image");
        }
#endif
        
        free(saliency);
        free(labels);
                
        self.computeROI = NO;
        
        [self.cameraView discardResizeShader];
        
#ifdef LOG_EXPERIMENT_DATA
        @autoreleasepool {
            NSString *strMeta = [NSString stringWithFormat:@"# saliency %07d %lu %lu %f %f \n# init_state %f %f %f %f %f %f\n", 
                                 self.frameLog.frameCount,
                                 w, h, wx, wy,
                                 self.targetMarkerView.targetPoint.x, self.targetMarkerView.targetPoint.y,
                                 self.targetMarkerView.targetGoal.x, self.targetMarkerView.targetGoal.y,
                                 self.cameraView.frame.size.width, self.cameraView.frame.size.height];
            if (![self.targetLog appendString:strMeta])
            {
                DebugLog(@"ERROR: Could not record target status in log!");
            }
        }
#endif
        
        // ------------------------------------------------------------------------ //
        // Update audio feedback
        // but also start feedback because this is the first time we update target position
        distance = [self.targetMarkerView distanceToGoal];
        radians = [self.targetMarkerView targetOrientation];
        [self.audioFeedback startWithDistance:&distance andOrientation:&radians];  
        
        // ------------------------------------------------------------------------ //
        // Set up tracking
        [self.cameraView setUpGrayResizeShader];
        
        nextIm = [cameraView intensityFromPixelBufferRef:pixelBufferRef];
        trackingResult = [cameraView trackTemplate:nextIm];
        free(nextIm);    
        
        blur = trackingResult.z;
        trackingStatus = self.cameraView.trackingStatus;
//        trackingOK = self.cameraView.trackingStatus == TRACKING_OK;
    } 
    else
    {
//        if (self.cameraView.pResize == nil) [self.cameraView setUpGrayResizeShader];
        
        // ------------------------------------------------------------------------ //
        // Track ROI  
        
        nextIm = [cameraView intensityFromPixelBufferRef:pixelBufferRef];
        trackingResult = [cameraView trackTemplate:nextIm];
        free(nextIm);     
        
        blur = trackingResult.z;
        trackingStatus = self.cameraView.trackingStatus;
//        trackingOK = self.cameraView.trackingStatus == TRACKING_OK;
            
//        if (trackingOK) {
        if (trackingStatus  == TRACKING_OK) {
            goal.x += trackingResult.x;
            goal.y += trackingResult.y;
            float w = self.cameraView.maxProcessingSizeTracking.width;
            float h = self.cameraView.maxProcessingSizeTracking.height;
            self.targetMarkerView.targetPoint = CGPointMake(self.cameraView.frame.size.width - 
                                                            goal.y*self.cameraView.frame.size.width/w,
                                                            goal.x*self.cameraView.frame.size.height/h);
            
//            std::cout << motion << std::endl;
            
            // ------------------------------------------------------------------------ //
            // Update audio feedback
            distance = [self.targetMarkerView distanceToGoal];
            radians = [self.targetMarkerView targetOrientation];
            [self.audioFeedback updateFeedbackWithDistance:&distance andOrientation:&radians];  
        }
        
    }
    
    // ------------------------------------------------------------------------ //
    // Render image on screen
    [self.cameraView renderPixelBufferRef:pixelBufferRef]; 
    
    BOOL reachedGoal = [self.targetMarkerView targetReachedGoal];
    BOOL isNewBestFrame = (self.bestFrameScore < 0 || 
                           (reachedGoal && (blur < self.bestFrameBlur + 0.05 || self.bestFrameBlur < 0)) ||
                           (distance <= (self.bestFrameScore - self.minSeparationForNewBestFrame) && 
                                ((blur < self.bestFrameBlur + 0.05) || self.bestFrameBlur < 0)) ||
                           (distance <= self.bestFrameScore && 
                                ((blur >= 0 && blur < (self.bestFrameBlur - 0.1)) || self.bestFrameBlur < 0)));
    if (isNewBestFrame && (trackingStatus  == TRACKING_OK))
    {
#ifdef LOG_EXPERIMENT_DATA
        if (!saveFrame) // save in case we did not do it before
            [self.frameLog saveFrame:sampleBuffer appendStrToName:nil];
#endif
        
        self.bestFrameBlur = blur;
        self.bestFrameScore = distance;
        
        OCVector3 *smoothedAcc = [self.inertialLog getLatestSmoothedAcceleration];
        bestFrameGravity = Vector3(smoothedAcc.getXAccel, smoothedAcc.getYAccel, smoothedAcc.getZAccel);
        
        if (self.bestFrameImageRef != NULL) {
            CGImageRelease(self.bestFrameImageRef);
            self.bestFrameImageRef = NULL;
        }
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer, 0);
        
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
        size_t width = CVPixelBufferGetWidth(imageBuffer); 
        size_t height = CVPixelBufferGetHeight(imageBuffer);  
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, 
                                                     colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
        self.bestFrameImageRef = CGBitmapContextCreateImage(context);
        CGColorSpaceRelease(colorSpace);
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        CGContextRelease(context); 

//        NSLog(@"NEW BEST FRAME");
    }
    
#ifdef LOG_EXPERIMENT_DATA
    // update target log
    str = [NSString stringWithFormat:@"%07d %f %f %f %f %f %f %d %d %d\n", self.frameLog.frameCount, CMTimeGetSeconds(time), 
           self.targetMarkerView.targetPoint.x, self.targetMarkerView.targetPoint.y, 
           distance, radians, blur, trackingStatus, isNewBestFrame, reachedGoal];
    if (![self.targetLog appendString:str])
    {
        DebugLog(@"ERROR: Could not record target status in log!");
    }
#endif
    
    if (reachedGoal || (trackingStatus != TRACKING_OK) || (toc(self.processingTime) > MAX_PROCESSING_TIME))
    {                
        [self preparePicPresentation:sampleBuffer];
        self.done = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self declareSuccessfulRun];
        });
    }
    
}


-(void) preparePicPresentation:(CMSampleBufferRef)sampleBuffer
{
    @autoreleasepool {
    
//    CGImageRef imageRef = NULL;
    CGImageRef rotatedImage = NULL;

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

//    uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer); 
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer); 
    size_t width = CVPixelBufferGetWidth(imageBuffer); 
    size_t height = CVPixelBufferGetHeight(imageBuffer);  
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
//    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, 
//                                                 colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
//    imageRef = CGBitmapContextCreateImage(context); 
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//    CGContextRelease(context); 

    
    // rotate image if necessary
//    Vector3 gravity = [self.inertialLog latestSmoothedAccel];
    Vector3 gravity = bestFrameGravity;
    gravity.normalize();
    
//    NSLog(@"Comparing absf(%f) > %f (20deg)", gravity.dot(Vector3(0,1,0)), cosf(20.0*M_PI/180.0));
    float theta;
    if (absf(gravity.dot(Vector3(0,1,0))) > absf(cosf(30.0*M_PI/180.0))) {
        theta = -M_PI + acosf(gravity.dot(Vector3(1,0,0)));
        //-(M_PI - acosf(...))
    } else {
        theta = -M_PI*0.5;
    }
        
//        NSLog(@"Rotating by %f (%f deg) along z", theta, theta*180.0/M_PI);
        
    CGRect imgRect = CGRectMake(0, 0, width, height);
    CGAffineTransform transform = CGAffineTransformMakeRotation(theta);
    CGRect rotatedRect = CGRectApplyAffineTransform(imgRect, transform);
    NSLog(@"rotated rect: %f %f %f %f", 
          rotatedRect.origin.x, rotatedRect.origin.y,
          rotatedRect.size.width, rotatedRect.size.height);
    
    CGContextRef bmContext = CGBitmapContextCreate(NULL,
                                                   rotatedRect.size.width,
                                                   rotatedRect.size.height,
                                                   8,
                                                   0,
                                                   colorSpace,
                                                   kCGImageAlphaPremultipliedFirst);
    CGContextSetAllowsAntialiasing(bmContext, FALSE);
    CGContextSetInterpolationQuality(bmContext, kCGInterpolationHigh);
    
    CGContextTranslateCTM(bmContext,
                          +(rotatedRect.size.width*0.5),
                          +(rotatedRect.size.height*0.5));
    CGContextRotateCTM(bmContext, theta);
    CGContextTranslateCTM(bmContext,
                          -(imgRect.size.width*0.5),
                          -(imgRect.size.height*0.5));
//    CGContextDrawImage(bmContext, 
//                       CGRectMake(0,0, 
//                                  imgRect.size.width, imgRect.size.height),
//                       imageRef); 
    CGContextDrawImage(bmContext, 
                       CGRectMake(0,0, 
                                  imgRect.size.width, imgRect.size.height),
                       self.bestFrameImageRef);     
    rotatedImage = CGBitmapContextCreateImage(bmContext);
//    CGImageRelease(imageRef); imageRef = NULL;
    CGImageRelease(self.bestFrameImageRef); self.bestFrameImageRef = NULL;
    CGContextRelease(bmContext);
//    }
    
    CGColorSpaceRelease(colorSpace);
    
//    if (imageRef == NULL) {
        self.picture = [UIImage imageWithCGImage:rotatedImage];
        CGImageRelease(rotatedImage);
//    } else {
//        self.picture = [UIImage imageWithCGImage:imageRef];
//        CGImageRelease(imageRef);
//    }
    
#ifdef LOG_EXPERIMENT_DATA
    // update target log
    NSString *str = [NSString stringWithFormat:@"# final_picture_gravity %f %f %f\n# final_picture_theta %f\n", 
                     gravity.x, gravity.y, gravity.z, theta];
    if (![self.targetLog appendString:str])
    {
        DebugLog(@"ERROR: Could not record target status in log!");
    }
#endif
        
    }
}

-(BOOL) saveFinalPic
{
    if (self.picture == nil) return NO;
    
    NSData *imageData = UIImageJPEGRepresentation(self.picture, 1.0f);
    NSString *imageName = [DLLog fullFilePath:[[NSString alloc] 
                                               initWithFormat:@"%@_finalPicture.jpg",self.logIdentifier]];
#ifdef LOG_EXPERIMENT_DATA
    if (![imageData writeToFile:imageName atomically:NO])
    {
        NSLog(@"Could not save final image.");
    }
#endif
    
#ifdef SAVE_PIC_CAM_ROLL
    UIImageWriteToSavedPhotosAlbum(self.picture, nil, nil, nil);
#endif
    
    return YES;
}

// note: image values are not normalized. this should be made prior to calling this func
-(BOOL) saveGrayImg:(img)image width:(size_t)w height:(size_t)h withName:(NSString*)imageName
{
    BOOL ok = YES;
    img scaledIm = see_scaleToAndCopy(image, w*h, 255.0);;
    ucimg imageChar = see_floatArrayToUChar(scaledIm, w*h, 0, 0, 1);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray(); 
    CGContextRef context = CGBitmapContextCreate(imageChar, w, h, 8, w, colorSpace, kCGBitmapByteOrderDefault); 
    CGImageRef imageRef = CGBitmapContextCreateImage(context); 
    CGContextRelease(context); 
    CGColorSpaceRelease(colorSpace);
    
    NSString *framePath = [DLLog fullFilePath:imageName];
    CFURLRef frameURLRef = (__bridge CFURLRef)[NSURL fileURLWithPath:framePath];
    CFWriteStreamRef picLogStream = CFWriteStreamCreateWithFile(kCFAllocatorDefault,frameURLRef);
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(frameURLRef, kUTTypeJPEG, 1, NULL);
    CFMutableDictionaryRef saveMetaAndOpts = CFDictionaryCreateMutable(nil, 0, 
                                                                       &kCFTypeDictionaryKeyCallBacks,  
                                                                       &kCFTypeDictionaryValueCallBacks);
    NSNumber *qualityLevel = [NSNumber numberWithFloat:0.8];
    CFNumberRef compressionQuality = (__bridge CFNumberRef) qualityLevel;
    CFDictionarySetValue(saveMetaAndOpts, 
                         kCGImageDestinationLossyCompressionQuality, compressionQuality);	
    CGImageDestinationAddImage(destination, imageRef, saveMetaAndOpts); // pass nil as last argument for no extra options
    
    bool success = CGImageDestinationFinalize(destination);
    if (!success) {
        DebugLog(@"Failed to write image to %@", framePath);
        ok = NO;
    } 
    CFRelease(destination);
    CFWriteStreamClose(picLogStream);
    CFRelease(picLogStream);
    CGImageRelease(imageRef);
    CFRelease(saveMetaAndOpts);

    free(imageChar);
    free(scaledIm);
    
    return ok;
}

@end