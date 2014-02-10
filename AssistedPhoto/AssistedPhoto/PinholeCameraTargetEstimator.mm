//
//  RandomTargetGenerator.m
//  AudiballMix
//
//    Created by Marynel Vazquez on 09/14/2011.
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

#import "PinholeCameraTargetEstimator.h"
#import <DataLogging/DLTiming.h>

#pragma mark Definitions

// random number generator
#define ARC4RANDOM_MAXFLT ((float)UINT32_MAX)       //!< max random number

// device motion
#define DEVICEMOTION_UPDATE_INTERVAL 1.0/50.0       //!< update frequency: 50 Hz

// camera settings
#define CAMERA_IMWIDTH      320                     //!< image width
#define CAMERA_IMHEIGHT     480                     //!< image height
#define CAMERA_F            605.4341                //!< focal length: 0.028/4.6e-5
#define CAMERA_PX           (CAMERA_IMWIDTH / 2.0)  //!< horizontal camera center
#define CAMERA_PY           (CAMERA_IMHEIGHT / 2.0) //!< vertical camera center

// target point bounds
#define POINT_MINDEPTH     CAMERA_F
#define POINT_MAXDEPTH     (CAMERA_F+1000)

#define MAX_DISTANCE       288.0

// easy access to matrix elements
enum MAT_ROT                                        //!< rotation matrix
{
	ROT11, ROT12, ROT13,
	ROT21, ROT22, ROT23,
	ROT31, ROT32, ROT33
};

enum MAT_CAM                                        //!< camera matrix
{
    CAM11, CAM12, CAM13, CAM14,
    CAM21, CAM22, CAM23, CAM24,
    CAM31, CAM32, CAM33, CAM34
};


#pragma mark
#pragma mark Util methods/functions

/**
    Generate random number inside (float) range
    @param minfloat minimum floating number
    @param maxfloat maximum floating number
    @return random number inside range
 */
inline float randomNumber(float minfloat, float maxfloat)
{
    assert(maxfloat > minfloat);
    float range = maxfloat-minfloat;
    float val = floorf(((float)arc4random() / ARC4RANDOM_MAXFLT) * range) + minfloat;
    return val;
}

#pragma mark
#pragma mark Private

@interface PinholeCameraTargetEstimator (Private)

-(void) updateTargetPosition:(CMDeviceMotion*)deviceMotion error:(NSError *)error;

@end


@implementation PinholeCameraTargetEstimator (Private)

/**
    Updates the camera's extrinsic parameters from the estimated motion and 
    reprojects the target on the screen
    @param deviceMotion device motion
    
    @note We assume the deviceMotion frame of reference points long the typical accel x,y,z axis 
    (using CMAttitudeReferenceFrameXArbitraryZVertical). A quaternion was obtained from the initial referenceAttitude, 
    and it seemed to be very close to 0 rotation. Maybe noise is affecting this value?
 */
-(void) updateTargetPosition:(CMDeviceMotion*) deviceMotion error:(NSError *)error
{
    if (self.done) return; // don't do anything if we already reached the goal
    if (toc(self.processingTime) > MAX_PROCESSING_TIME)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self declareSuccessfulRun];
            self.startInfoLabel.text = @"Time's up.";
            self.startInfoLabel.hidden = NO;
        });
    }
    
    double ticTime = tic();
    float distance, radians = -1;
    
    [self.deviceMotionLog appendDeviceMotionData:deviceMotion error:error];
    
    // save reference attitude if it's missing 
    if (self.referenceAttitude == nil)
    {
        self.referenceAttitude = deviceMotion.attitude;
        
        // but also start feedback because this is the first time we update target position
        distance = [self.targetMarkerView distanceToGoal];
        if ([self.audioFeedback caresAboutRadialOrientation])
        {
            radians = [self.targetMarkerView targetOrientation];
            [self.audioFeedback startWithDistance:&distance andOrientation:&radians];   
        }
        else
        {
            [self.audioFeedback startWithDistance:&distance andOrientation:NULL]; 
        }
        
        return;
    }
        
    // get device orientation
    CMAttitude *currentAttitude = deviceMotion.attitude;    
    // then get camera orientation (though there's no need to store it)
    [currentAttitude multiplyByInverseOfAttitude:self.referenceAttitude];
    CMQuaternion q = [currentAttitude quaternion];
    Quaternion camOrientation(q.w, q.x, q.y, q.z);
    camOrientation = camOrientation*Quaternion(0, 1, 0, 0); // camera frame is 180deg (rotating along x) from the device frame
    camOrientation.normalize();
    
    // get linear acceleration
    CMAcceleration userAcceleration = deviceMotion.userAcceleration; 
    
    // update extrinsic camera parameters
    // first take care of the linear motion components
    // use very simple integrator for the simulation (probably this can be improved)
    float deltaT = DEVICEMOTION_UPDATE_INTERVAL;
    self.cameraPosition = self.cameraPosition + self.cameraVelocity * deltaT + self.cameraAcceleration * (deltaT * deltaT * 0.5);
    self.cameraVelocity = self.cameraVelocity + self.cameraAcceleration * deltaT;
    self.cameraAcceleration = Vector3(userAcceleration.x*9.81, userAcceleration.y*9.81, userAcceleration.z*9.81);

    
    // construct camera matrix
    // P = K[R|t] with t = -RC
    float *r = camOrientation.rotationMatrix3x3();    
    float KR[] = 
    {
        CAMERA_F*r[ROT11] + CAMERA_PX*r[ROT31], CAMERA_F*r[ROT12] + CAMERA_PX*r[ROT32], CAMERA_F*r[ROT13] + CAMERA_PX*r[ROT33],
        CAMERA_F*r[ROT21] + CAMERA_PY*r[ROT31], CAMERA_F*r[ROT22] + CAMERA_PY*r[ROT32], CAMERA_F*r[ROT23] + CAMERA_PY*r[ROT33],
        r[ROT31], r[ROT32], r[ROT33]
    };
    delete[] r;
    
    Vector3 t = Vector3(- (KR[ROT11]*self.cameraPosition.x + KR[ROT12]*self.cameraPosition.y + KR[ROT13]*self.cameraPosition.z),
                        - (KR[ROT21]*self.cameraPosition.x + KR[ROT22]*self.cameraPosition.y + KR[ROT23]*self.cameraPosition.z),
                        - (KR[ROT31]*self.cameraPosition.x + KR[ROT32]*self.cameraPosition.y + KR[ROT33]*self.cameraPosition.z));
    
    float P[] = 
    {
        KR[ROT11], KR[ROT12], KR[ROT13], t.x,
        KR[ROT21], KR[ROT22], KR[ROT23], t.y,
        KR[ROT31], KR[ROT32], KR[ROT33], t.z
    };
    
    // project the target
    float homox = P[CAM11]*self.target.x + P[CAM12]*self.target.y + P[CAM13]*self.target.z + P[CAM14];
	float homoy = P[CAM21]*self.target.x + P[CAM22]*self.target.y + P[CAM23]*self.target.z + P[CAM24];
	float homoz = P[CAM31]*self.target.x + P[CAM32]*self.target.y + P[CAM33]*self.target.z + P[CAM34];
    
    float x = homox/homoz;
	float y = CAMERA_IMHEIGHT - homoy/homoz; 
    
    // update target marker
    self.targetMarkerView.targetPoint = CGPointMake(x,y);
        
    // update feedback
    distance = [self.targetMarkerView distanceToGoal];
    if ([self.audioFeedback caresAboutRadialOrientation])
    {
        radians = [self.targetMarkerView targetOrientation];
        [self.audioFeedback updateFeedbackWithDistance:&distance andOrientation:&radians];   
    }
    else
    {
        [self.audioFeedback updateFeedbackWithDistance:&distance andOrientation:NULL]; 
    }
    
    float timeStamp = deviceMotion.timestamp;
    // update pinhole log
    NSString *str = [NSString stringWithFormat:@"%07d %f %f %f %f %f %f %f %f %f %f %f %f %f %f %f\n",
                     self.frameCount, ticTime, timeStamp, 
                     self.cameraPosition.x, self.cameraPosition.y, self.cameraPosition.z,
                     camOrientation.elem[0], camOrientation.elem[1], camOrientation.elem[2], camOrientation.elem[3],
                     self.cameraVelocity.x, self.cameraVelocity.y, self.cameraVelocity.z,
                     self.cameraAcceleration.x, self.cameraAcceleration.y, self.cameraAcceleration.z];
    if (![self.pinholeLog appendString:str])
    {
        DebugLog(@"ERROR: Could not record pinhole camera status in log!");
    }
    
    // update target log
    str = [NSString stringWithFormat:@"%07d %f %f %f %f %f\n",
           self.frameCount, timeStamp, x, y, distance, radians];
    if (![self.targetLog appendString:str])
    {
        DebugLog(@"ERROR: Could not record target status in log!");
    }
    
    self.frameCount = self.frameCount + 1;
    
    if ([self.targetMarkerView targetReachedGoal])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self declareSuccessfulRun];
            self.startInfoLabel.text = @"The target is centered!";
            self.startInfoLabel.hidden = NO;
        });
    }
    
    if ([self.targetMarkerView targetOutsideBounds])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self declareSuccessfulRun];
            self.startInfoLabel.text = @"Lost target.";
            self.startInfoLabel.hidden = NO;
        });        
    }
}

@end



#pragma mark Public

@implementation PinholeCameraTargetEstimator
@synthesize motionManager;
@synthesize motionQueue;
@synthesize referenceAttitude;
@synthesize minBounds;
@synthesize maxBounds;
@synthesize cameraPosition;
@synthesize cameraVelocity;
@synthesize cameraAcceleration;
@synthesize deviceMotionLog;
@synthesize pinholeLog;
@synthesize frameCount;

/**
    Initialize random target with visible projection on a pinhole camera model
    x is bounded between 0 and CAMERA_IMWIDTH
    y is bounded between 0 and CAMERA_IMWIDTH
    z is bounded between POINT_MINDEPTH and POINT_MAXDEPTH
 */
-(id) init
{
    if (self = [super init])
    {
        self.minBounds = Vector3(40.f,40.f,(float)POINT_MINDEPTH);
        self.maxBounds = Vector3((float)CAMERA_IMWIDTH-40,(float)CAMERA_IMHEIGHT-40,(float)POINT_MAXDEPTH);
    }
    return self;
}

/**
    Initialize random target generator with specific minimum and maximum bounds
    @param minB minimum bounds
    @param maxB maximum bounds  
    @note The standard init method is recommended for the predefined camera model 
    There is no checking of parameters to be compatible with the camera model!
 */
-(id)initWithMinBounds:(Vector3*)minB maxBounds:(Vector3*)maxB
{
    if (self = [super init])
    {
        self.minBounds = *minB;
        self.maxBounds = *maxB;
    }
    return self;
}

/**
    Generate new target inside min/max bounds (and save it in <a>motionEstimator</a>)
 */
-(void) newTarget
{
    assert(self.minBounds.z <= self.maxBounds.z && self.minBounds.z > 0);
    
    // select target depth
    float z = randomNumber(self.minBounds.z, self.maxBounds.z);
    
    // select target's projection on the image space
    float projx = randomNumber(self.minBounds.x, self.maxBounds.x);
    float projy = randomNumber(self.minBounds.y, self.maxBounds.y);
    
    // find the 3d position of the target in space
    // solve for x,y given z, such that the following correspondence holds:
    // (x,y,z)^T -> (CAMERA_F * x / z + CAMERA_PX, CAMERA_F * y / z + CAMERA_PY)^T
    //
    // see Multiple View Geometry, pag 155
    float x = (projx - CAMERA_PX)*z/(float)CAMERA_F;
    float y = (projy - CAMERA_PY)*z/(float)CAMERA_F;
    
    //self.target = Vector3(-x,y,-z); // flip target to the frame of reference of the device (assuming camera is in [0,0,0])
    self.target = Vector3(x,-y,-z); // flip target to the frame of reference of the device (assuming camera is in [0,0,0])
    // @todo not working for vertical orientation
    
    // save target information
    NSString *str = [NSString stringWithFormat:@"# init_state %f %f %f %f %f %f %f %f %f\n",
                     projx, projy, self.target.x, self.target.y, self.target.z,
                     self.targetMarkerView.targetGoal.x, self.targetMarkerView.targetGoal.y,
                     self.targetMarkerView.frame.size.width, self.targetMarkerView.frame.size.height];
    if (![self.targetLog appendString:str])
    {
        DebugLog(@"ERROR: Could not record target in log!");
    }
}

-(void) start
{
    [super start];  
    self.targetMarkerView.hidden = YES;
}

/**
    Do what is necessary to start estimating motion
 */
-(void) startEstimatingMotion
{    
    if (self.done == YES || self.processingTime != 0) return;
    
    self.frameCount = 0;
    self.startInfoLabel.hidden = YES;
    
    // clean extrinsic camera parameters
    // note: we assume that the camera is at the origin of the world coord frame
    // looking at the +z axis, and that it's not moving
    self.cameraPosition = Vector3();
    self.cameraVelocity = Vector3();
    self.cameraAcceleration = Vector3();
    
    // clear reference attitude
    self.referenceAttitude = nil;
    
    // init motion manager
    if (self.motionManager == nil)
    {
        self.motionManager = [[CMMotionManager alloc] init];
        
        if (!self.motionManager.isDeviceMotionAvailable)
        { /* should not continue without sensors */
            [NSException raise:NSInternalInconsistencyException 
                        format:@"DeviceMotion is not available"];
        }   
        self.motionManager.deviceMotionUpdateInterval = DEVICEMOTION_UPDATE_INTERVAL;
    }
    
    // init motion queue for "pushed" data
    if (self.motionQueue == nil)
    {
        self.motionQueue = [[NSOperationQueue alloc] init];
    }
    
    // start data collection
    [self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryZVertical 
                                                            toQueue:self.motionQueue 
                                                        withHandler:^(CMDeviceMotion *deviceMotion, NSError *error)
     {
         [self updateTargetPosition:deviceMotion error:error];
     }];
    
    [self.targetMarkerView startAnimation:CGPointMake(-1.0f,-1.0f)]; // start with point outside view so that it won't render right away
    
    self.targetMarkerView.alpha = 1.0;
    self.targetMarkerView.hidden = NO;
    
    [self newTarget];
    
    if (self.audioFeedbackType == AUDIOFEEDBACK_SILENT) {
        [self.startAudioClip play];
    }
    
    self.processingTime = tic();
}

/**
    Do what is necessary to stop estimating motion
 */
-(void) stopEstimatingMotion
{
    if (self.motionManager != nil)
    {
        if ([self.motionManager isDeviceMotionActive])
            [self.motionManager stopDeviceMotionUpdates];
        
        self.motionManager = nil;
    }
    
    if (self.motionQueue != nil)
    {
        self.motionQueue = nil;
    }
    
    [self.audioFeedback stop];
    [self.targetMarkerView stopAnimation];
}

/**
    Declare successful run after the target reached the goal
 */
-(void) declareSuccessfulRun
{
    self.targetMarkerView.alpha = 0.3;
    
    // set done = YES, play success audio clip, stop all
    [super declareSuccessfulRun];
    
    NSConditionLock* lock = [[NSConditionLock alloc] initWithCondition:0];
    [lock lock];
    [lock unlockWithCondition:![self.motionManager isDeviceMotionActive] && 
                              self.deviceMotionLog == nil &&
                              self.targetLog == nil];
    
    [self dismissModalViewControllerAnimated:YES];
}

/**
    Is motion being estimated?
 */
-(BOOL) isEstimatingMotion
{
    return self.motionManager != nil && [self.motionManager isDeviceMotionActive];
}

/**
    Start logging common data accross all target estimators
    @return are we logging?
 */
-(BOOL) startLogging
{
    BOOL ok = [super startLogging];
        
    NSString *deviceMotionStr = [NSString stringWithFormat:@"%@_deviceMotion", 
                                 self.logIdentifier];
    NSString *pinholeStr = [NSString stringWithFormat:@"%@_pinhole",
                            self.logIdentifier];
    
    // create log handlers
    self.deviceMotionLog = [[DLDeviceMotionLog alloc] initWithName:deviceMotionStr];
    self.pinholeLog = [[DLTextLog alloc] initWithName:pinholeStr];
    
    // \todo add more logs here
    
    ok = ok && self.deviceMotionLog != nil && self.pinholeLog != nil;
    if (!ok)
    {
        DebugLog(@"ERROR: Failed setting up PinholeCameraTargetEstimator's logs.");
    }
    
    return ok;
}

/**
    Stop logging common data accross all target estimators
 */
-(void) stopLogging
{
    [super stopLogging];
    
    // setting the logs to nil closes the files...
    self.deviceMotionLog = nil;
    self.pinholeLog = nil;
}


/**
     String description of target estimator
     @return string description
 */
-(NSString *)targetEstimatorDescription
{
    NSString *str = [[NSString alloc] initWithFormat:@"%@ %d %d %f %f %f %f %f", [super targetEstimatorDescription],
                     CAMERA_IMWIDTH, CAMERA_IMHEIGHT, CAMERA_F,
                     CAMERA_PX, CAMERA_PY, 
                     (float)POINT_MINDEPTH, (float) POINT_MAXDEPTH];
    return str;
}

@end







