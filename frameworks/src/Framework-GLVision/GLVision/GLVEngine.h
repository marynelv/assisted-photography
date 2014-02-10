//
//  GLVEngine.h
//  Framework-GLVision
//
//    Created by Marynel Vazquez on 10/22/11.
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
#import <QuartzCore/QuartzCore.h>
#import "GLVProgramHandler.h"

/**
    OpenGLES 2 vision engine 
    Encapsulates GL data and helps running the programmable pipeline
    @note Some functions facilitate deleting objects appropriately, but the user has to make sure to call them.
 */
@interface GLVEngine : NSObject

@property (nonatomic, retain) NSMutableArray *frameBuffer;     //!< frame buffer ids
@property (nonatomic, retain) NSMutableArray *renderBuffer;    //!< render buffer ids
@property (nonatomic, retain) NSMutableArray *bufferObject;    //!< render buffer ids
@property (nonatomic, retain) NSMutableArray *texture;         //!< texture ids
@property (nonatomic, retain) NSMutableArray *program;         //!< programs

-(id) initWithFrameBuffer:(GLuint)mainFBO colorRenderBuffer:(GLuint)colorRenderBuffer;

-(NSUInteger) genBufferObjectWithData:(GLvoid *)data size:(GLsizeiptr)size target:(GLenum)target 
                                usage:(GLenum)usage identifier:(GLuint *)identifier;

-(GLuint) frameBufferID:(NSUInteger)idx;
-(GLuint) renderBufferID:(NSUInteger)idx;
-(GLuint) bufferObjectID:(NSUInteger)idx;
-(GLuint) textureID:(NSUInteger)idx;
-(GLVProgramHandler *) programHandler:(NSUInteger)idx;

-(void) storeFrameBufferID:(GLuint)buffer;
-(void) storeRenderBufferID:(GLuint)buffer;
-(void) storeBufferObjectID:(GLuint)buffer;
-(void) storeTextureID:(GLuint)tex;
-(void) storeProgramHandler:(GLVProgramHandler *)programHandler;

-(void) deleteFrameBuffer:(NSUInteger)idx;
-(void) deleteRenderBuffer:(NSUInteger)idx;
-(void) deleteBufferObject:(NSUInteger)idx;
-(void) deleteTexture:(NSUInteger)idx;
-(void) deleteProgramHandler:(NSUInteger)idx;

-(void) deleteFrameBuffers;
-(void) deleteRenderBuffers;
-(void) deleteBufferObjects;
-(void) deleteTextures;
-(void) deletePrograms;

-(void) clear;

@end

@interface GLVEngine (StaticGLHelpers)

+(void) genBufferObjectWithData:(GLvoid *)data size:(GLsizeiptr)size target:(GLenum)target 
                          usage:(GLenum)usage identifier:(GLuint *)identifier;
+(GLuint) setUpGenericRectTexIdx;
+(void) setUpGenericRectTexWithSize:(CGSize)size origin:(CGPoint)origin 
                              array:(GLuint *)rectArray idxElementArray:(GLuint *)idxElemArray;
+(void) setUpGenericRectTexInvWithSize:(CGSize)size origin:(CGPoint)origin 
                                 array:(GLuint *)rectArray idxElementArray:(GLuint *)idxElemArray;
+(BOOL) glError:(NSString*)callingPlace;

@end
