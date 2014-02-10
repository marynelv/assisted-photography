//
//  TargetMarkerView.m
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

#import "TargetMarkerView.h"

#ifdef LOG_PRINT_FRAME_RATE 
#import <QuartzCore/QuartzCore.h>
#endif

#define BALL_EXTERNAL_RADIUS    20.0
#define BALL_INTERNAL_RADIUS    13.0

#define DRAWING_INTERVAL        (1.0/30.0) // 30 Hz

#pragma mark Private

@interface TargetMarkerView (Drawing)
-(void) drawMarker:(CGContextRef)ctx;
-(void) drawGoal:(CGContextRef)ctx;
@end

@implementation TargetMarkerView (Drawing)

/**
    Draw marker
    @param ctx context
 */
-(void) drawMarker:(CGContextRef)ctx
{
    if (self.targetPoint.x < 0) return; // target is outside view
    
    CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
	CGContextFillEllipseInRect(ctx, CGRectMake(self.targetPoint.x-BALL_EXTERNAL_RADIUS, 
                                               self.targetPoint.y-BALL_EXTERNAL_RADIUS, 
                                               BALL_EXTERNAL_RADIUS*2.0, BALL_EXTERNAL_RADIUS*2.0));
	CGContextSetRGBFillColor(ctx, .7, .7, .7, 1);
	CGContextFillEllipseInRect(ctx, CGRectMake(self.targetPoint.x-BALL_INTERNAL_RADIUS, 
                                               self.targetPoint.y-BALL_INTERNAL_RADIUS, 
                                               BALL_INTERNAL_RADIUS*2.0, BALL_INTERNAL_RADIUS*2.0));
}

/**
    Draw goal
    @param ctx context
 */
-(void) drawGoal:(CGContextRef)ctx
{
    // acceptance radius
	CGContextSetLineWidth(ctx, 1.0);
	CGContextSetRGBStrokeColor(ctx, .5, .5, .5, 1.0);
	CGContextAddArc(ctx, self.targetGoal.x, self.targetGoal.y, self.acceptanceRadius, 0, 2.0*M_PI, 1);
	CGContextStrokePath(ctx);
	
	// real target
	CGContextSetLineWidth(ctx, 3.0);
	CGContextSetRGBStrokeColor(ctx, 0.0, .67, 1.0, 1.0);
	CGContextMoveToPoint(ctx, self.targetGoal.x-10.0, self.targetGoal.y-10.0);
	CGContextAddLineToPoint(ctx, self.targetGoal.x+10.0, self.targetGoal.y+10.0);
	CGContextStrokePath(ctx);
	CGContextMoveToPoint(ctx, self.targetGoal.x-10.0, self.targetGoal.y+10.0);
	CGContextAddLineToPoint(ctx, self.targetGoal.x+10.0, self.targetGoal.y-10.0);
	CGContextStrokePath(ctx);
}
@end

#pragma mark Public

@implementation TargetMarkerView
@synthesize targetPoint;
@synthesize targetGoal;
@synthesize acceptanceRadius;
@synthesize timer;

/**
    Initializer
    @param frame view frame
    @note The <a>targetGoal</a> is set to the middle of the frame by default, and acceptance radius is 20. 
    These values can be changed using their respective setters.
 */
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.targetPoint = CGPointMake(-1.f, -1.f);
        self.targetGoal = CGPointMake(frame.size.width/2.0, frame.size.height/2.0);
        self.acceptanceRadius = 20;
        self.timer = nil;

#ifdef LOG_PRINT_FRAME_RATE
        timeTracker = new TimeIntervalTracker();
#endif

    }
    return self;
}

- (void)dealloc
{
    
#ifdef LOG_PRINT_FRAME_RATE 
    delete timeTracker;
#endif

}

/**
    Draw target marker
 */
- (void)drawRect:(CGRect)rect
{   
#ifdef LOG_PRINT_FRAME_RATE 
    timeTracker->update(CACurrentMediaTime());
    NSLog(@"draw rect frame rate: %d", timeTracker->rate());
#endif
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextClearRect(ctx, rect);
    
    [self drawMarker:ctx];
    [self drawGoal:ctx];
}

/**
    Did the target reach the goal?
    @return True if the target is close enough to the goal
    Tells if the distance between <a>targetPoint</a> and <a>targetGoal</a> is less than <a>acceptanceRadius</a>
 */
-(BOOL) targetReachedGoal
{
    float dx = targetPoint.x - targetGoal.x;
    float dy = targetPoint.y - targetGoal.y;
    return (dx*dx + dy*dy) < acceptanceRadius*acceptanceRadius;
}


-(BOOL) targetOutsideBounds
{
    return  targetPoint.x < 0 || targetPoint.y < 0 || 
            targetPoint.x > self.frame.size.width || 
            targetPoint.y > self.frame.size.height;
}

/**
    Start animating target marker
    @param initial target position
 */
-(void) startAnimation:(CGPoint)target
{
    if (self.timer != nil && [self.timer isValid])
    {
        DebugLog(@"The targetMarkerView is bing animated. Why start again?");
        return;
    }

    // set initial target position
    self.targetPoint = target;

    // start drawing!
    self.timer = [NSTimer
                  scheduledTimerWithTimeInterval:DRAWING_INTERVAL
                  target:self 
                  selector:@selector(setNeedsDisplay) 
                  userInfo:nil 
                  repeats:YES];

}

/**
    Stop animating target marker
    @note reset the targer position (<a>targetPoint</a>) and moves it outside the view
 */
-(void) stopAnimation
{
    // get rid of timer if it was scheduled
    if (self.timer == nil) return;
    if ([self.timer isValid]) [self.timer invalidate];
    self.timer = nil;
}

/**
    Euclidean distance from target to goal
    @return distance
 */
-(float) distanceToGoal
{
    float dx = self.targetPoint.x - self.targetGoal.x;
    float dy = self.targetPoint.y - self.targetGoal.y;
    return sqrtf(dx*dx + dy*dy);
}

/**
    Target orientation in radians
    @return radians between a horizontal positive vector coming out of the goal and the vector from the goal to the target
 */
-(float) targetOrientation
{
    float dx = self.targetPoint.x - self.targetGoal.x;
    float dy = self.targetGoal.y - self.targetPoint.y; //- (self.targetPoint.y - self.targetGoal.y);
    return atan2(dy, dx);
}

@end
