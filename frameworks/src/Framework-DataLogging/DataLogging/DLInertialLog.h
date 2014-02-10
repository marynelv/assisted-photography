//
//  DLInertialLog.h
//  Framework-DataLogging
//
//    Created by Marynel Vazquez on 10/11/2011.
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

#import <CoreMotion/CoreMotion.h>
#import <BasicMath/Vector3.h>
#import <BasicMath/OCVector3.h>
#import "DLLog.h"

#define INERTIALLOG_ACCEL_UPDATEINTERVAL    1.0/50.0    //!< get linear accelerations at 50Hz
#define INERTIALLOG_GYRO_UPDATEINTERVAL     1.0/50.0    //!< get angular velocities at 50Hz

/**
    Inertial data logger
    Takes advange of a motion manager to push out inertial measurements and save them into a log file.
    Last measurement data can be retrieved from the log.
 */
@interface DLInertialLog : DLLog
{
    NSString *accelFilePath;
    NSFileHandle *accelFileHandle;
    NSOperationQueue *accelQueue;
    NSString *gyroFilePath;
    NSFileHandle *gyroFileHandle;
    NSOperationQueue *gyroQueue;
    Vector3 latestSmoothedAccel;             //!< latest smoothed acceleration (~gravity)
}

@property (nonatomic, retain) NSString *accelFilePath;              //!< accel log full path
@property (nonatomic, retain) NSFileHandle *accelFileHandle;        //!< accel log file handle
@property (nonatomic, retain) NSOperationQueue *accelQueue;         //!< accel queue
@property (nonatomic, retain) NSString *gyroFilePath;               //!< gyro log full path
@property (nonatomic, retain) NSFileHandle *gyroFileHandle;         //!< gyro log file handle
@property (nonatomic, retain) NSOperationQueue *gyroQueue;          //!< gyro queue
@property (nonatomic, retain) CMMotionManager *sharedMotionManager; //!< shared motion manager
@property (atomic, assign) CMAcceleration latestAccel;              //!< latest accel measurement
//@property (atomic, assign) Vector3 latestSmoothedAccel;             //!< latest smoothed acceleration (~gravity)
@property (atomic, assign) CMRotationRate latestGyro;               //!< latest gyro measurement

-(id) initWithAccelFile:(NSString *)aName GyroFile:(NSString *)gName motionManager:(CMMotionManager*)motionManager;
-(void) close;
-(BOOL) isLogging;
-(BOOL) appendAccelData:(CMAccelerometerData *)accelData error:(NSError*)error;
-(BOOL) appendGyroData:(CMGyroData *)gyroData error:(NSError*)error;
-(OCVector3 *)getLatestSmoothedAcceleration;

@end
