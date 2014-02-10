//
//  BlurryBar.h
//  Framework-See
//
//  Created by Marynel Vazquez on 3/2/12.
//  Copyright (c) 2012 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BlurryBar : UIView

@property (atomic, assign) float blurryLevel;
@property (nonatomic, retain) UIColor *color;

@end
