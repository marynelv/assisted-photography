//
//  AFViewController.h
//  TestAudioFeedback
//
//    Created by Marynel Vazquez on 1/11/12.
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

#import <UIKit/UIKit.h>
#import <AudioFeedback/RadialAudioFeedback.h>
//#import <AudioFeedback/LinearAudioFeedback.h>
#import <AudioFeedback/RadialRegionView.h>
#import "BallView.h"

typedef enum AudioFeedbackType {
    AUDIO_PIANO,            //!< linear (garage_electricPiano)
    AUDIO_PIANOBEEP,        //!< linear (garage_electricPianoSilence)
    //AUDIO_SUSUMU4,          //!< radial/susumu (4 directions only) -- excluded due to copyright
    AUDIO_SPEECH4,          //!< radial/spoken (4 direction only)
    AUDIO_NUMTYPES          //!< number of audio feedback types
} AudioType;

@interface AFViewController : UIViewController

@property (nonatomic, retain) AudioFeedback *audioFeedback;
@property (nonatomic, assign) AudioType audioType;
@property (nonatomic, retain) RadialRegionView *radialRegionView;
@property (nonatomic, retain) BallView *ballView;
@property (nonatomic, retain) UIRotationGestureRecognizer *rotationGestureRecognizer;
@property (nonatomic, retain) IBOutlet UILabel *typeLabel;

-(BOOL) startAudioFeedback;
-(IBAction) handleRotationGesture:(UIGestureRecognizer *)sender;

@end
