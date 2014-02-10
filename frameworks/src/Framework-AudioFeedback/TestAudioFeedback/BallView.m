//
//  BallView.m
//  Framework-AudioFeedback
//
//  Created by Marynel Vazquez on 1/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BallView.h"

@implementation BallView
@synthesize ballColor;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextClearRect(context, rect);
    
    // Drawing code
    CGContextSetFillColorWithColor(context, self.ballColor.CGColor);
	CGContextFillEllipseInRect(context, CGRectMake(self.frame.origin.x, 
												   self.frame.origin.y, 
												   self.frame.size.width, 
                                                   self.frame.size.height));
}

@end
