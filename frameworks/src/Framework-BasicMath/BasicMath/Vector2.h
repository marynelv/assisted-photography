//
//  Vector2.h
//  BasicMath
//
//    Created by Marynel Vazquez on 12/5/11.
//    Copyright 2011 Carnegie Mellon University.
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

#ifndef BASICMATH_VECTOR2
#define BASICMATH_VECTOR2

#ifdef __cplusplus
#include <iostream>
#endif

/** 2-dimensional vector 
 */
class Vector2
{
	
public:
	
	float x;			//!< first coordinate
	float y;			//!< second coordinate
	
	Vector2(float a = 0.0, float b = 0.0);
	~Vector2();
	
	bool operator==(const Vector2& v) const;
	bool operator!=(const Vector2& v) const;
	Vector2& operator=(const Vector2& v);
	Vector2 operator+(const Vector2& v) const;
	Vector2 operator-(const Vector2& v) const;
	Vector2 operator*(float k) const;
	float norm() const;
	float norm2() const;
	void normalize();
	bool isOrigin() const;
	
#ifdef __cplusplus
	/** Output vector to ostream 
	 */
	friend std::ostream& operator<<(std::ostream& os, const Vector2& v2)
	{
		os << v2.x << " " << v2.y << std::endl;
		return os;
	}
#endif
	
};


#endif
