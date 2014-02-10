//
//  DLLog.m
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

#import "DLLog.h"

@implementation DLLog


/**
    Get full path for a file
    @param fileName file name in the apps' document directory
    @return full file path
 */
+(NSString *) fullFilePath:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *directory = [paths objectAtIndex:0];
	NSArray *sections = [NSArray arrayWithObjects:directory,@"/",fileName,nil];
	NSString *fullPath = [NSString pathWithComponents:sections];
	return fullPath;
}

/**
    Open log file in the app's document directory
    @param fullPath log file path
    @param fileHandle file handle
    @return was the file opened successfully?
 
    Creates new file handle for file and retruns it through <a>fileHandle</a>.
 */
+(BOOL) openFilePath:(NSString*)fullPath withFileHandle:(NSFileHandle **)fileHandle
{
    
    // set up file manager
    if ([DLLog logFileExists:fullPath])
    {
        DebugLog(@"Log file (%@) could not be created because another file exists with the same name!", fullPath);
        return NO;
	}
    
	// create empty file
	NSData *data = [NSData data];
	[data writeToFile:fullPath atomically:YES];
    
    // set up file handle
    *fileHandle = [NSFileHandle fileHandleForUpdatingAtPath:fullPath];
    if (*fileHandle == nil)
    {
        DebugLog(@"File handle for log (%@) could not be set up.", fullPath);
        return NO;
    }
    [*fileHandle seekToEndOfFile];
    
    return YES;
}

/**
    Utility function to check if a log file already exists
    @param pathToLogFile log file path
    @return does the file already exist?
 */
+(BOOL) logFileExists:(NSString *)pathToLogFile
{
    // set up file manager
    NSFileManager *defaultManager = [NSFileManager defaultManager];
	return [defaultManager fileExistsAtPath:pathToLogFile];
}

/**
    Append string to file
    @param str data to append
    @param encoding data encoding
    @param fileHandle file handle
    @return was the operation successful?
 */
+(BOOL) appendString:(NSString *)str encoding:(NSStringEncoding)encoding fileHandle:(NSFileHandle *)fileHandle
{
    if (fileHandle == nil) 
    {
        DebugLog(@"Invalid file handle to write to log.");
        return NO;
    }
    
    @try {
        @autoreleasepool {
            NSData *data = [str dataUsingEncoding:encoding];
            [fileHandle writeData:data];
        }
        return YES;
    }
    @catch (NSException *exception) {
        DebugLog(@"Could not append string to log file. An error ocurred while trying to write data.");
        return NO;
    }
}

@end
