//
//  RadialAudioFeedback.h
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

/**
    Radial Direction Audio Feedback
    Imagine a circle centered at the goal, and divide it in <a>numberOfDirections</a> directions. 
    Audio feedback is produced by increasing the audio coming from the direction closer to the 2d target on the screen, 
    and by adjusting the pitch of the sound depending on how far this target is from the goal.
 
    @note For now, only 4 radial dimensions are implemented.
 */
@interface RadialAudioFeedback : AudioFeedback   
@property (nonatomic, assign) int numberOfDirections;                  //!< number of radial directions to use
@property (nonatomic, assign) float spacingBetweenDirections;          //!< spacing between radial directions (2*pi / numberOfDirections)
@property (nonatomic, assign) float firstDirectionAngle;               //!< angle (in radians) of first direction
@property (nonatomic, assign) BOOL smoothTransition;                   //!< smooth sound transitions

-(id) init;
-(id) initWithSoundFiles:(NSArray*)soundFiles andStartingAtAngle:(float)radians;
// easy sound initializers
//-(id) initWithSusumu4Sounds; -- excluded due to copyright
-(id) initWithSpeechSounds;
-(id) initWithPianoSound;
-(id) initWithPianoBeepSound;

//-(void) useSusumu4Sounds;
//-(void) useSpeechSounds;
//-(void) usePianoSounds;
//-(void) usePianoBeepSound;

-(BOOL) startWithDistance:(float*)distance andOrientation:(float*)radians;
-(BOOL) stop;
-(BOOL) updateFeedbackWithDistance:(float*)distance andOrientation:(float*)radians;
-(BOOL) caresAboutRadialOrientation;

@end
