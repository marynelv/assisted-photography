//
//  SeeTestSaliencyViewController+FileHandling.h
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "SeeTestSaliencyViewController.h"

@interface SeeTestSaliencyViewController (FileHandling)
- (NSString *) moviePath;
- (BOOL) deleteFileIfAlreadyExists:(NSString *)path;
@end
