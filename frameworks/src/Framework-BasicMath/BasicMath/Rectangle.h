//
//  Rectangle.h
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

#ifndef BASICMATH_RECTANGLE
#define BASICMATH_RECTANGLE

#ifdef __cplusplus
#include <iostream>
#endif

#include "Vector2.h"

class Rectangle {
public:
    Vector2 origin;
    Vector2 size;
    
    Rectangle(float w, float h);
    Rectangle(float x1 = 0, float y1 = 0, float x2 = 0, float y2 = 0);
    bool operator==(const Rectangle& r) const;
    bool operator!=(const Rectangle& r) const;
    Rectangle& operator=(const Rectangle& r);
    
    inline float left() const
        { return origin.x; }
    inline float top() const
        { return origin.y; }
    inline float right() const
        { return origin.x + size.x; }
    inline float bottom() const
        { return origin.y + size.y; }
    inline float width() const
        { return size.x; }
    inline float height() const
        { return size.y; }
    inline Vector2 center() const 
        { return Vector2(left() + width()/2.0, top() + height()/2.0); }
    
#ifdef __cplusplus
    /** Output vector to ostream 
     */
    friend std::ostream& operator<<(std::ostream& os, const Rectangle& r)
    {
        os << r.left() << " " << r.top() << " " << r.width() << " " << r.height();
        return os;
    }
#endif
    
};


#endif
