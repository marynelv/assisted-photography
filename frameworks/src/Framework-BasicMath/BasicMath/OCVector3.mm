//
//  OCVector3.m
//  BasicMath
//
//  Created by Marynel Vazquez on 11/12/12.
//  Copyright (c) 2012 Robotics Institute. Carnegie Mellon University. All rights reserved.
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

#import "OCVector3.h"
#include "Vector3.h"

struct Vector3Opaque {
    Vector3 vector3;
    Vector3Opaque() : vector3() {};
    Vector3Opaque(float x, float y, float z) : vector3(x,y,z) {};
};

@interface OCVector3 ()
@property (nonatomic, readwrite, assign) Vector3Opaque *vector3cpp;
@end

@implementation OCVector3
@synthesize vector3cpp=_vector3cpp;

- (id)init {
    self = [super init];
    if (self != nil) {
        self.vector3cpp = new Vector3Opaque();
    }
    return self;
}


- (id)initWithX:(float)x Y:(float)y Z:(float)z {
    self = [super init];
    if (self != nil) {
        self.vector3cpp = new Vector3Opaque(x,y,z);
    }
    return self;
}

- (void)dealloc {
    delete _vector3cpp;
    _vector3cpp = NULL;
    [super dealloc];
}

-(float)getXAccel {
    return self.vector3cpp->vector3.x;
}

-(float)getYAccel {
    return self.vector3cpp->vector3.y;
}

-(float)getZAccel {
    return self.vector3cpp->vector3.z;
}

-(void)setX:(float)x Y:(float)y Z:(float)z {
    self.vector3cpp->vector3.x = x;
    self.vector3cpp->vector3.y = y;
    self.vector3cpp->vector3.z = z;
}

@end
