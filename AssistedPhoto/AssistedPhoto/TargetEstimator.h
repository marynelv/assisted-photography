//
//  TargetGenerator.h
//  AudiballMix
//
//    Created by Marynel Vazquez on 09/13/2011.
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

#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import <BasicMath/Vector3.h>
#import "TargetMarkerView.h"
#import <AudioFeedback/RadialAudioFeedback.h>
#import <AudioFeedback/AudioClip.h>
#import <DataLogging/DLTextLog.h>

#define MAX_PROCESSING_TIME        SEC_TO_NANOS(60)       //\todo move to settings

/**
 Available audio feedback types
 */
typedef enum AudioFeedbackType {
    AUDIOFEEDBACK_SILENT,           //!< no audio feedback
    AUDIOFEEDBACK_PIANO,            //!< piano tone
    AUDIOFEEDBACK_PIANOBEEP,        //!< piano beep
//    AUDIOFEEDBACK_SUSUMU4,          //!< reordered selection of radial directions
    AUDIOFEEDBACK_SPEECH4,          //!< spoken "right","bottom","left","top" directions
    AUDIOFEEDBACK_NUM               //!< number of available audio feedback types
} AudioType;


/**
    Available target estimators
 */
typedef enum TargetEstimatorType {
    TARGET_PINHOLECAM_IMU,          //!< pinhole camera target estimator (with IMU tracking)
    TARGET_APH_OF,                  //!< assisted photography target estimator (with optic flow) 
    TARGET_NUM                      //!< number of available target generators
} TargetType;

/**
    Target estimator (selects a target and tracks it over time)
 
    The target may be a 3D or 2D point. The third dimension (z) may be
    useless and ignored by certain motion estimators. All subclasses must take care
    of recording target information in the <a>targetLog</a>.
 */
@interface TargetEstimator : UIViewController
@property (nonatomic, assign) Vector3 target;                            //!< target 
@property (nonatomic, retain) TargetMarkerView *targetMarkerView;        //!< target view controller
@property (nonatomic, retain) RadialAudioFeedback *audioFeedback;        //!< audio feedback
@property (nonatomic, assign) AudioType audioFeedbackType;
@property (nonatomic, retain) AudioClip *successAudioClip;               //!< clip to play when target reaches goal
@property (nonatomic, retain) AudioClip *startAudioClip;                 //!< clip to play when app starts processing
@property (nonatomic, retain) NSString *logIdentifier;                   //!< common log identifier
@property (nonatomic, retain) DLTextLog *targetLog;                      //!< target log
@property (atomic, assign) BOOL done;                                    //!< did the run ended?
@property (atomic, assign) float runningTime;                            //!< session running time
@property (atomic, assign) float processingTime;                         //!< processing time
@property (nonatomic, retain) UITapGestureRecognizer *startGestureRecognizer; //!< start-gesture recognizer
@property (nonatomic, retain) UILongPressGestureRecognizer *stopGestureRecognizer; //!< stop-gesture recognizer
@property (nonatomic, retain) UILabel *startInfoLabel;                   //!< label with info to start processing data


-(NSString*) vector3toStr:(Vector3*)v;
-(NSString *) description;

-(void) newTarget;
-(void) start;
-(void) startEstimatingMotion;
-(void) stopEstimatingMotion;
-(void) restart;
-(void) declareSuccessfulRun;
-(BOOL) isEstimatingMotion;
-(void) setAcceptanceRadius:(CGFloat)radius;
-(BOOL) setUpAudioFeedback:(AudioType)audioType;


-(BOOL) startLogging;
-(void) stopLogging;

-(void) stopAll;

-(NSString *)targetEstimatorDescription;

@end

@interface TargetEstimator (CustomClassMethods)

+(NSString *)commonLogIdentifier;

@end
