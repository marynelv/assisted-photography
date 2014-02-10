//
//  ImageTransformation.cpp
//  Framework-See
//
//  Created by Marynel Vazquez on 12/2/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#include "ImageTransformation.h"
#include <assert.h>

//Transformation2D::Transformation2D(unsigned short size)
//{
//    numElem = size;
//    if (numElem > 0)
//        data = (float*)calloc(numElem, sizeof(float));
//    else
//        data = NULL;
//}
//
//Transformation2D::~Transformation2D()
//{
////    assert(numElem != 0 || data == NULL);
//    if (numElem != 0 && data != NULL) free(data);
//}
//
///**
// Matrix4 elements in column major order
// */
//typedef enum
//{
//    AFFINE_DXX,        //!< 1,1
//    AFFINE_DXY,        //!< 2,1
//    AFFINE_TX,         //!< 3,1
//    AFFINE_DYX,        //!< 4,1
//    AFFINE_DYY,        //!< 1,2
//    AFFINE_TY,         //!< 2,2
//    AFFINE_NUMELEM     //!< number of elements in the matrix
//} AffineTransElem;      
//
//AffineTransformation::AffineTransformation() : Transformation2D(6)
//{
//    setIdentity();
//}
//
//AffineTransformation::~AffineTransformation()
//{}
//
//void 
//AffineTransformation::setIdentity()
//{
//    data[AFFINE_DXX] = 1.0;
//    data[AFFINE_DXY] = 0.0;
//    data[AFFINE_DYX] = 0.0;
//    data[AFFINE_DYY] = 1.0;
//    data[AFFINE_TX]  = 0.0;
//    data[AFFINE_TY]  = 0.0;
//}
//
//bool
//AffineTransformation::isIdentity()
//{
//    return (data[AFFINE_DXX] == 1.0 && data[AFFINE_DXY] == 0.0 &&
//            data[AFFINE_DYX] == 0.0 && data[AFFINE_DYY] == 1.0 &&
//            data[AFFINE_TX]  == 0.0 && data[AFFINE_TY]  == 0.0);
//}
//
//bool 
//AffineTransformation::isAllZeros()
//{
//    return (data[AFFINE_DXX] == 0.0 && data[AFFINE_DXY] == 0.0 &&
//            data[AFFINE_DYX] == 0.0 && data[AFFINE_DYY] == 0.0 &&
//            data[AFFINE_TX]  == 0.0 && data[AFFINE_TY]  == 0.0);    
//}
