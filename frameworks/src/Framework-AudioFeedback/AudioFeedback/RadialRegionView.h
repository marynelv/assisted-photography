//
//  RadialRegionView.h
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

#import <UIKit/UIKit.h>

@interface RadialRegionView : UIView

@property (nonatomic, assign) CGPoint center;                                   //!< circle's center point
@property (nonatomic, assign) int internalRadius;                               //!< radius from center
@property (nonatomic, assign) int externalRadius;                               //!< radius from center
@property (nonatomic, assign, setter = setNumDirections:) int numDirections;    //!< number of radial directions
@property (nonatomic, retain) UIColor *markerColor;                             //!< marker color to delimit radial regions
@property (nonatomic, assign) float startingAngle;                              //!< starting angle in radians (0 by default)

-(id) initWithFrame:(CGRect)frame center:(CGPoint)centerPoint intRad:(int)internal extRad:(int)external;
-(id) initWithFrame:(CGRect)frame center:(CGPoint)centerPoint intRad:(int)internal extRad:(int)external numDir:(int)num;

@end
