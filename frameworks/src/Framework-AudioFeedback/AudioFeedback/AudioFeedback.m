//
//  AudioFeedback.m
//  Framework-AudioFeedback
//
//    Created by Marynel Vazquez on 9/21/11.
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

#import "AudioFeedback.h"
#import "AudioFeedbackCommon.h"

@implementation AudioFeedback
@synthesize alContext;
@synthesize alDevice;
@synthesize bufferArray;
@synthesize sourceArray;
@synthesize queue;

/**
 Initialize audio feedback
 */
-(id) init
{
    if (self = [super init])
    {
        self.alDevice = NULL;
        self.alContext = NULL;
        self.bufferArray = [[NSMutableArray alloc] init];
        self.sourceArray = [[NSMutableArray alloc] init];
        self.queue = dispatch_queue_create("edu.cmu.ri.apt.audiballmix.audio", NULL);
        
        if (![self setUpOpenAL])
        {
            AudioFeedbackDebugLog(@"WARNING: Could not set up OpenAL.");
        }
    }
    
    return self;
}

/**
 Be good with the environment
 */
-(void) dealloc
{
//    dispatch_release(self.queue);
    [self cleanUpOpenAL];
}

/**
 Set up OpenAL
 @return <a>TRUE</a> if device and context are already set or if no error ocurred while setting them up
 */
-(BOOL) setUpOpenAL
{
    if (self.alDevice != NULL && self.alContext != NULL)
    {
        AudioFeedbackDebugLog(@"No need to reset OpenAL (clean up first if you really want to delete the device and the context!)");
        return YES;        
    } 
    else if (self.alDevice != NULL && self.alContext != NULL)
    {
        AudioFeedbackDebugLog(@"Device or context already exist. Clean up before setting them up again.");
        return NO;
    }
    
    // select the "preferred" device
    self.alDevice = alcOpenDevice(NULL);
    
    // create the context and set it up as current context
    if (self.alDevice)
    {   
        self.alContext = alcCreateContext(self.alDevice, NULL);
        if (alcMakeContextCurrent(self.alContext))
        {
            return YES;
        }
        
        // couldn't make our context the current context
        AudioFeedbackDebugLog(@"Could not set up current context in OpenAL");
        alcDestroyContext(self.alContext); self.alContext = NULL;
        alcCloseDevice(self.alDevice); self.alDevice = NULL;
        return NO;
    }
    
    // couldn't set up OpenAL device :(
    AudioFeedbackDebugLog(@"Could not set up OpenAL device!");
    return NO;
}

/**
 Clean up <a>bufferArray</a> and <a>sourceArray</a> in OpenAL and empty the arrays
 */
-(void) cleanUpSourcesAndBuffers
{
    if (self.sourceArray == nil || self.bufferArray == nil ||
        ([self.sourceArray count] == 0 || [self.bufferArray count] == 0))
        return;
    
    ALenum lastErrorCode;
    NSUInteger tmpUInt;
    
    // clean up sources
    for (NSNumber *source in self.sourceArray)
    {
        tmpUInt = [source unsignedIntValue];
        // detach from buffers
        alSourcei(tmpUInt, AL_BUFFER, 0);
        // delete source
        alDeleteSources(1, &(tmpUInt));
        if ((lastErrorCode = alGetError()) != AL_NO_ERROR)
        {
            AudioFeedbackDebugLog(@"An error (code = %d) ocurred while deleting buffer (%d)", lastErrorCode, tmpUInt);
        }
    }
    
    // clean up buffers
    for (NSNumber *buff in self.bufferArray)
    {
        tmpUInt = [buff unsignedIntValue];
        // delete buffer
        alDeleteBuffers(1, &(tmpUInt));
        if ((lastErrorCode = alGetError()) != AL_NO_ERROR)
        {
            AudioFeedbackDebugLog(@"An error (code = %d) ocurred while deleting buffer (%d)", lastErrorCode, tmpUInt);
        }
    }
    
    [self.sourceArray removeAllObjects];
    [self.bufferArray removeAllObjects];
}

/**
 Clean up everything in OpenAL (i.e. device, context, sources and buffers)
 */
-(void) cleanUpOpenAL
{    
    // clean up sources and buffers
    [self cleanUpSourcesAndBuffers];
    
    // release current context
    alcMakeContextCurrent(NULL);
    
    // destroy context
    if (self.alContext != NULL)
    {
        alcDestroyContext(self.alContext);
        self.alContext = NULL;
    }
    
    // close device
    if (self.alDevice != NULL)
    {
        alcCloseDevice(self.alDevice);
        self.alDevice = NULL;
    }
}

/** 
 Construct AudioFileID for an audio file
 @param filePath path to file
 @return big audio ID struct
 */
-(AudioFileID)audioFileID:(NSString*)filePath
{
	AudioFileID outAFID;
	// use the NSURl instead of a cfurlref cuz it is easier
	NSURL * afUrl = [NSURL fileURLWithPath:filePath];
	OSStatus result = AudioFileOpenURL((CFURLRef)objc_unretainedPointer(afUrl), kAudioFileReadPermission, 0, &outAFID);
	if (result != 0) AudioFeedbackDebugLog(@"Could not open file: %@",filePath);
	
	return outAFID;
}

/**
 Find the audio portion of the file
 @param fileID audio file id 
 @return size in bytes
 */
+(UInt32)audioFileSize:(AudioFileID)fileID
{
	UInt64 outDataSize = 0;
	UInt32 thePropSize = sizeof(UInt64);
	OSStatus result = AudioFileGetProperty(fileID, kAudioFilePropertyAudioDataByteCount, &thePropSize, &outDataSize);
	if(result != 0) AudioFeedbackDebugLog(@"Could not get file size.");
	return (UInt32)outDataSize;
}

/**
 Set up context id and source id for an audio file
 @param fileName audio file name
 @param looping set looping property to <a>TRUE</a>?
 @return <a>TRUE</a> if the audio file was set up properly for OpenAL
 @note Assumes the file type is caf
 */
-(BOOL)setUpOpenALSound:(NSString*)fileName looping:(BOOL)looping
{
	// get the full path of the file
	NSString* file = [[NSBundle mainBundle] pathForResource:fileName ofType:@"caf"];
    
	// get the file and its size
	AudioFileID fileID = [self audioFileID:file];
	UInt32 fileSize = [AudioFeedback audioFileSize:fileID];
	
	// temporary allocation for audio data
	unsigned char *data = (unsigned char *)malloc(fileSize);
	
	// move data into a buffer
	OSStatus status = noErr;
	status = AudioFileReadBytes(fileID, false, 0, &fileSize, data);
    // and close the file
	AudioFileClose(fileID); 
	
	if (status != 0) 
    { 
        NSLog(@"Could not load audio file: %@",file); 
        free(data);
        return FALSE; 
    }
	
	NSUInteger bufferID;
	// get buffer ID from openAL
	alGenBuffers(1, &bufferID);
	// and place the data into the buffer
	alBufferData(bufferID,AL_FORMAT_MONO16,data,fileSize,44100); 
	
	// save the buffer ID so we can use it later
	[self.bufferArray addObject:[NSNumber numberWithUnsignedInteger:bufferID]];
    
	NSUInteger sourceID;
	// get source ID from openAL
	alGenSources(1, &sourceID); 
	
	// attach the buffer to the source
	alSourcei(sourceID, AL_BUFFER, bufferID);
	// set basic source preferences
	alSourcef(sourceID, AL_GAIN, 1.0f);
	alSourcef(sourceID, AL_PITCH, 1.0f);
    if (looping)
        alSourcei(sourceID, AL_LOOPING, AL_TRUE);
	
	// store this for future use
	[self.sourceArray addObject:[NSNumber numberWithUnsignedInteger:sourceID]];
	
	// clean up temporary allocation
	free(data);
	
	return TRUE;
}

/**
 Start providing audio feedback
 @param distance distance from target to goal
 @param radians target orientation with respect to goal (0 means to the right)
 @return <a>TRUE</a> if audio feedback started successfully
 */
-(BOOL) startWithDistance:(float*)distance andOrientation:(float*)radians;
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];   
}

/**
 Stop providing audio feedback
 @return <a>TRUE</a> if everything went ok
 */
-(BOOL) stop
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

/**
 Update audio feedback
 @param distance distance from target to goal
 @param radians target orientation with respect to goal (0 means to the right)
 @return <a>TRUE</a> if audio feedback was updated successfully
 */
-(BOOL) updateFeedbackWithDistance:(float*)distance andOrientation:(float*)radians
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];       
}

/**
 Does the audio feedback class care about radial orientation?
 @return <a>YES</a> if the class (or subclass) cares
 @note This function can be used to save computation (not all classes care about radial orientation!)
 */
-(BOOL) caresAboutRadialOrientation
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];     
}

/** 
 Is OpenAL playing sound(s)?
 @return <a>TRUE</a> if playing sounds
 */
-(BOOL) playingSound
{
    if (!self.sourceArray || [self.sourceArray count] == 0)
        return FALSE;
    
    ALenum state, lastErrorCode;
    NSUInteger sourceID;
    
    // check for a playing source
    for (NSNumber *source in self.sourceArray)
    {
        sourceID = [source unsignedIntValue];
        // is playing?
        alGetSourcei(sourceID, AL_SOURCE_STATE, &state);
        if ((lastErrorCode = alGetError()) != AL_NO_ERROR)
        {
            AudioFeedbackDebugLog(@"An error (code = %d) ocurred while trying to figure out if source %d is playing", lastErrorCode, sourceID);
            return FALSE;
        }
        if (state == AL_PLAYING) return TRUE;
    }
    return FALSE;
}

/**
 Is audio feedback set up and ready to play?
 @return <a>TRUE</a> if openAL seems to be OK and ready
 */
-(BOOL) isSetUp
{
    return (self.alDevice != NULL && self.alContext != NULL &&
            self.sourceArray && [self.sourceArray count] > 0 &&
            self.bufferArray && [self.bufferArray count] == [self.sourceArray count]);
    
}

@end
