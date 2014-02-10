//
//  RandomTargetGenerator.h
//  AudiballMix
//
//    Created by Marynel Vazquez on 9/14/11.
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
#import "TargetEstimator.h"
#import <DataLogging/DLDeviceMotionLog.h>
#import <BasicMath/Quaternion.h>

/**
    Pinhole camera target generator (with intertial tracking)
    Targets are generated as random 3D points projected into a pinhole camera image.
    The motion estimation process ends when the user centers the target in the screen.
    @note All camera parameters are static (changing them would require re-definitions)
 */
@interface PinholeCameraTargetEstimator : TargetEstimator

@property (nonatomic, retain) CMMotionManager *motionManager;       //!< motion manager
@property (nonatomic, retain) NSOperationQueue *motionQueue;        //!< motion queue for "pushing" data
@property (retain) CMAttitude *referenceAttitude;                   //!< motion device reference attitude
@property (nonatomic, assign) Vector3 minBounds;                    //!< minimum bounds for the target
@property (nonatomic, assign) Vector3 maxBounds;                    //!< maximum bounds for the target
@property (nonatomic, assign) Vector3 cameraPosition;               //!< camera center in world coordinates
@property (nonatomic, assign) Vector3 cameraVelocity;               //!< camera velocity in world coordinates
@property (nonatomic, assign) Vector3 cameraAcceleration;           //!< camera acceleration
@property (nonatomic, retain) DLDeviceMotionLog *deviceMotionLog;   //!< DeviceMotion log
@property (nonatomic, retain) DLTextLog *pinholeLog;                //!< Pinhole camera log
@property (atomic, assign) unsigned int frameCount;                 //!< Frame count

-(id) init;
-(id) initWithMinBounds:(Vector3*)minB maxBounds:(Vector3*)maxB;

-(void) newTarget;
-(void) start;
-(void) startEstimatingMotion;
-(void) stopEstimatingMotion;
-(void) declareSuccessfulRun;
-(BOOL) isEstimatingMotion;

-(BOOL) startLogging;
-(void) stopLogging;

-(NSString *)targetEstimatorDescription;

@end
