//
//  RadialAudioFeedback.m
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

#import "RadialAudioFeedback.h"
#import "AudioFeedbackCommon.h"

#define SPACING(N)          (2*M_PI/(float)N)       //!< angular spacing between sources
#define SPACING_MULTIPLIER  0.7f                    //!< spacing multiplier for sound interpolation
#define DISTANCE_MAX        (576.9*2)               //!< max distance = sqrt(320*320+480*480) * 2 for pitch change
#define PITCH_MAX           1.3                     //!< max pitch value


#pragma mark - Private methods/functions

@interface RadialAudioFeedback (Private)
-(void) useLinearSound:(NSString*)soundFile;
-(BOOL) setUpMultipleOpenALSounds:(NSArray*)sounds looping:(BOOL)looping;
@end

@implementation RadialAudioFeedback (Private)

/**
    Initializes using single sound file 
 */
-(void) useLinearSound:(NSString*)soundFile
{
    NSArray *files = [[NSArray alloc] initWithObjects: soundFile, nil];
    [self setUpMultipleOpenALSounds:files looping:YES];
    self.numberOfDirections = [files count];
    self.spacingBetweenDirections = SPACING(self.numberOfDirections);
}

/**
    Set up multiple sounds
    @param sounds array with sound file names
    @param loop loop the sounds?
    @return <a>TRUE</a> if all sounds were set up properly
 */
-(BOOL) setUpMultipleOpenALSounds:(NSArray*)sounds looping:(BOOL)looping
{
    for (id sound in sounds)
    {
        if (![self setUpOpenALSound:sound looping:looping])
        {
            AudioFeedbackDebugLog(@"Failed setting up sound file (%@). Please check this is a caf sound file and it has been added to the application sandbox.", sound);
            return FALSE;
        }
    }
    return TRUE;
}

@end

#pragma mark - Public

@implementation RadialAudioFeedback
@synthesize numberOfDirections;
@synthesize spacingBetweenDirections;
@synthesize firstDirectionAngle;
@synthesize smoothTransition;

/**
    Initialize with default sound files (Piano)
    @return id of initialized instance
    @note <a>changePitch</a> is set to <a>TRUE</a> by default (use setter to modify)
 */
-(id) init
{
    return [self initWithPianoSound];
}


/** 
    Initialize with a particular set of sound files (in caf format)
    @param soundFiles array of sound file names (without caf extension)
    @param radians orientation of first direction (usual value is 0 - parallel to the x axis -)
    @return id of initialized instance
    @note The sound files must be arraged in clockwise order, with the first one oriented at the starting angle (<a>radians</a>)
 */
-(id) initWithSoundFiles:(NSArray*)soundFiles andStartingAtAngle:(float)radians
{
    if (self = [super init])
    {
        if (!soundFiles)
        {
            AudioFeedbackDebugLog(@"Invalid sound files. Falling back to default sounds (Piano).");
            return [self init];
        }
        else
        {
            self.numberOfDirections = [soundFiles count];
            self.spacingBetweenDirections = SPACING(self.numberOfDirections);
            [self setUpMultipleOpenALSounds:soundFiles looping:YES];
        }
        
        if (radians < 0 || radians > 2*M_PI)
        {
            AudioFeedbackDebugLog(@"Invalid starting angle (%f is not in [0,2*PI]). Using 0 as default.", radians);
            self.firstDirectionAngle = 0.f;
        }
        else
        {
            self.firstDirectionAngle = radians;
        }
        
        // set OpenAL distance model
        alDistanceModel(AL_LINEAR_DISTANCE);
    }
    
    return self;
}

///** -- excluded due to copyright
//    Initializes audio feedback with a reordered sequence of 4 sounds from the "Radial Direction" model
//    @return id of initialized instance
//    Enables smooth audio transitions and sets the first direction angle to 0 (right) by default.
//    @note See Harada, Takagi, Asakawa, "On the audio representation of radial direction", CHI'11
// */
//-(id) initWithSusumu4Sounds
//{
//    if (self = [super init])
//    {
//        NSArray *files = [[NSArray alloc] initWithObjects:
//                          @"AudioFeedback.framework/Resources/susumu_i_S",          // DIR_RIGHT
//                          @"AudioFeedback.framework/Resources/susumu_aw_S",         // DIR_DOWN
//                          @"AudioFeedback.framework/Resources/susumu_ibar_S",       // DIR_LEFT
//                          @"AudioFeedback.framework/Resources/susumu_u_S",          // DIR_UP
//                          nil];
//        [self setUpMultipleOpenALSounds:files looping:YES];
//        self.numberOfDirections = [files count];
//        self.spacingBetweenDirections = SPACING(self.numberOfDirections);
//        self.smoothTransition = YES;
//        self.firstDirectionAngle = 0.f;
//        // set OpenAL distance model
//        alDistanceModel(AL_LINEAR_DISTANCE);
//        
//    }
//    return self;
//}

/**
    Initialize with default speech files ("up","down","left","right")
    @return id of initialized instance
    Disables smooth audio transitions and sets the first direction angle to 0 (right) by default.
 */
-(id) initWithSpeechSounds
{
    if (self = [super init])
    {
        NSArray *files = [[NSArray alloc] initWithObjects:
                          @"AudioFeedback.framework/Resources/speech_right",          // DIR_RIGHT
                          @"AudioFeedback.framework/Resources/speech_down",           // DIR_DOWN
                          @"AudioFeedback.framework/Resources/speech_left",           // DIR_LEFT
                          @"AudioFeedback.framework/Resources/speech_up",             // DIR_UP
                          nil];
        [self setUpMultipleOpenALSounds:files looping:YES];
        self.numberOfDirections = [files count];
        self.spacingBetweenDirections = SPACING(self.numberOfDirections);
        self.smoothTransition = NO;
        self.firstDirectionAngle = 0.f;        
        // set OpenAL distance model
        alDistanceModel(AL_LINEAR_DISTANCE);
        
    }
    return self;
}

/**
    Initialize with electric piano tone (single direction, single sound file)
    @return id of initialized instance
    Disables smooth audio transitions and sets the first direction angle to 0 (right) by default.
 */
-(id) initWithPianoSound
{
    if (self = [super init])
    {
        [self useLinearSound:@"AudioFeedback.framework/Resources/garage_electricPiano"];
        self.firstDirectionAngle = 0.f;
        self.smoothTransition = NO;
        // set OpenAL distance model
        alDistanceModel(AL_LINEAR_DISTANCE);
        
    }
    return self;
}

/**
    Initialize with electric piano beep (single direction, single sound file)
    @return id of initialized instance
    Disables smooth audio transitions and sets the first direction angle to 0 (right) by default.
 */
-(id) initWithPianoBeepSound
{
    if (self = [super init])
    {
        [self useLinearSound:@"AudioFeedback.framework/Resources/garage_electricPianoBeep"];
        self.firstDirectionAngle = 0.f;
        self.smoothTransition = YES;
        // set OpenAL distance model
        alDistanceModel(AL_LINEAR_DISTANCE);
        
    }
    return self;
}

//-(void) useSusumu4Sounds
//{
//    if ([self isSetUp]) {
//        [self cleanUpOpenAL];
//        [
//    }
//    
//    NSArray *files = [[NSArray alloc] initWithObjects:
//                      @"AudioFeedback.framework/Resources/susumu_i_S",          // DIR_RIGHT
//                      @"AudioFeedback.framework/Resources/susumu_aw_S",         // DIR_DOWN
//                      @"AudioFeedback.framework/Resources/susumu_ibar_S",       // DIR_LEFT
//                      @"AudioFeedback.framework/Resources/susumu_u_S",          // DIR_UP
//                      nil];
//    [self setUpMultipleOpenALSounds:files looping:YES];
//    self.numberOfDirections = [files count];
//    self.spacingBetweenDirections = SPACING(self.numberOfDirections);
//    self.smoothTransition = YES;
//    self.firstDirectionAngle = 0.f;
//    // set OpenAL distance model
//    alDistanceModel(AL_LINEAR_DISTANCE);
//    
//}
//
//-(void) useSpeechSounds
//{
//    
//}
//
//-(void) usePianoSounds
//{
//    
//}
//
//-(void) usePianoBeepSound
//{
//    
//}


/**
    Start providing audio feedback
    @param distance distance from target to goal
    @param radians target orientation with respect to goal (0 means to the right)
    @return <a>TRUE</a> if audio feedback started successfully
 */
-(BOOL) startWithDistance:(float*)distance andOrientation:(float*)radians
{
    if ([self.sourceArray count] == 0 || [self.bufferArray count] == 0)
    {
        AudioFeedbackDebugLog(@"There is no source or buffer to play.");
        return FALSE;
    }
    
    if ([self playingSound])
    {
        AudioFeedbackDebugLog(@"AudioFeedback is already active. Why start again?");
        return FALSE;
    }
    
//    // position listener at the origin
//    ALenum lastErrorCode;
//    alListener3f(AL_POSITION, 0.f, 0.f, 0.f);
//    if ((lastErrorCode = alcGetError( self.alDevice )) != AL_NO_ERROR)
//    {
//        AudioFeedbackDebugLog(@"An error (code = %d) ocurred while positioning listener.", lastErrorCode);
//        return FALSE;
//    }
    
    alDopplerFactor(0.0); // disable doppler effect!
    
    // start playing
    NSUInteger sourceID;
    ALenum lastErrorCode;
    int n = 1;
    for (id source in self.sourceArray)
    {
        sourceID = [source unsignedIntValue];
        alSourcef(sourceID, AL_GAIN, 0.f);
        if ((lastErrorCode = alcGetError( self.alDevice )) != AL_NO_ERROR)
        {
            AudioFeedbackDebugLog(@"An error (code = %d) ocurred while mutting sound %d.", lastErrorCode, n);
            return FALSE;
        }
        alSourcePlay(sourceID);
        if ((lastErrorCode = alcGetError( self.alDevice )) != AL_NO_ERROR)
        {
            AudioFeedbackDebugLog(@"An error (code = %d) ocurred while starting sound %d.", lastErrorCode, n);
            return FALSE;
        }
        n++;
    }
    
    // update listener position with given data
    return [self updateFeedbackWithDistance:distance andOrientation:radians];
}

/**
    Stop providing audio feedback
    @return <a>TRUE</a> if everything went ok
 */
-(BOOL) stop
{
    // start playing
    NSUInteger sourceID;
    ALenum lastErrorCode;
    int n = 1;
    for (id source in self.sourceArray)
    {
        sourceID = [source unsignedIntValue];
        alSourceStop(sourceID);
        if ((lastErrorCode = alcGetError( self.alDevice )) != AL_NO_ERROR)
        {
            AudioFeedbackDebugLog(@"An error (code = %d) ocurred while stopping sound %d.", lastErrorCode, n);
            return FALSE;
        }
        n++;
    }
    return TRUE;
}

/**
    Update audio feedback
    @param distance distance from target to goal (pass NULL for pitch = 1)
    @param radians target orientation with respect to goal (0 means to the right)
    @return <a>TRUE</a> if audio feedback was updated successfully
    Moves the listener around to modify the type of sound, and sets up pitch according to distance
 */
-(BOOL) updateFeedbackWithDistance:(float*)distance andOrientation:(float*)radians
{
    if (radians == NULL) 
        return FALSE; // need radial information to play the right sound
    
    dispatch_sync(self.queue, ^{
        
        ALfloat pitchVal = 1;
        if (distance != NULL)
            pitchVal = PITCH_MAX * (1.0 - ((*distance) * PITCH_MAX / DISTANCE_MAX));
        
        NSUInteger sourceID;
        ALenum lastErrorCode;
        int n = 0, state;
        float sourceAngle, diff, gain, midspace;
//        NSLog(@"----");
        for (id source in self.sourceArray)
        {
            sourceID = [source unsignedIntValue];
            
            // radians is in [-M_PI, M_PI]
            // so we compute the direction of the sound in that frame of reference
            sourceAngle = - (n*self.spacingBetweenDirections + self.firstDirectionAngle);
            if (sourceAngle > 2*M_PI) sourceAngle = sourceAngle - 2*M_PI;
            if (sourceAngle > M_PI) sourceAngle = sourceAngle - 2*M_PI;
            if (sourceAngle < -2*M_PI) sourceAngle = 2*M_PI + sourceAngle;
            if (sourceAngle < -M_PI) sourceAngle = sourceAngle + 2*M_PI;
            
            // compute the angular difference between the target and the source
            diff = *radians - sourceAngle;
            if (diff > M_PI) diff = 2*M_PI - diff;
            else if (diff < -M_PI) diff = 2*M_PI + diff;
            else if (diff < 0) diff = -diff;
            
            // if the difference is greater than the spacing/2 + delta, we make the gain zero
            // (delta is used to smooth a bit the transition)
            if (self.smoothTransition) {          
                
                midspace = self.spacingBetweenDirections*SPACING_MULTIPLIER;
                if (diff > midspace) gain = 0.f;
                else gain =  1.f - (diff/midspace); 
                
                alSourcef(sourceID, AL_GAIN, gain);
                
            } else {
                
                if (diff > self.spacingBetweenDirections*0.5) { gain = 0.f; alSourceStop(sourceID); }
                else {
                    gain = 1.f; 
                    alSourcef(sourceID, AL_GAIN, gain);
                    alGetSourcei(sourceID, AL_SOURCE_STATE, &state);
                    if (state != AL_PLAYING && state != AL_INITIAL) {
                        alSourcePlay(sourceID);
                    }
                }
                
            }
//            NSLog(@"radians(%f) - source(%d) - source_angle = %f diff = %f gain = %f",
//                  *radians, n, sourceAngle, diff, gain);
            
            lastErrorCode = alcGetError( self.alDevice );
            
            if (lastErrorCode != AL_NO_ERROR)
            {
                AudioFeedbackDebugLog(@"An error (code = %d) ocurred while mutting sound %d.", lastErrorCode, n);
            }
            
            if (gain > 0)
            {
                alSourcef(sourceID, AL_PITCH, pitchVal);
                lastErrorCode = alcGetError( self.alDevice );
                if (lastErrorCode != AL_NO_ERROR)
                {
                    AudioFeedbackDebugLog(@"An error (code = %d) ocurred while setting up pitch for sound %d.", lastErrorCode, n);
                }
            }
            n = n + 1;
        }
    });
    
    return TRUE;
}

/**
    Does the audio feedback class care about radial orientation?
    @return <a>YES</a> if the class (or subclass) cares
    @note This function can be used to save computation (not all classes care about radial orientation!)
 */
-(BOOL) caresAboutRadialOrientation
{
    return YES;
}



@end
