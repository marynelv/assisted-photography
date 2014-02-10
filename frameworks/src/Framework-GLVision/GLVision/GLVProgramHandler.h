//
//  GLProgramHandler.h
//  AudiballMix
//
//    Created by Marynel Vazquez on 10/1/11.
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

#import <Foundation/Foundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <QuartzCore/QuartzCore.h>
#import "GLVCommon.h"

/**
    OpenGLES 2.0 program handler
 */
@interface GLVProgramHandler : NSObject 
{
    GLuint program;
    GLuint vertexShader;
    GLuint fragmentShader;
}

-(id) initWithVertexShaderFilename:(NSString *)vertexShaderFilename fragmentShaderFilename:(NSString *)fragmentShaderFilename;
-(void) dealloc;
-(GLint) attributeIndex:(const GLchar *)attributeName;
-(GLint) uniformIndex:(const GLchar *)uniformName;
-(BOOL) linkProgamAndValidate:(BOOL)validate;
-(BOOL) isProgramLinked;
-(void) useProgram;
-(NSString *)vertexShaderLog;
-(NSString *)fragmentShaderLog;
-(NSString *)programLog;

+(GLVProgramHandler *) setUpGLProgramWithVertexShader:(NSString *)vertexShaderFileName fragmentShader:(NSString *)fragmentShaderFileName;

@end

// To be implemented by subclasses...
@interface GLVProgramHandler (Virtual)

-(int) allAttributeIndices:(GLuint **)indices;
-(int) allUniformIndices:(GLuint **)indices;
-(GLuint) attributeWithIndex:(int)index;
-(GLuint) uniformWithIndex:(int)index;
-(void) enableAttributes;
-(void) disableAttributes;
-(void) renderToTextureStorage:(GLuint*)storage size:(CGSize*)size;

@end
