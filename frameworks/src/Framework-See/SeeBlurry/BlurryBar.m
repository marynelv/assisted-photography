//
//  BlurryBar.m
//  Framework-See
//
//  Created by Marynel Vazquez on 3/2/12.
//  Copyright (c) 2012 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "BlurryBar.h"

#define MAX_BAR_WIDTH   320
#define MAX_BAR_HEIGHT  20

@implementation BlurryBar
@synthesize blurryLevel;
@synthesize color;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        
        self.blurryLevel = 1.0;
        self.color = [UIColor redColor];
        
    }
    return self;
}


- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];  
    
    CGRect rectangle = CGRectMake(0, self.frame.size.height - MAX_BAR_HEIGHT, 
                                  MAX_BAR_WIDTH * blurryLevel, MAX_BAR_HEIGHT );
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [self.color CGColor]);
//    CGContextSetRGBFillColor(context, 1.0, 0.0, 0.0, 1.0);
    CGContextSetRGBStrokeColor(context, 0.0, 0.0, 0.0, 1.0);
    CGContextFillRect(context, rectangle);
}

@end
