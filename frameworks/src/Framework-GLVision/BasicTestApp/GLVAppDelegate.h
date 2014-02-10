//
//  GLVAppDelegate.h
//  Framework-GLVision
//
//  Created by Marynel Vazquez on 10/22/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GLVViewController;

@interface GLVAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) GLVViewController *viewController;

@end
