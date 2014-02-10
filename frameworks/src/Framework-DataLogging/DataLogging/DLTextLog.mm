//
//  DLTextLog.m
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

#import "DLTextLog.h"
#import "DLTiming.h"

@implementation DLTextLog
@synthesize filePath;
@synthesize fileHandle;

/** 
    Initialize TextLog with a particular file name
    @param name log file name (without extions, '.txt' is used by default)
    @return TextLog
 */
-(id) initWithName:(NSString*)name 
{
    if (self = [super init])
    {
        if (!isMachTimeValid()) initMachTime();
        
        NSString *fullName = [NSString stringWithFormat:@"%@.txt",name];
        self.filePath = [DLLog fullFilePath:fullName];
        NSFileHandle *handle;
        if (![DLLog openFilePath:self.filePath withFileHandle:&handle])
        {   self = nil; }
        else
        {   self.fileHandle = handle; 
            // save default header info

            if (![self appendString:[[NSString alloc] initWithFormat:@"# %@ %f\n", name, tic()]]){
                self = nil;
            }
        }
        
    }
    return self;
}

/**
    Close file before deallocating all memory
 */
-(void) dealloc
{
    [self close];
}

/**
    Is the text log open?
 */
-(BOOL) isLogging
{
    return self.fileHandle != nil;
}

/**
    Close log file handle
 */
-(void) close
{
    if (self.fileHandle != nil) {[self.fileHandle closeFile]; self.fileHandle = nil;}
}

/**
    Append string to file
    @param str data to append
    @return was the operation successful?
 */
-(BOOL) appendString:(NSString *)str
{
    return [DLLog appendString:str encoding:NSUTF8StringEncoding fileHandle:self.fileHandle];
}



@end
