//
//  AssistedPhotographyTargetEstimator.h
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


#import "TargetEstimator.h"
#import <BasicMath/Vector2.h>
#import <See/ImageSource.h>
#import "RenderedCameraView.h"
#import <DataLogging/DLInertialLog.h>
#import <DataLogging/DLFrameLog.h>
//#import "VideoLog.h"

// capture session options:
// AVCaptureSessionPreset640x480
// AVCaptureSessionPresetLow (192x144, max fps 15) 
// AVCaptureSessionPresetMedium (480x360, max fps 30)
#define IMAGE_QUALITYPRESET     AVCaptureSessionPreset640x480   //!< back camera image quality
#define IMAGE_WIDTH             640.0                           //!< back camera image width
#define IMAGE_HEIGHT            480.0                           //!< back camera image height

#define MIN_SEPARATION          10                              //\todo move to settings

#define LOG_EXPERIMENT_DATA                                     // comment to log less data into app space
#define SAVE_PIC_CAM_ROLL                                       // save final picture to camera roll?

typedef struct ExponentialParams {
    Vector2 mean;
    float a;
    float b;
    float c;
    
    ExponentialParams(Vector2 im, float ia, float ib, float ic){
        mean = im;
        a = ia;
        b = ib;
        c = ic;
    }
    
} ExpParams;

/**
    AssistedPhotographyTargetEstimator (with undefined tracking)
    Targets are generated from an initial camera image based on visual saliency attributes.
    The motion estimation methods are left empty for subclasses to define.
 */
@interface AssistedPhotographyTargetEstimator : TargetEstimator <ImageSourceDelegate, TrackingDelegate>
{
    Vector2 goal;
    Vector3 bestFrameGravity;
}

@property (nonatomic, retain) ImageSource *imageSource;         //!< image source
@property (nonatomic, retain) RenderedCameraView *cameraView;   //!< camera view
@property (nonatomic, retain) CMMotionManager *motionManager;   //!< motion manager
@property (nonatomic, retain) DLInertialLog *inertialLog;       //!< inertial (accel + gyro) log
@property (nonatomic, retain) DLFrameLog *frameLog;             //!< frame log
@property (nonatomic, assign) BOOL computeROI;                  //!< computer ROI?
@property (atomic, retain) UIImage *picture;                    //!< final picture
@property (atomic, assign) BOOL startProcessing;                //!< start processing the images?

// scoring system
@property (atomic, assign) CGImageRef bestFrameImageRef;        //!< best frame image ref
@property (atomic, assign) float bestFrameScore;                //!< score of best frame
@property (atomic, assign) float bestFrameBlur;                 //!< blurriness of best frame
//@property (atomic, assign) Vector3 bestFrameGravity;            //!< gravity when best frame was captured
@property (atomic, assign) BOOL saveEveryBestFrame;             //!< save every best frame?
@property (atomic, assign) float minSeparationForNewBestFrame;  //!< minimum distance separation for new best frame (manhattan distance)
//@property (atomic, assign) float maxRunningTime;                //!< maximum running time before the run ends

-(void) viewDidLoad;
-(void) viewDidUnload;

-(void) newTarget;
-(void) start;
-(void) startEstimatingMotion;
-(void) stopEstimatingMotion;
-(void) declareSuccessfulRun;
-(BOOL) isEstimatingMotion;

-(BOOL) startLogging;
-(void) stopLogging;

-(NSString *)targetEstimatorDescription;

- (void) alertTrackingFailure:(NSString*)message;

@end

@interface AssistedPhotographyTargetEstimator (ImageSourceDelegate)

-(void) processSampleBuffer:(CMSampleBufferRef)sampleBuffer withPresentationTime:(CMTime)time;
-(void) preparePicPresentation:(CMSampleBufferRef)sampleBuffer;
-(BOOL) saveFinalPic;
-(BOOL) saveGrayImg:(img)image width:(size_t)w height:(size_t)h withName:(NSString*)imageName;

@end