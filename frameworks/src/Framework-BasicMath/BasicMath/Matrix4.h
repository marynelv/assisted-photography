//
//  matrix.h
//  BasicMath
//
//    Created by Marynel Vazquez on 10/18/11.
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

#ifndef BASICMATH_MATRIX4
#define BASICMATH_MATRIX4

#include "Quaternion.h"

/**
    Matrix4 elements in column major order
 */
typedef enum
{
    MAT4_11,        //!< 1,1
    MAT4_21,        //!< 2,1
    MAT4_31,        //!< 3,1
    MAT4_41,        //!< 4,1
    MAT4_12,        //!< 1,2
    MAT4_22,        //!< 2,2
    MAT4_32,        //!< 3,2
    MAT4_42,        //!< 4,2
    MAT4_13,        //!< 1,3
    MAT4_23,        //!< 2,3
    MAT4_33,        //!< 3,3
    MAT4_43,        //!< 4,3
    MAT4_14,        //!< 1,4
    MAT4_24,        //!< 2,4
    MAT4_34,        //!< 3,4
    MAT4_44,        //!< 4,4
    MAT4_NUMELEM    //!< number of elements in the matrix
} Mat4Elem;         


/**
    4x4 Matrix (typically used as projection matrix)
 */
class Matrix4
{
public:
    
    float* elem;            //!< matrix elements (in column-major order)
    
    Matrix4();
    Matrix4(float*& e);
    ~Matrix4();
    
    Matrix4& operator=(const Matrix4& matrix);
    bool operator==(const Matrix4& matrix);
    bool operator!=(const Matrix4& matrix);
    Matrix4 operator+(const Matrix4& matrix);
    Matrix4 operator-(const Matrix4& matrix);
    Matrix4 operator*(const Matrix4& matrix);
    float& operator[](Mat4Elem x);
    float& operator[](int x);
    
    static Matrix4 identity();
    
    // affine transformation matrices
    static Matrix4 translate(float x, float y, float z);
    static Matrix4 rotateX(float radians);
    static Matrix4 rotateY(float radians);
    static Matrix4 rotateZ(float radians);
    static Matrix4 rotateQua(const Quaternion& q);
    
    // camera matrices
    static Matrix4 orthographic(float left, float right, float bottom, float top, float near, float far);
    
    // projection
    Vector3 projectVector(const Vector3 v) const;
    
#ifdef __cplusplus
    /*! Output quaternion to ostream
	 */
	friend std::ostream& operator<<(std::ostream& os, const Matrix4& m)
	{
		os << m.elem[MAT4_11] << " " << m.elem[MAT4_12] << " " << m.elem[MAT4_13] << " " << m.elem[MAT4_14] << std::endl;
		os << m.elem[MAT4_21] << " " << m.elem[MAT4_22] << " " << m.elem[MAT4_23] << " " << m.elem[MAT4_24] << std::endl;
		os << m.elem[MAT4_31] << " " << m.elem[MAT4_32] << " " << m.elem[MAT4_33] << " " << m.elem[MAT4_34] << std::endl;
		os << m.elem[MAT4_41] << " " << m.elem[MAT4_42] << " " << m.elem[MAT4_43] << " " << m.elem[MAT4_44] << std::endl;
		return os;
	}
#endif
    
};


#endif
