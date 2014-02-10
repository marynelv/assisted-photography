//
//  SeeTestSaliencyViewController+FileHandling.m
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "SeeTestSaliencyViewController+FileHandling.h"

#define MOVIE_FILE_NAME         @"saliency.mov"

@implementation SeeTestSaliencyViewController (FileHandling)

- (NSString *) moviePath
{
	NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectoryPath = [dirs objectAtIndex:0];
	return [documentsDirectoryPath stringByAppendingPathComponent:MOVIE_FILE_NAME];
}

- (BOOL) deleteFileIfAlreadyExists:(NSString *)path
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:path])
	{
		[fileManager removeItemAtPath:path error:NULL];	
		return YES;
	}
	return NO;
}

@end
