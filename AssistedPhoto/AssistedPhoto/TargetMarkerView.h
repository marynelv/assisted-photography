//
//  TargetMarkerView.h
//  AudiballMix
//
//    Created by Marynel Vazquez on 9/20/11.
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

#import <UIKit/UIKit.h>
#import "TimeIntervalTracker.h"

@interface TargetMarkerView : UIView
{
    
#ifdef LOG_PRINT_FRAME_RATE
    TimeIntervalTracker *timeTracker;                   //!< frame rate tracker
#endif
    
}

@property (nonatomic, assign) CGPoint targetPoint;      //!< current position of the target
@property (nonatomic, assign) CGPoint targetGoal;       //!< desired target goal (ideal placement)
@property (nonatomic, assign) CGFloat acceptanceRadius; //!< acceptance radius around <a>targetGoal</a>
@property (nonatomic, retain) NSTimer *timer;           //!< drawing timer

-(BOOL) targetReachedGoal;
-(BOOL) targetOutsideBounds;
-(void) startAnimation:(CGPoint)target;
-(void) stopAnimation;

-(float) distanceToGoal;
-(float) targetOrientation;

@end
