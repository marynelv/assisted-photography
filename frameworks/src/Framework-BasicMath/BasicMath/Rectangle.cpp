//
//  Rectangle.cpp
//  BasicMath
//
//  Created by Marynel Vazquez on 12/6/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
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

#include "Rectangle.h"

Rectangle::Rectangle(float x1, float y1, float x2, float y2)
{
    origin = Vector2(x1,y1);
    size = Vector2(x2 - x1, y2 - y1);
}

Rectangle::Rectangle(float w, float h)
{
    origin = Vector2();
    size = Vector2(w,h);
}

bool 
Rectangle::operator==(const Rectangle& r) const
{
    return origin == r.origin && size == r.size;
}

bool 
Rectangle::operator!=(const Rectangle& r) const
{
    return !(*this == r);
}

Rectangle& 
Rectangle::operator=(const Rectangle& r)
{
    origin = r.origin;
    size = r.size;
	return *this;
}
