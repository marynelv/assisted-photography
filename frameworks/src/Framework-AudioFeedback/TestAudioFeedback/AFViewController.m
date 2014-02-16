//
//  AFViewController.m
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

#import "AFViewController.h"

#define CIRCLE_CENTER_X 160
#define CIRCLE_CENTER_Y 240

static float distanceTo(float x, float y, float goalx, float goaly)
{
    float diffx = x-goalx, diffy = y-goaly;
    return sqrtf(diffx*diffx + diffy*diffy);
}

static float radians(float x, float y, float goalx, float goaly)
{
    float vecx = x - goalx, vecy = y - goaly;
    return atan2f(-vecy, vecx); // inverse direction along the unit circle
}

@implementation AFViewController
@synthesize audioFeedback;
@synthesize audioType;
@synthesize radialRegionView;
@synthesize ballView;
@synthesize rotationGestureRecognizer;
@synthesize typeLabel;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.rotationGestureRecognizer = [[UIRotationGestureRecognizer alloc] 
                                      initWithTarget:self 
                                      action:@selector(handleRotationGesture:)];
    [self.view addGestureRecognizer:self.rotationGestureRecognizer];
    
    self.view.backgroundColor = [UIColor blackColor];

    // load radial regions to be displayed
    self.radialRegionView = [[RadialRegionView alloc] initWithFrame:CGRectMake(0,0,320,480)
                                                             center:CGPointMake(CIRCLE_CENTER_X,CIRCLE_CENTER_Y) 
                                                             intRad:30 extRad:100 
                                                             numDir:4];
    self.radialRegionView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:self.radialRegionView];
    
    self.ballView = [[BallView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    self.ballView.ballColor = [UIColor orangeColor];
    [self.ballView setHidden:YES];
    [self.view addSubview:self.ballView];
    
    self.audioType = AUDIO_PIANO;
    [self startAudioFeedback];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
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
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(BOOL) startAudioFeedback
{
    if (self.audioFeedback != nil) {
        [self.audioFeedback stop];
        self.audioFeedback = nil;
    }
    
    switch (self.audioType) {
//        case AUDIO_SUSUMU4: -- excluded due to copyright
//            self.audioFeedback = [[RadialAudioFeedback alloc] init];
//            self.radialRegionView.numDirections = 4;
//            self.typeLabel.text = @"Radial (Susumu)";
//            break;
        case AUDIO_SPEECH4:
            self.audioFeedback = [[RadialAudioFeedback alloc] initWithSpeechSounds];
            self.radialRegionView.numDirections = 4;
            self.typeLabel.text = @"Radial (Spoken)";
            break;
        case AUDIO_PIANO:
            self.audioFeedback = [[RadialAudioFeedback alloc] initWithPianoSound];
            self.radialRegionView.numDirections = 0;
            self.typeLabel.text = @"Linear (electric piano)";
            break;
        case AUDIO_PIANOBEEP:
            self.audioFeedback = [[RadialAudioFeedback alloc] initWithPianoBeepSound];
            self.radialRegionView.numDirections = 0;
            self.typeLabel.text = @"Linear (paused electric piano)";
            break;            
        default:
            break;
    }
    [self.radialRegionView setNeedsDisplay];
    
    return [self.audioFeedback isSetUp];
}

// Handles the start of a touch
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (self.audioFeedback == nil) return;
    
	if ([touches count] == 1) 
	{
		UITouch *touch = [touches anyObject];
		CGPoint p = [touch locationInView:self.view];
        
        float dist; float rad;
        
        switch (self.audioType) {
//            case AUDIO_SUSUMU4: -- excluded due to copyright
//                dist = distanceTo(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
//                rad = radians(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
//                [self.audioFeedback startWithDistance:&dist andOrientation:&rad];
//                break;
            case AUDIO_SPEECH4:
                dist = distanceTo(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
                rad = radians(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
                [self.audioFeedback startWithDistance:&dist andOrientation:&rad];
                break;
            case AUDIO_PIANOBEEP:
            case AUDIO_PIANO:
                dist = distanceTo(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
                [self.audioFeedback startWithDistance:&dist andOrientation:NULL];
                break;
                
            default:
                break;
        }
        
        self.ballView.center = p;
        [self.ballView setHidden:NO];
	}
    else 
    {
        [self.audioFeedback stop];
        [self.ballView setHidden:YES];
    }
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{ 
    if (self.audioFeedback == nil) return;
    
	if ([touches count] == 1) 
	{
		UITouch *touch = [touches anyObject];
		CGPoint p = [touch locationInView:self.view];
        
        float dist; float rad;
        switch (self.audioType) {
//            case AUDIO_SUSUMU4: -- excluded due to copyright
//                dist = distanceTo(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
//                rad = radians(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
//                [self.audioFeedback updateFeedbackWithDistance:&dist andOrientation:&rad];
//                break;
            case AUDIO_SPEECH4:
                dist = distanceTo(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
                rad = radians(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
                [self.audioFeedback updateFeedbackWithDistance:&dist andOrientation:&rad];
                break;
            case AUDIO_PIANO:
            case AUDIO_PIANOBEEP:
                dist = distanceTo(p.x, p.y, CIRCLE_CENTER_X, CIRCLE_CENTER_Y);
                rad = 0;
                [self.audioFeedback updateFeedbackWithDistance:&dist andOrientation:&rad];
                break;
                
            default:
                break;
        }
        
        self.ballView.center = p;
	} 
    else 
    {
        [self.audioFeedback stop];
        [self.ballView setHidden:YES];
    }
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!self.audioFeedback) return;
    
    [self.audioFeedback stop];
    [self.ballView setHidden:YES];
}


-(IBAction) handleRotationGesture:(UIGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        
        switch (self.audioType) {
//            case AUDIO_SUSUMU4: -- excluded due to copyright
//                self.audioType = AUDIO_SPEECH4;
//                break;
            case AUDIO_SPEECH4:
                self.audioType = AUDIO_PIANO;
                break;
            case AUDIO_PIANO:
                self.audioType = AUDIO_PIANOBEEP;
                break;
            case AUDIO_PIANOBEEP:
                self.audioType = AUDIO_SPEECH4;
                break;
            default:
                break;
        }
        
        // restart audio feedback
        [self startAudioFeedback];  
    }
    else if (sender.state == UIGestureRecognizerStateBegan)
    {
        [self.ballView setHidden:YES];
        [self.audioFeedback stop];
    }
}

@end
