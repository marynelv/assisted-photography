//
//  vector3.h
//  BasicMath
//
//    Created by Marynel Vazquez on 2/15/11.
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

#ifndef BASICMATH_VECTOR3
#define BASICMATH_VECTOR3

#ifdef __cplusplus
#include <iostream>
#endif
    
/** 3-dimensional vector 
 */
class Vector3
{
	
public:
	
	float x;			//!< first coordinate
	float y;			//!< second coordinate
	float z;			//!< third coordinate
	
	Vector3(float a = 0.0, float b = 0.0, float c = 0.0);
    Vector3(const Vector3& v);
	~Vector3();
	
	bool operator==(const Vector3& v) const;
	bool operator!=(const Vector3& v) const;
	Vector3& operator=(const Vector3& v);
	Vector3 operator+(const Vector3& v) const;
	Vector3 operator-(const Vector3& v) const;
	Vector3 operator*(float k) const;
	float dot(const Vector3& v) const;
	Vector3 cross(const Vector3& v) const;
	float norm() const;
	float norm2() const;
	void normalize();
	bool isOrigin() const;
	
#ifdef __cplusplus
	/** Output vector to ostream 
	 */
	friend std::ostream& operator<<(std::ostream& os, const Vector3& v3)
	{
		os << v3.x << " " << v3.y << " " << v3.z << std::endl;
		return os;
	}
#endif
	
};
    
	
#endif