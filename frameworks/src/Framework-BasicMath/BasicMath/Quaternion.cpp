//
//  Quaternion.cpp
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

#include "Quaternion.h"
#include <math.h>


/*! Quaternion constructor
	\note The quaternion is set up as the identity rotation
 */
Quaternion::Quaternion()
{
	elem = (float*)calloc(4, sizeof(float));
	elem[0] = 1;
	elem[1] = 0;
	elem[2] = 0;
	elem[3] = 0;
}

/*! Quaternion (copy-like) constructor
	\param qua Quaternion to copy data from
 */
Quaternion::Quaternion(const Quaternion& qua)
{
	elem = (float*)calloc(4, sizeof(float));
	memcpy(elem, qua.elem, 4);
}

/*! Quaternion constructor
	\param q0 scalar part
	\param q1 first component of vector part
	\param q2 second component of vector part
	\param q3 third component of vector part
 */
Quaternion::Quaternion(float q0, float q1, float q2, float q3)
{
	elem = (float*)calloc(4, sizeof(float));
	elem[0] = q0;
	elem[1] = q1;
	elem[2] = q2;
	elem[3] = q3;
}

/*! Pure quaternion constructor
 \param q1 first component of vector part
 \param q2 second component of vector part
 \param q3 third component of vector part
 */
Quaternion::Quaternion(float q1, float q2, float q3)
{
	elem = (float*)calloc(4, sizeof(float));
	elem[0] = 0.0f;
	elem[1] = q1;
	elem[2] = q2;
	elem[3] = q3;
}

/*! Pure quaternion constructor
 \param v 3d vector
 \param q2 second component of vector part
 \param q3 third component of vector part
 */
Quaternion::Quaternion(const Vector3& v)
{
	elem = (float*)calloc(4, sizeof(float));
	elem[0] = 0.0f;
	elem[1] = v.x;
	elem[2] = v.y;
	elem[3] = v.z;
}

/*! Destructor 
 */
Quaternion::~Quaternion()
{
	free(elem);
}

//-setters-----------------------------------------------------

/*! Set pure quaternion
 \param q1 first component of vector part
 \param q2 second component of vector part
 \param q3 third component of vector part
 */
void 
Quaternion::setPureQua(float q1, float q2, float q3)
{
	elem[0] = 0.0f;
	elem[1] = q1;
	elem[2] = q2;
	elem[3] = q3;
}

/*! Set pure quaternion
 \param v 3d vector
 */
void 
Quaternion::setPureQua(Vector3& v)
{
	elem[0] = 0.0f;
	elem[1] = v.x;
	elem[2] = v.y;
	elem[3] = v.z;
}

//-getters-----------------------------------------------------

/*! First component of vector part
	\return second element of quaternion
 */
float 
Quaternion::x() const
{
	return elem[1];
}

/*! Second component of vector part
 \return third element of quaternion
 */
float 
Quaternion::y() const
{
	return elem[2];	
}

/*! Third component of vector part
 \return fourth element of quaternion
 */
float 
Quaternion::z() const
{
	return elem[3];
}

/*! Scalar part
	\return first element of quaternion
 */
float 
Quaternion::scalarPart() const
{
	return elem[0];	
}

/*! Vector part
	\return array with second, third and fourth component 
	\note if result is altered, quaternion is also changed
 */
float* 
Quaternion::vectorPart() const
{
	return &(elem[1]);
}

/*! Vector part
	\return 3d vector with vector part
 */
Vector3 
Quaternion::vector3() const
{
	return Vector3(elem[1],elem[2],elem[3]);
}

//-operators---------------------------------------------------

/*! Equal operator
	\param qua other quaternion
	\return <a>true</a> if this quaternion is equal to the other
 */
bool 
Quaternion::operator==(const Quaternion& qua) const
{
	return (elem[0] == qua.elem[0] &&
			elem[1] == qua.elem[1] &&
			elem[2] == qua.elem[2] &&
			elem[3] == qua.elem[3]);
}

/*! Not equal operator
	\param qua other quaternion
	\return <a>true</a> if this quaternion is not equal to the other
 */
bool 
Quaternion::operator!=(const Quaternion& qua) const
{
	return !(*this == qua);
}

/*! Assignment operator
	\param qua quaternion to copy data from
	\return quaternion with assigned data
 */
Quaternion& 
Quaternion::operator=(const Quaternion& qua)
{
	
	if (&qua != this)
	{
//		cblas_scopy(4, qua.elem, 1, elem, 1);	
		elem[0] = qua.elem[0];
		elem[1] = qua.elem[1];
		elem[2] = qua.elem[2];
		elem[3] = qua.elem[3];
	}

	return *this;
}

/*! Add operator
	\param qua other quaternion to add
	\return this quaternion plus the other
 */
Quaternion 
Quaternion::operator+(const Quaternion& qua) const
{
//	Quaternion q(*this);
//	cblas_saxpy(4, 1.0f, qua.elem, 1, q.elem, 1);
//	return q;
	return Quaternion(elem[0]+qua.elem[0], 
					  elem[1]+qua.elem[1], 
					  elem[2]+qua.elem[2], 
					  elem[3]+qua.elem[3]);
}

/*! Subtraction operator
 \param qua other quaternion to subtract from
 \return this quaternion minus the other
 */
Quaternion 
Quaternion::operator-(const Quaternion& qua) const
{
//	Quaternion q(*this);
//	cblas_saxpy(4, -1.0f, qua.elem, 1, q.elem, 1);
//	return q;
	return Quaternion(elem[0]-qua.elem[0], 
					  elem[1]-qua.elem[1], 
					  elem[2]-qua.elem[2], 
					  elem[3]-qua.elem[3]);
}

/*! Quaternion multiplication 
	\param qua other quaternion to multiply by
	\return this quaternion times the other quaternion
 */
Quaternion 
Quaternion::operator*(const Quaternion& qua) const
{
	Quaternion q;
//	float 
//	*tmp1 = (float*)calloc(4,sizeof(float)), 
//	*tmp2 = (float*)calloc(4,sizeof(float)), 
//	*tmp3 = (float*)calloc(4,sizeof(float));
//	
//	q.elem[0] = cblas_sdsdot(3, elem[0]*qua.elem[0], &(elem[1]), 4, &(qua.elem[1]), 4);
//	
//	cblas_ccopy(3, &(qua.elem[1]), 4, &(tmp1[1]), 4);
//	cblas_ccopy(3, &(elem[1]), 4, &(tmp2[1]), 4);
//	
//	cblas_sscal(3, elem[0], &(tmp1[1]), 4);
//	cblas_sscal(3, qua.elem[0], &(tmp2[1]), 4);
//	
//	const float W[9] = 
//			{	   0.f,	 elem[3],	-elem[2],
//			 -elem[3],		 0.f,	 elem[1],
//			  elem[2],	-elem[1],		 0.f};
//	cblas_sgemv(CblasRowMajor, CblasNoTrans, 3, 3, 1.0f, W, 3, &(qua.elem[1]), 4, 0.0, &(tmp3[1]), 4);
//	
//	cblas_saxpy(4, 1.0f, tmp1, 4, tmp2, 4);
//	cblas_saxpy(4, 1.0f, tmp2, 4, tmp3, 4);
//	cblas_saxpy(4, 1.0f, tmp3, 4, q.elem, 4);
					   
	q.elem[0] = (qua.elem[0]*elem[0]) - (qua.elem[1]*elem[1]) - (qua.elem[2]*elem[2]) - (qua.elem[3]*elem[3]);
	q.elem[1] = (elem[0]*qua.elem[1]) + (elem[1]*qua.elem[0]) + (elem[2]*qua.elem[3]) - (elem[3]*qua.elem[2]);
	q.elem[2] = (elem[0]*qua.elem[2]) - (elem[1]*qua.elem[3]) + (elem[2]*qua.elem[0]) + (elem[3]*qua.elem[1]);
	q.elem[3] = (elem[0]*qua.elem[3]) + (elem[1]*qua.elem[2]) - (elem[2]*qua.elem[1]) + (elem[3]*qua.elem[0]);

	return q;
}

/*! Multiplication operator
	\param k constant multiply by
	\return result from multiplication
 */
Quaternion 
Quaternion::operator*(float k) const
{
	Quaternion q;
//	Quaternion q(*this);
//	cblas_sscal(4,k,q.elem,1);
	q.elem[0] = elem[0] * k;
	q.elem[1] = elem[1] * k;
	q.elem[2] = elem[2] * k;
	q.elem[3] = elem[3] * k;
	return q;
}


/*! Conjugate
	\return quaternion conjugate (inverse)
 */
Quaternion 
Quaternion::conjugate() const
{
	Quaternion q;
	q.elem[0] = elem[0];
	q.elem[1] = -elem[1];
	q.elem[2] = -elem[2];
	q.elem[3] = -elem[3];
	return q;
}

/*! Quaternion norm (equal to vector l2 norm)
	\return norm
 */
float 
Quaternion::norm()
{
//	float n = cblas_sdot(4, elem, 1, elem, 1);
	float n = elem[0]*elem[0] + elem[1]*elem[1] + 
			  elem[2]*elem[2] + elem[3]*elem[3];
	n = sqrtf(n);
	return n;
}

/*! Normalize quaternion
	\return <a>true</a> if quaternion was normalized
	Normalizing fails if the Euclidean norm of the quaternion	
	is 0.
 */
bool 
Quaternion::normalize()
{
	float n = norm();
	if (n != 0)
	{
		n = 1.0/n;
//		cblas_sscal(4,n,elem,1);
		elem[0] = elem[0]/n;
		elem[1] = elem[1]/n;
		elem[2] = elem[2]/n;
		elem[3] = elem[3]/n;
		return true;
	}
	return false;
}

/*! Normalize quaternion
	\param epsilon threshold for normalizing
	\return <a>true</a> if vector was normalized, or <a>false</a> if norm is 0.
	The quaternion is normalized if its norm differs from 1 by
	at least <a>epsilon</a>.
 */
bool 
Quaternion::normalize(float epsilon)
{
	float n = norm();
	if (n != 0 && fabs(n - 1) > epsilon)
	{
		n = 1.0/n;
//		cblas_sscal(4,n,elem,1);
		elem[0] = elem[0]*n;
		elem[1] = elem[1]*n;
		elem[2] = elem[2]*n;
		elem[3] = elem[3]*n;
		return true;
	}
	return false;
}

/*! Check if quaternion is all zeros
	\return <a>true</a> if quaternion is [0, (0,0,0)]
 */
bool 
Quaternion::isAllZeros()
{
	return 
	elem[0] == 0.0 && 
	elem[1] == 0.0 && 
	elem[2] == 0.0 && 
	elem[3] == 0.0;
}

/*! Find rotation between two vectors
	\param v1 a vector
	\param v2 another vector
	\param threshold difference in orientation threshold
	\return quaternion q such that v2 = q*v1*q' where q' is the conjugate
 
	First we find the amount of rotation to be performed between the 
	vectors using the dot product. Then we find an axis of rotation
	using the cross product. If the vectors lie (almost) on the same 
	line - if their angle is less than <a>threshold</a> -, we set an 
	arbitrary axis of rotation by default.
 
	If either <a>v1</a> or <a>v2</a> are (0,0,0), then
	the result is the [0, (0, 0, 0)] quaternion.
 
	\note The rotation q*v*q' rotates the vector v in the counter-clockwise 
	direction.
 */
Quaternion 
Quaternion::rotation(const Vector3& v1, const Vector3& v2, 
					 float threshold)
{
	if (v1.isOrigin() || v2.isOrigin())
	{
		// nothing to do with (0,0,0) vectors!
		return Quaternion();
	}
	
	float norm1 = v1.norm();
	float norm2 = v2.norm();
	
	float angle = acos(v1.dot(v2)/(norm1*norm2));	// angle in [0,PI]
	Vector3 u;										// rotation axis
	
	if (angle < threshold || angle > M_PI - threshold)
	{
		// vectors are too close to each other!
		// so we pick a non-parallel vector as axis
		if (v1.z != 0.0)
		{ u.x = v1.y; u.y = -v1.x; u.z = v1.z; }
		else if (v1.y != 0.0)
		{ u.x = v1.z; u.y = v1.y; u.z = -v1.x; }
		else
		{ u.x = v1.x; u.y = v1.z; u.z = -v1.y; }
	}
	else 
	{
		// find a perpendicular axis using the cross product
		u = v1.cross(v2);
	}
	
	//normalize rotation axis
	u.normalize();
	
	angle = angle*0.5;
	float c = cos(angle); // cos(angle/2)
	float s = sin(angle); // sin(angle/2)
	return Quaternion(c, s*u.x, s*u.y, s*u.z);
}

/*! Rotate vector in counter-clockwise direction
	\param v vector to rotate
	\return q*v*q' where q is this quaternion and q' is its conjugate
 */
Vector3 
Quaternion::rotateCCW(const Vector3 v) const
{
	Quaternion v4d(v);
	Quaternion conj = conjugate();
	Quaternion rotated = (*this)*v4d*conjugate();
	return rotated.vector3();
}

/*! Rotate vector in clockwise direction
 \param v vector to rotate
 \return q'*v*q where q is this quaternion and q' is its conjugate
 */
Vector3 
Quaternion::rotateCW(const Vector3 v) const
{
	Quaternion v4d(v);
	Quaternion rotated = conjugate()*v4d*(*this);
	return rotated.vector3();
}

/*! Construct 3x3 rotation matrix from quaternion
 \return array containing the elements of the rotation matrix
 The elements of the rotation matrix are stored in row-major order
 (elem11, elem12, elem13, then elem21, elem22, elem23...)
 \note The returned array must be released by the user using delete[]!
 */
float* 
Quaternion::rotationMatrix3x3() const
{
    float *rotation = new float[9];
    
    float xx = elem[1]*elem[1];
    float xy = elem[1]*elem[2];
    float xz = elem[1]*elem[3];
    float xw = elem[1]*elem[0];
    
    float yy = elem[2]*elem[2];
    float yz = elem[2]*elem[3];
    float yw = elem[2]*elem[0];
    
    float zz = elem[3]*elem[3];
    float zw = elem[3]*elem[0];
    
    rotation[0] = 1 - 2 * ( yy + zz );  // rot11
    rotation[1] =     2 * ( xy - zw );  // rot12
    rotation[2] =     2 * ( xz + yw );  // rot13
    
    rotation[3] =     2 * ( xy + zw );  // rot21
    rotation[4] = 1 - 2 * ( xx + zz );  // rot22
    rotation[5] =     2 * ( yz - xw );  // rot23
    
    rotation[6] =     2 * ( xz - yw );  // rot31
    rotation[7] =     2 * ( yz + xw );  // rot32
    rotation[8] = 1 - 2 * ( xx + yy );  // rot33
    
    return rotation;
}
