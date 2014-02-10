//
//  AudioClip.m
//  Framework-AudioFeedback
//
//    Created by Marynel Vazquez on 1/23/12.
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

#import "AudioClip.h"
#import "AudioFeedbackCommon.h"

@interface AudioClip (Private)
-(BOOL) registerClipSound:(NSURL *)clipURLRef;
@end

@implementation AudioClip (Private)

-(BOOL) registerClipSound:(NSURL *)clipURLRef
{
    SystemSoundID ssid = 0;
    OSStatus errStatus = AudioServicesCreateSystemSoundID((__bridge CFURLRef) clipURLRef, &ssid);
    self.clipSSID = ssid;
    return errStatus == noErr;
}

@end

@implementation AudioClip
@synthesize clipSSID;

/**
    Initialize audio clip whith given sound file
    @param clipName name of clip in AudioFeedback bundle
    @return AudioClip id
 
    Creates system sound id for given clip.
 */
-(id) initWithClip:(NSString *)clipName
{
    NSURL* clipURL = [[NSBundle mainBundle] URLForResource:[[NSString alloc] initWithFormat:@"AudioFeedback.framework/Resources/%@", clipName] 
                                             withExtension:@"caf"];
    return [self initWithClipURL:clipURL];
}


/**
    Initialize audio clip with given sound file (could be outside the AudioFeedback bundle)
    @param clipURL url to clip file
    @return AudioClip id
 
    Creates system sound id for given clip.
 */
-(id) initWithClipURL:(NSURL *)clipURL
{
    self = [super init];
    if (self) {
        
        self.clipSSID = 0;
        if (![self registerClipSound:clipURL])
        {
            AudioFeedbackDebugLog(@"Sound clip %@ could not be registered with Audio Services.", [clipURL absoluteString]);
            self = nil;
        }
        
    }    
    return self;
}

-(void) dealloc 
{
    AudioServicesDisposeSystemSoundID(self.clipSSID);
}

-(void) play
{
    AudioServicesPlaySystemSound(self.clipSSID);
}


@end
