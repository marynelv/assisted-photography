//
//  matrix.cpp
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


#include "Matrix4.h"
#include <cstring>
#include <math.h>

/**
    Constructor
    Sets all elements of the matrix to zero.
 */
Matrix4::Matrix4()
{
    elem = new float[MAT4_NUMELEM];
    memset(elem, 0, sizeof(float)*MAT4_NUMELEM);
}

/**
    Constructor
    @param e 16 elements to fill the matrix with
    Sets all elements to match the provided array
 */
Matrix4::Matrix4(float*& e)
{
    elem = new float[MAT4_NUMELEM];
    for(int i=0; i<MAT4_NUMELEM; i++)
    {
        elem[i] = e[i];
    }
}

/**
    Destructor
 */
Matrix4::~Matrix4()
{
    delete[] elem;
}

/**
    Assigment operator
    @param matrix matrix to copy elements from
    @return matrix copy
 */
Matrix4& 
Matrix4::operator=(const Matrix4& matrix)
{
    if (this != &matrix)
    {
        for(int i=0; i<MAT4_NUMELEM; i++)
        {
            elem[i] = matrix.elem[i];
        }
    }
    return *this;
}

/**
    Equality operator
    @param matrix matrix to compare with
    @return do matrices have the same elements in the same positions?
 */
bool 
Matrix4::operator==(const Matrix4& matrix)
{
    if (this == &matrix)
        return true;
    
    for(int i=0; i<MAT4_NUMELEM; i++)
    {
        if (elem[i] != matrix.elem[i])
            return false;
    }
    
    return true;
}

/**
    Not-equal operator
    @param matrix matrix to compare with
    @return are matrices different?
 */
bool 
Matrix4::operator!=(const Matrix4& matrix)
{
    return !(*this == matrix);
}

/**
    Sum operator
    @param matrix matrix to sum up with
    @return the sum of this matrix and the given one
 */
Matrix4 
Matrix4::operator+(const Matrix4& matrix)
{
    Matrix4 sum;
    for(int i=0; i<MAT4_NUMELEM; i++)
    {
        sum.elem[i] = elem[i] + matrix.elem[i];
    }
    return sum;
}

/** Difference operator
    @param matrix matrix to subtract 
    @return this matrix minus the given matrix
 */
Matrix4 
Matrix4::operator-(const Matrix4& matrix)
{
    Matrix4 dif;
    for(int i=0; i<MAT4_NUMELEM; i++)
    {
        dif.elem[i] = elem[i] - matrix.elem[i];
    }
    return dif;    
}

/**
    Matrix multiplication
    @param matrix to multiply by
    @return this matrix times the given matrix
 */
Matrix4 
Matrix4::operator*(const Matrix4& matrix)
{
    int idx;
    float dotProd;
    Matrix4 mult;
    for(int i=0; i<4; i++)
        for(int j=0; j<4; j++)
        {
            idx = j*4 + i;
            dotProd = 0;
            for (int d=0; d<4; d++)
            {
                dotProd += elem[d*4 + i]*matrix.elem[j*4 + d];
            }
            mult.elem[idx] = dotProd;
        }
    return mult;  
}

/**
    Element accesor
    @param x matrix element
    @return element value
 */
float& 
Matrix4::operator[](Mat4Elem x)
{
    return elem[x];
}

/**
    Element accesor
    @param x matrix element
    @return element value
 */
float& 
Matrix4::operator[](int x)
{
    return elem[x];
}

/**
    Identity matrix
    @return Identity matrix
 */
Matrix4 
Matrix4::identity()
{
    Matrix4 m;
    for (int i=0; i<4; i++)
    {
        m[i*4 + i] = 1.0;
    }
    return m;
}

/**
    Translation matrix
    @param x x translation
    @param y y translation
    @param z z translation
    @return 4x4 matrix representing the given translation
 */
Matrix4 
Matrix4::translate(float x, float y, float z)
{
    Matrix4 m = identity();
    m[MAT4_14] = x;
    m[MAT4_24] = y;
    m[MAT4_34] = z;
    return m;
}

/**
    Rotation along the x axis
    @param radians rotation angle
    @return 4x4 matrix representing a rotation of <a>radians</a> along x
 */
Matrix4
Matrix4::rotateX(float radians)
{
    float c = cos(radians);
    float s = sin(radians);
    
    Matrix4 m = identity();
    m[MAT4_22] = c;
    m[MAT4_32] = s;
    m[MAT4_23] = -s;
    m[MAT4_33] = c;
    return m;
}

/**
    Rotation along the y axis
    @param radians rotation angle
    @return 4x4 matrix representing a rotation of <a>radians</a> along y
 */
Matrix4 
Matrix4::rotateY(float radians)
{
    float c = cos(radians);
    float s = sin(radians);
    
    Matrix4 m = identity();
    m[MAT4_11] = c;
    m[MAT4_13] = -s;
    m[MAT4_13] = s;
    m[MAT4_33] = c;
    return m;
}

/**
    Rotation along the z axis
    @param radians rotation angle
    @return 4x4 matrix representing a rotation of <a>radians</a> along z
 */
Matrix4 
Matrix4::rotateZ(float radians)
{
    float c = cos(radians);
    float s = sin(radians);
    
    Matrix4 m = identity();
    m[MAT4_11] = c;
    m[MAT4_21] = s;
    m[MAT4_12] = -s;
    m[MAT4_22] = c;
    return m;
}

/**
    Rotation matrix from quaternion
    @param q quaternion 
    @return 4x4 matrix representing quaternion rotation
 */
Matrix4 
Matrix4::rotateQua(const Quaternion& q)
{
    // rotation matrix in row major order
    float* rot3 = q.rotationMatrix3x3();
    
    Matrix4 m;
    for(int i=0; i<3; i++)
        for(int j=0; j<3; j++)
        {
            m[j*4 + i] = rot3[i*3 + j]; 
        }
    m[MAT4_44] = 1.0;
    return m;
}


/**
    Orthographic projection matrix
    @param left left border of the near area
    @param right right border of the near area
    @param bottom bottom border of the near area
    @param top top border of the near area
    @param near start of the depth of field
    @param far end of the depth of field
    @return ortographic camera matrix
 
    The rectanle formed by <a>left</a>, <a>right</a>, <a>bottom</a> and <a>top</a>
    will be size of the visible image area.
 */
Matrix4 
Matrix4::orthographic(float left, float right, float bottom, float top, float near, float far)
{
    Matrix4 m;
    
    float r_l = right - left;
	float t_b = top - bottom;
	float f_n = far - near;
	float tx = - (right + left) / (right - left);
	float ty = - (top + bottom) / (top - bottom);
	float tz = - (far + near) / (far - near);
    
	m.elem[0] = 2.0f / r_l;
	m.elem[1] = 0.0f;
	m.elem[2] = 0.0f;
	m.elem[3] = 0.0f;
	
	m.elem[4] = 0.0f;
	m.elem[5] = 2.0f / t_b;
	m.elem[6] = 0.0f;
	m.elem[7] = 0.0f;
	
	m.elem[8] = 0.0f;
	m.elem[9] = 0.0f;
	m.elem[10] = -2.0f / f_n;
	m.elem[11] = 0.0f;
	
	m.elem[12] = tx;
	m.elem[13] = ty;
	m.elem[14] = tz;
	m.elem[15] = 1.0f;
    
    return m;
}

/**
    Project 3D vector
    @param v vector to project
    @return projected vector
 
    Transforms the given vector to homogeneous coordinates, multiplies it by this 
    matrix and turns it back to 3D.
 */
Vector3 
Matrix4::projectVector(const Vector3 v) const
{
    float x, y, z, w;
    x = elem[MAT4_11]*v.x + elem[MAT4_12]*v.y + elem[MAT4_13]*v.z + elem[MAT4_14];
    y = elem[MAT4_21]*v.x + elem[MAT4_22]*v.y + elem[MAT4_23]*v.z + elem[MAT4_24];
    z = elem[MAT4_31]*v.x + elem[MAT4_32]*v.y + elem[MAT4_33]*v.z + elem[MAT4_34];
    w = elem[MAT4_41]*v.x + elem[MAT4_42]*v.y + elem[MAT4_43]*v.z + elem[MAT4_44];
    return Vector3(x/w, y/w, z/w);
}

