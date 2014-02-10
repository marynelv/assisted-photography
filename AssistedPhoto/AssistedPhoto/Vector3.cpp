//
//  vector3.cpp
//  AudiballMix
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

#include "Vector3.h"
#include <math.h>

/** Constructor
 */
Vector3::Vector3(float a, float b, float c) 
{
	x = a;
	y = b;
	z = c;
}

/** Destructor
 */
Vector3::~Vector3()
{}

/** Equivalent operator
	\param v vector to compare with
	\return <a>true</a> if vectors are equivalent
 */
bool 
Vector3::operator==(const Vector3& v) const
{
	return (x == v.x && y == v.y && z == v.z);
}

/** Non-equivalent operator
	\param v vector to compare with
	\return <a>true</a> if vectors are not equivalent
 */
bool 
Vector3::operator!=(const Vector3& v) const
{
	return !(*this == v);
}

/** Assignment operator
	\param v vector to compare with
	\return copy of v
 */
Vector3& 
Vector3::operator=(const Vector3& v)
{
	x = v.x;
	y = v.y;
	z = v.z;
	return *this;
}

/** Addition operator
	\param v vector to compare with
	\return this vector plus v
 */
Vector3 
Vector3::operator+(const Vector3& v) const
{
	return Vector3(x+v.x,y+v.y,z+v.z);
}

/** Subtraction operator
	\param v vector to compare with
	\return this vector plus v
 */
Vector3 
Vector3::operator-(const Vector3& v) const
{
	return Vector3(x-v.x,y-v.y,z-v.z);
}

/** Multiplication by scalar
	\param k scalar
	\return this vector times k
 */
Vector3 
Vector3::operator*(float k) const
{
	
	return Vector3(x*k,y*k,z*k);
}

/** Dot product
	\param v vector
	\return dot product between this vector and v
 */
float 
Vector3::dot(const Vector3& v) const
{	
	return x*v.x + y*v.y + z*v.z;
}

/** Cross product
	\param v vector
	\return cross product between this vector and v
 */
Vector3 
Vector3::cross(const Vector3& v) const
{	
	return Vector3(v.z*y - v.y*z, v.x*z - v.z*x, v.y*x - v.x*y);
}

/** Vector norm
	\return l2 vector norm
 */
float 
Vector3::norm() const
{
	return sqrt(x*x + y*y + z*z);
}

/** Squared vector norm
	\return squared l2 vector norm
 */
float 
Vector3::norm2() const
{
	return x*x + y*y + z*z;
}

/** Normalize vector
	\note the (0,0,0) always remains unchanged
 */ 
void 
Vector3::normalize()
{
	float n = norm();
	if (n != 0.0)
	{
		x /= n;
		y /= n;
		z /= n;
	}
}

/** Check if vector is (0,0,0)
	\return <a>true</a> if vector is equal to (0,0,0)
 */
bool 
Vector3::isOrigin() const
{
	return x == 0.0 && y == 0.0 && z == 0.0;
}
