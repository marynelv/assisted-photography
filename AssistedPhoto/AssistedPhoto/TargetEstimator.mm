//
//  TargetGenerator.m
//  AudiballMix
//
//    Created by Marynel Vazquez on 09/13/2011.
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

#import "TargetEstimator.h"
#import <DataLogging/DLTiming.h>

#pragma mark - Common set up

@implementation TargetEstimator (CustomClassMethods)

/**
    Log date unique identifier
    @return string id based on current time and date
 */
+(NSString *)commonLogIdentifier
{
    NSDate *dateCreated = [[NSDate alloc] init];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyMMdd_HHmmss"];
    return [dateFormatter stringFromDate:dateCreated];
}

@end

@implementation TargetEstimator
@synthesize target;
@synthesize targetMarkerView;
@synthesize audioFeedback;
@synthesize audioFeedbackType;
@synthesize successAudioClip;
@synthesize startAudioClip;
@synthesize targetLog;
@synthesize logIdentifier;
@synthesize done;
@synthesize runningTime;
@synthesize processingTime;
@synthesize startGestureRecognizer;
@synthesize stopGestureRecognizer;
@synthesize startInfoLabel;

#pragma mark - Standard UIViewController 

- (void)didReceiveMemoryWarning
{
    
    
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.processingTime = 0;
    
    // standard configuration
    self.view.backgroundColor = [UIColor blackColor];
    
    // sucess audio clip
    self.successAudioClip = [[AudioClip alloc] initWithClip:@"garage_turup"];
    // start audio clip
    self.startAudioClip = [[AudioClip alloc] initWithClip:@"garage_tum"];
    
    // target marker
    TargetMarkerView *markerView = [[TargetMarkerView alloc] initWithFrame:[self.view frame]];
    markerView.backgroundColor = [UIColor clearColor];
    [self setTargetMarkerView:markerView];
    [self.view addSubview:markerView];
    
    // start gesture
    self.startGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self 
                                                                              action:@selector(startEstimatingMotion)];
    self.startGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.startGestureRecognizer];
    
//    // stop gesture
//    self.stopGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self 
//                                                                               action:@selector(restart)];
//    
//    self.stopGestureRecognizer.minimumPressDuration = 1.0;
//    self.stopGestureRecognizer.numberOfTouchesRequired = 2;
//    [self.view addGestureRecognizer:self.stopGestureRecognizer];
    
    // transition style
    [self setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal]; 
    
    // start info label
    self.startInfoLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 438, 320, 35)];
    self.startInfoLabel.text = @"Tap to start";
    self.startInfoLabel.font = [UIFont fontWithName:@"Gill Sans" size:30.0];
    self.startInfoLabel.textColor = [UIColor whiteColor];
    self.startInfoLabel.textAlignment = UITextAlignmentCenter; 
    self.startInfoLabel.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.startInfoLabel];
    
    // ready to start
    self.done = NO;
//    [self start];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
 
    self.targetMarkerView = nil;    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
    
    [self stopAll];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
//    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - TargetEstimator Specific 

/**
    NSString representation of a Vector3
    @param v vector to describe
    @return string describing the vector
 */
-(NSString*) vector3toStr:(Vector3*)v
{
    NSString* str = [NSString stringWithFormat:@"(%f, %f, %f)",
                     v->x, v->y, v->z];
    return str;
}

/**
    String description of the target
    @return string description
 */
-(NSString *) description
{
    NSString *d = [NSString stringWithFormat:@"[%@] target = (%f, %f, %f)",
                   [self class], 
                   self.target.x, 
                   self.target.y, 
                   self.target.z];
    return d;
}

/**
    Generate new target
    @return target
 */
-(void) newTarget
{
    [NSException raise:NSInternalInconsistencyException 
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

/**
    Start app and logging but, don't process data yet
 */
-(void) start
{    
    // set up log identifier to facilitate grouping files
    self.logIdentifier = [TargetEstimator commonLogIdentifier];
    self.done = NO;
    
// NOTE: Uncomment if you'd like to log data to app space
    // find target, start logging and start estimating motion
    if (![self startLogging])
    {
        NSLog(@"Could not initialize all logging files!");
    }
    
    self.startInfoLabel.hidden = NO;
}

/**
    Do what is necessary to start estimating motion
 */
-(void) startEstimatingMotion
{
    [NSException raise:NSInternalInconsistencyException 
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

/**
    Do what is necessary to stop estimating motion
 */
-(void) stopEstimatingMotion
{
    [NSException raise:NSInternalInconsistencyException 
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

/** 
    Restart system
 */
-(void) restart
{    
    [self stopAll];
    [self start];
}

/**
    Is motion being estimated?
 */
-(BOOL) isEstimatingMotion
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];    
}


/** 
    Set acceptance radius (on TargetMarkerView)
    @param radius acceptance radius
 */
-(void) setAcceptanceRadius:(CGFloat)radius
{
    [self.targetMarkerView setAcceptanceRadius:radius];
}

/**
    Set up audtio feedback 
    @param audioType audio feedback type
    @return <a>TRUE</a> if <a>audioFeedback</a> was initialized properly
 */
-(BOOL) setUpAudioFeedback:(AudioType)audioType
{
    switch (audioType) {
        case AUDIOFEEDBACK_SILENT:
            self.audioFeedback = nil;
            break;
        case AUDIOFEEDBACK_PIANO:
            self.audioFeedback = [[RadialAudioFeedback alloc] initWithPianoSound];
            break;
        case AUDIOFEEDBACK_PIANOBEEP:
            self.audioFeedback = [[RadialAudioFeedback alloc] initWithPianoBeepSound];
            break;
//        case AUDIOFEEDBACK_SUSUMU4: -- removed due to copyright
//            self.audioFeedback = [[RadialAudioFeedback alloc] initWithSusumu4Sounds];
//            break;
        case AUDIOFEEDBACK_SPEECH4:
            self.audioFeedback = [[RadialAudioFeedback alloc] initWithSpeechSounds];
            break;
        default:
            [NSException raise:NSInternalInconsistencyException 
                        format:@"Unrecognized audio feedback type. Check the AudioFeedback class for available types."];
            break;
    }
    
    self.audioFeedbackType = audioType;
    
    return [self.audioFeedback isSetUp];
}

/**
    Dismiss target estimator
 */
-(IBAction) dismissModalView:(UIGestureRecognizer *)sender
{
    [self stopEstimatingMotion];
    [self.audioFeedback stop];
    [self.targetMarkerView stopAnimation];
    [self dismissModalViewControllerAnimated:YES];
}

/**
    Start logging common data accross all target estimators
    @return are we logging?
 */
-(BOOL)startLogging
{
    self.targetLog = [[DLTextLog alloc] initWithName:[[NSString alloc] initWithFormat:@"%@_target", self.logIdentifier]];
    if (self.targetLog == nil) return NO;
    
    [self.targetLog appendString:[[NSString alloc] initWithFormat:@"%@\n", [self targetEstimatorDescription]]];
    
    self.runningTime = tic();
    
    return YES;
}

/**
    Stop logging common data accross all target estimators
 */
-(void) stopLogging
{
    self.runningTime = NANOS_TO_SEC(toc(self.runningTime));
    self.processingTime = NANOS_TO_SEC(toc(self.processingTime));
    [self.targetLog appendString:[[NSString alloc] initWithFormat:@"# times %f %f\n", self.processingTime, self.runningTime]];
    
    self.processingTime = 0;
    
    self.targetLog = nil;
}

/**
    Declare successful run after the target reached the goal
 */
-(void) declareSuccessfulRun
{
    [self.successAudioClip play];
    [self stopAll];
}

/**
    Stop estimating motion and logging
 */
-(void) stopAll
{    
    self.done = YES;
    
    [self stopEstimatingMotion];
    [self stopLogging];
    
    self.logIdentifier = nil;
}

/**
    String description of target estimator
    @return string description
 */
-(NSString *)targetEstimatorDescription
{
    NSString *audioTypeStr;
    switch (self.audioFeedbackType) {
        case AUDIOFEEDBACK_SILENT:
            audioTypeStr = @"SILENT";
            break;
        case AUDIOFEEDBACK_PIANO:
            audioTypeStr = @"PIANO";
            break;
        case AUDIOFEEDBACK_PIANOBEEP:
            audioTypeStr = @"PIANOBEEP";
            break;
//        case AUDIOFEEDBACK_SUSUMU4: -- removed due to copyright
//            audioTypeStr = @"SUSUMU4";
//            break;
        case AUDIOFEEDBACK_SPEECH4:
            audioTypeStr = @"SPEECH4";
            break;
        default:
            audioTypeStr = @"?";
            break;
    }
    
    NSString *str = [[NSString alloc] initWithFormat:@"# %@ %@ %f", 
                     NSStringFromClass([self class]), 
                     audioTypeStr, 
                     [self.targetMarkerView acceptanceRadius]];
    return str;
}

@end
