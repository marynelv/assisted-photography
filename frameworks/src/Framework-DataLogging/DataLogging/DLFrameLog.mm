//
//  DLFrameLog.m
//  Framework-DataLogging
//
//    Created by Marynel Vazquez on 01/20/2012.
//    Copyright 2012 Carnegie Mellon University.
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

#import "DLFrameLog.h"
#import "DLTiming.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreVideo/CoreVideo.h>
#import <ImageIO/CGImageDestination.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import <ImageIO/CGImageProperties.h>
#import <CoreFoundation/CFDictionary.h>

@implementation DLFrameLog
@synthesize fileName;
@synthesize frameCount;


-(id) initWithName:(NSString*)name;
{
    if (self = [super initWithName:name])
    {
        self.fileName = name;
        self.frameCount = -1;
        frameQueue = dispatch_queue_create("edu.cmu.ri.apt.DataLogging.FrameQueue", NULL);
        
        if (!isMachTimeValid()) initMachTime();
    }
    return self;
}


/**
 Write frame timestamp to log
 @param time time stamp (usually comming from a CMSampleBufferRef through AVFoundation)
 @return was the timestamp saved successfully?
 */
-(BOOL) appendFrameTimeStamp:(float)timeStamp presentationTime:(CMTime)presentationTime
{
    NSString *str = [[NSString alloc] initWithFormat:@"%07d %f %f\n", self.frameCount, 
                     timeStamp, CMTimeGetSeconds(presentationTime)];
    return [self appendString:str];
}

-(BOOL) skipFrameWithPresentationTime:(CMTime)presentationTime
{    
//    double timeStamp = tic();
    self.frameCount = self.frameCount + 1;
//    @autoreleasepool {
//        NSString *str = [[NSString alloc] initWithFormat:@"# %05d %f %f\n", self.frameCount, 
//                         timeStamp, CMTimeGetSeconds(presentationTime)];
//        [self appendString:str];
//    }
    
    return YES;
}

/**
    Save frame to app bundle (but don't increase frame count or log anything into text file)
    @param frameSampleBuffer image data
    @param presentationTime presentation time
    @param specialIdentifier special identifier to append to image name
    @return <a>TRUE</a> if we at least tried to save the frame
    @note The sample buffer is not checked against NULL. Caller is responsible for that. 
 */
-(BOOL) saveFrame:(CMSampleBufferRef)frameSampleBuffer appendStrToName:(NSString*)specialIdentifier
{
    BOOL ok = YES;
    
    @autoreleasepool {
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
        
        NSString *imageName;
        if (specialIdentifier != nil)
        {
            imageName = [NSString stringWithFormat:@"%@_frame%05d%@.jpeg", self.fileName, self.frameCount, specialIdentifier];
        }
        else
        {
            imageName = [NSString stringWithFormat:@"%@_frame%05d.jpeg", self.fileName, self.frameCount];
        }
        NSString *framePath = [DLLog fullFilePath:imageName];

        CFURLRef frameURLRef = (__bridge CFURLRef)[NSURL fileURLWithPath:framePath];
        CFWriteStreamRef picLogStream = CFWriteStreamCreateWithFile(kCFAllocatorDefault,frameURLRef);
        CGImageDestinationRef destination = CGImageDestinationCreateWithURL(frameURLRef, kUTTypeJPEG, 1, NULL);
        CFMutableDictionaryRef saveMetaAndOpts = CFDictionaryCreateMutable(nil, 0, 
                                                                           &kCFTypeDictionaryKeyCallBacks,  
                                                                           &kCFTypeDictionaryValueCallBacks);
        NSNumber *qualityLevel = [NSNumber numberWithFloat:0.6];
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
    }
    
    return ok;
}

/**
     Save frame to app bundle
     @param frameSampleBuffer image data
     @param presentationTime presentation time
     @param specialIdentifier special identifier to append to image name
     @return <a>TRUE</a> if we at least tried to save the frame
     @note The sample buffer is not checked against NULL. Caller is responsible for that.
     @note It is hard to tell if the image was saved properly because the saving function is delegated to a custom thread. 
 */
-(BOOL) saveFrame:(CMSampleBufferRef)frameSampleBuffer presentationTime:(CMTime)presentationTime 
        appendStrToName:(NSString*)specialIdentifier
{
    double timeStamp = tic();
    
//    if (!frameQueue) {
//        DebugLog(@"Error: Frame queue could not be found.");
//        return NO;
//    }
    
    self.frameCount = self.frameCount + 1;
    [self appendFrameTimeStamp:timeStamp presentationTime:presentationTime];
    return [self saveFrame:frameSampleBuffer appendStrToName:specialIdentifier];
    
//    @autoreleasepool {
//        
//        self.frameCount = self.frameCount + 1;
//        
//        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(frameSampleBuffer);
//        
//        CVPixelBufferLockBaseAddress(imageBuffer,0);
//        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//        size_t width = CVPixelBufferGetWidth(imageBuffer);
//        size_t height = CVPixelBufferGetHeight(imageBuffer);
//        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
//        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); 
//        CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst); 
//        CGImageRef imageRef = CGBitmapContextCreateImage(context); 
//        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//        CGContextRelease(context); 
//        CGColorSpaceRelease(colorSpace);
//        
//        NSString *imageName;
//        if (specialIdentifier != nil)
//        {
//            imageName = [NSString stringWithFormat:@"%@_frame%05d%@.jpeg", self.fileName, self.frameCount, specialIdentifier];
//        }
//        else
//        {
//            imageName = [NSString stringWithFormat:@"%@_frame%05d.jpeg", self.fileName, self.frameCount];
//        }
//        NSString *framePath = [DLLog fullFilePath:imageName];
//        
////        dispatch_async(frameQueue, ^{    
////            
////            @autoreleasepool {
//                CFURLRef frameURLRef = (__bridge CFURLRef)[NSURL fileURLWithPath:framePath];
//                CFWriteStreamRef picLogStream = CFWriteStreamCreateWithFile(kCFAllocatorDefault,frameURLRef);
//                CGImageDestinationRef destination = CGImageDestinationCreateWithURL(frameURLRef, kUTTypeJPEG, 1, NULL);
//                CFMutableDictionaryRef saveMetaAndOpts = CFDictionaryCreateMutable(nil, 0, 
//                                                                                   &kCFTypeDictionaryKeyCallBacks,  
//                                                                                   &kCFTypeDictionaryValueCallBacks);
//                NSNumber *qualityLevel = [NSNumber numberWithFloat:0.7];
//                CFNumberRef compressionQuality = (__bridge CFNumberRef) qualityLevel;
//                CFDictionarySetValue(saveMetaAndOpts, 
//                                     kCGImageDestinationLossyCompressionQuality, compressionQuality);	
//                CGImageDestinationAddImage(destination, imageRef, saveMetaAndOpts); // pass nil as last argument for no extra options
//        
//                bool success = CGImageDestinationFinalize(destination);
//                if (!success) {
//                    DebugLog(@"Failed to write image to %@", framePath);
//                } 
////                else {
////                    DebugLog(@"Saved %@", framePath);
////                }
//                
//                CFRelease(destination);
//                CFWriteStreamClose(picLogStream);
//                CFRelease(picLogStream);
//                CGImageRelease(imageRef);
//                //CFRelease(compressionQuality);
//                CFRelease(saveMetaAndOpts);
////            }
////        });
//        
////        CGImageRelease(imageRef);
//        [self appendFrameTimeStamp:timeStamp presentationTime:presentationTime];
//        
//    }
//    
//    return YES;

}

/**
    Save frame to app bundle
    @param frameSampleBuffer image data
    @param presentationTime presentation time
    @return <a>TRUE</a> if we at least tried to save the frame
    @note The sample buffer is not checked against NULL. Caller is responsible for that.
    @note It is hard to tell if the image was saved properly because the saving function is delegated to a custom thread. 
 */
-(BOOL) saveFrame:(CMSampleBufferRef)frameSampleBuffer presentationTime:(CMTime)presentationTime
{
    return [self saveFrame:frameSampleBuffer presentationTime:presentationTime appendStrToName:nil];

}


@end
