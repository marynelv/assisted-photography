//
//  Quaternion.h
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

#ifndef BASICMATH_QUATERNION
#define BASICMATH_QUATERNION

#include "Vector3.h"

/*! Quaternion
 */
class Quaternion
{
public:
	
	float* elem;
	
	Quaternion();
	Quaternion(const Quaternion& qua);
	Quaternion(float q0, float q1, float q2, float q3);
	Quaternion(float q1, float q2, float q3);
	Quaternion(const Vector3& v);
	~Quaternion();
	
	//setters
	void setPureQua(float q1, float q2, float q3);
	void setPureQua(Vector3& v);
	
	//getters
	float x() const;
	float y() const;
	float z() const;
	float scalarPart() const;
	float* vectorPart() const;
	Vector3 vector3() const;
	
	//operators
	bool operator==(const Quaternion& qua) const;
	bool operator!=(const Quaternion& qua) const;
	Quaternion& operator=(const Quaternion& qua);
	Quaternion operator+(const Quaternion& qua) const;
	Quaternion operator-(const Quaternion& qua) const;
	Quaternion operator*(const Quaternion& qua) const;
	Quaternion operator*(float k) const;
	Quaternion conjugate() const;
	
	//util 
	float norm();
	bool normalize();
	bool normalize(float epsilon);
	bool isAllZeros();

	//other useful methods
	static Quaternion rotation(const Vector3& v1, const Vector3& v2, float threshold = 0.0001);
	Vector3 rotateCCW(const Vector3 v) const;
	Vector3 rotateCW(const Vector3 v) const;
    float* rotationMatrix3x3() const;

#ifdef __cplusplus
	/*! Output quaternion to ostream
	 */
	friend std::ostream& operator<<(std::ostream& os, const Quaternion& q)
	{
		os << q.elem[0] << " " << q.elem[1] << " " << q.elem[2] << " " << q.elem[3];
		return os;
	}
#endif
    
};

#endif