//
//  RadialRegionView.m
//  Framework-AudioFeedback
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

#import "RadialRegionView.h"

@interface RadialRegionView () {
    float dir_angle;        //!< angle for each direction
    float dir_halfangle;    //!< half-angle for each direction
}
@end

@implementation RadialRegionView
@synthesize center;
@synthesize internalRadius;
@synthesize externalRadius;
@synthesize numDirections;
@synthesize markerColor;
@synthesize startingAngle;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
    }
    return self;
}

/**
 * Initializer
 * @param frame view frame
 * @param centerPoint center location of the radial regions
 * @param internal internal radius
 * @param external external radius
 * Sets number of dimensions to 4 by default, starting angle to 0, and marker color to white
 */
-(id) initWithFrame:(CGRect)frame center:(CGPoint)centerPoint intRad:(int)internal extRad:(int)external
{
    self = [self initWithFrame:frame];
    if (self) {
        self.center = centerPoint;
        self.internalRadius = internal;
        self.externalRadius = external;
        self.numDirections = 4;
        self.markerColor = [UIColor whiteColor];
        self.startingAngle = 0;
    }
    return self;
}

/**
 * Initializer
 * @param frame view frame
 * @param centerPoint center location of the radial regions
 * @param internal internal radius
 * @param external external radius
 * @param num number of radial dimensions
 */
-(id) initWithFrame:(CGRect)frame center:(CGPoint)centerPoint 
             intRad:(int)internal extRad:(int)external numDir:(int)num
{
    self = [self initWithFrame:frame center:centerPoint intRad:internal extRad:external];
    if (self) {
        self.numDirections = num;
    }
    return self;
}

-(void) setNumDirections:(int)num
{
    numDirections = num;
    
    dir_angle = 2.0*M_PI/num;	
    dir_halfangle = M_PI/num;	
}

// Drawing code
- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, rect);
    
	CGFloat insideCircleRad = self.internalRadius;	
	CGFloat outsideCircleRad = self.externalRadius;	
	
	//	CGContextSetRGBFillColor(context, 0, 0, 0, 1.0);
	CGContextSetLineWidth(context, 2.0);
    CGContextSetStrokeColorWithColor(context, self.markerColor.CGColor);
	CGContextStrokeEllipseInRect(context, CGRectMake(self.center.x - insideCircleRad, 
													 self.center.y - insideCircleRad, 
													 insideCircleRad*2.0, insideCircleRad*2.0));
	CGContextStrokeEllipseInRect(context, CGRectMake(self.center.x - outsideCircleRad, 
													 self.center.y - outsideCircleRad, 
													 outsideCircleRad*2.0, outsideCircleRad*2.0));
	

	CGFloat ptAx, ptAy, ptBx, ptBy;
	CGFloat ang = dir_halfangle; // move only half angle at the beginning
	for (int s = 0; s < self.numDirections; s++)
	{
		if (s > 0) ang = s*dir_angle + dir_halfangle + startingAngle;
		ptAx = sin(ang)*insideCircleRad;
		ptAy = cos(ang)*insideCircleRad;
		ptBx = sin(ang)*outsideCircleRad;
		ptBy = cos(ang)*outsideCircleRad;
		//if (ang < M_PI/4 || ang > 3*M_PI/4) { ptAy = -ptAy; ptBy = -ptBy; }
		CGContextSetLineWidth(context, 2.0);
		CGContextSetRGBStrokeColor(context, 1, 1, 1, 1.0);
		CGContextMoveToPoint(context, self.center.x + ptAx, self.center.y + ptAy);
		CGContextAddLineToPoint(context, self.center.x + ptBx, self.center.y + ptBy);
		CGContextStrokePath(context);
	}

    
}

@end
