//
//  DLInertialLog.m
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

#import "DLInertialLog.h"

#define ACCEL_SMOOTHING_FACTOR1 0.15
#define ACCEL_SMOOTHING_FACTOR2 0.85

@implementation DLInertialLog
@synthesize accelFilePath;
@synthesize accelFileHandle;
@synthesize accelQueue;
@synthesize gyroFilePath;
@synthesize gyroFileHandle;
@synthesize gyroQueue;
@synthesize sharedMotionManager;
@synthesize latestAccel;
//@synthesize latestSmoothedAccel;
@synthesize latestGyro;

/**
    Init with file names and motion manager
    @param aName accelerometer log file name (without extension, '.txt' would be appended by default)
    @param gName gyroscope log file name (without extension, '.txt' would be appended by default)
    @param motionManager motion manager
    @return InertialLog 
 
    Starts accelerometer and gyroscope readings.
 */
-(id) initWithAccelFile:(NSString *)aName GyroFile:(NSString *)gName motionManager:(CMMotionManager*)motionManager
{
    if (self = [super init])
    {
        self.sharedMotionManager = motionManager;
        if (![self.sharedMotionManager isAccelerometerAvailable] || ![self.sharedMotionManager isGyroAvailable])
        {
            DebugLog(@"Accelerometer or Gyro are not available for logging device motion.");
            self = nil;
        }
        else
        {
            NSString *aFullName = [NSString stringWithFormat:@"%@.txt",aName];
            self.accelFilePath = [DLLog fullFilePath:aFullName];
            NSFileHandle *aHandle;
            
            NSString *gFullName = [NSString stringWithFormat:@"%@.txt",gName];
            self.gyroFilePath = [DLLog fullFilePath:gFullName];
            NSFileHandle *gHandle;
            
            if (![DLLog openFilePath:self.accelFilePath withFileHandle:&aHandle] ||
                ![DLLog openFilePath:self.gyroFilePath withFileHandle:&gHandle])
            {
                self = nil;
            }
            else
            {
                self.accelFileHandle = aHandle;
                self.gyroFileHandle = gHandle;
                
                self.sharedMotionManager.accelerometerUpdateInterval = INERTIALLOG_ACCEL_UPDATEINTERVAL;
                self.sharedMotionManager.gyroUpdateInterval = INERTIALLOG_GYRO_UPDATEINTERVAL;
                
                self.accelQueue = [[NSOperationQueue alloc] init];
                self.gyroQueue = [[NSOperationQueue alloc] init];
                
                latestSmoothedAccel = Vector3(0,0,0);
                
                [self.sharedMotionManager startAccelerometerUpdatesToQueue:self.accelQueue 
                                                               withHandler:^(CMAccelerometerData *data, NSError *err)
                 {
                     [self appendAccelData:data error:err]; 
                 }];
                
                [self.sharedMotionManager startGyroUpdatesToQueue:self.gyroQueue withHandler:^(CMGyroData *data, NSError *err)
                 {
                     [self appendGyroData:data error:err];
                 }];
            }
            
        }
    }
    return self;
}

/**
    Close handlers and stop accel/gyro updates
 */
-(void) dealloc
{
    [self close];
}

/**
    Close file handles and stop motion updates
 */
-(void) close
{
    if ([self.sharedMotionManager isAccelerometerActive])
        [self.sharedMotionManager stopAccelerometerUpdates];
    
    if ([self.sharedMotionManager isGyroAvailable])
        [self.sharedMotionManager stopGyroUpdates];
    
    if (self.accelFileHandle) [self.accelFileHandle closeFile];
    if (self.gyroFileHandle) [self.gyroFileHandle closeFile];
}

/**
    Are we logging?
    @return <a>TRUE</a> if device motion is being logged
 */
-(BOOL) isLogging
{
    return (self.accelFileHandle && [self.sharedMotionManager isAccelerometerActive] &&
            self.gyroFileHandle && [self.sharedMotionManager isGyroAvailable]);
}

/**
    Append accelerometer data to accelerometer log
    @param accelData accelerometer data
    @param error motion manager error
    @return was the data appended successfully?
 */
-(BOOL) appendAccelData:(CMAccelerometerData *)accelData error:(NSError*)error
{
    if (error)
    {
        DebugLog(@"Could not save acceleration data to log file! Got error: %@", error);
        DebugLog(@"%@", [error localizedDescription]);
        DebugLog(@"%@", [error localizedFailureReason]); 
        DebugLog(@"%@", [error localizedRecoverySuggestion]); 
        DebugLog(@"%@", [error localizedRecoveryOptions]);
        return NO;
    }
    
    CMAcceleration accel = accelData.acceleration; 
    
    self.latestAccel = accel;
    float smoothx = latestSmoothedAccel.x*ACCEL_SMOOTHING_FACTOR2 +
                        self.latestAccel.x*ACCEL_SMOOTHING_FACTOR1;
    float smoothy = latestSmoothedAccel.y*ACCEL_SMOOTHING_FACTOR2 +
                        self.latestAccel.y*ACCEL_SMOOTHING_FACTOR1;
    float smoothz = latestSmoothedAccel.z*ACCEL_SMOOTHING_FACTOR2 +
                        self.latestAccel.z*ACCEL_SMOOTHING_FACTOR1;
    latestSmoothedAccel = Vector3(smoothx, smoothy, smoothz);
    
    NSTimeInterval timestamp = accelData.timestamp;
    NSString *str = [NSString stringWithFormat:@"%f %f %f %f %f %f %f\n", timestamp, accel.x, accel.y, accel.z,
                     smoothx, smoothy, smoothz];
    return [DLLog appendString:str encoding:NSUTF8StringEncoding fileHandle:self.accelFileHandle];
}

/**
    Append gyro data to accelerometer log
    @param gyroData accelerometer data
    @param error motion manager error
    @return was the data appended successfully?
 */
-(BOOL) appendGyroData:(CMGyroData *)gyroData error:(NSError*)error
{
    if (error)
    {
        DebugLog(@"Could not save gyroscope data to log file! Got error: %@", error);
        DebugLog(@"%@", [error localizedDescription]);
        DebugLog(@"%@", [error localizedFailureReason]); 
        DebugLog(@"%@", [error localizedRecoverySuggestion]); 
        DebugLog(@"%@", [error localizedRecoveryOptions]);
        return NO;
    }
    
    CMRotationRate gyro = gyroData.rotationRate; self.latestGyro = gyro;
    NSTimeInterval timestamp = gyroData.timestamp;
    NSString *str = [NSString stringWithFormat:@"%f %f %f %f\n", timestamp, gyro.x, gyro.y, gyro.z];
    return [DLLog appendString:str encoding:NSUTF8StringEncoding fileHandle:self.gyroFileHandle];
}

-(OCVector3 *)getLatestSmoothedAcceleration
{
    OCVector3 *v = [[OCVector3 alloc] initWithX:latestSmoothedAccel.x Y:latestSmoothedAccel.y Z:latestSmoothedAccel.z];
    return v;
}

@end
