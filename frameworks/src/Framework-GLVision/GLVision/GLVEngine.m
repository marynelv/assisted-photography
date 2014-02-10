//
//  GLVEngine.m
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

#import "GLVEngine.h"
#import "GLVCommon.h"

@implementation GLVEngine
@synthesize frameBuffer;
@synthesize renderBuffer;
@synthesize bufferObject;
@synthesize texture;
@synthesize program;

/**
    Basic constructor
    Initializes the GL arrays
 */
-(id) init
{
    if (self = [super init])
    {
        self.frameBuffer = [[NSMutableArray alloc] init];
        self.renderBuffer = [[NSMutableArray alloc] init];
        self.bufferObject = [[NSMutableArray alloc] init];
        self.texture = [[NSMutableArray alloc] init];
        self.program = [[NSMutableArray alloc] init];
    }
    return self;
}

/**
    Initialize with main frame buffer object and color render buffer
    @param mainFBO frame buffer id
    @param colorRenderBuffer render buffer id
    @return GLVEngine
 
    The frame buffer id is stored in the <a>frameBuffer</a> array, while the render
    buffer id is stored in the <a>bufferObject</a> array. Both id's will be placed at
    position 0.
 
    @note If there is no need to store the frame buffer id or the render buffer, 
    use init constructor without parameters.
 */
-(id) initWithFrameBuffer:(GLuint)mainFBO colorRenderBuffer:(GLuint)colorRenderBuffer
{
    if (self = [super init])
    {
        self.frameBuffer = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithUnsignedInt:mainFBO], nil];
        self.renderBuffer = [[NSMutableArray alloc] initWithObjects:[NSNumber numberWithUnsignedInt:colorRenderBuffer], nil];
        self.bufferObject = [[NSMutableArray alloc] init];
        self.texture = [[NSMutableArray alloc] init];
        self.program = [[NSMutableArray alloc] init];
    }
    return self;
}

/**
    Generate buffer object and store in <a>bufferObject</a> array
    @param data buffer object data
    @param size data size (usually sizeof(data) from calling code)
    @param target target (e.g. GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc)
    @param usage data usage (e.g. GL_STATIC_DRAW, GL_DYNAMIC_DRAW, etc)
    @param identifier object identifier (output parameter)
    @return buffer object position in <a>bufferObject</a> array
 */
-(NSUInteger) genBufferObjectWithData:(GLvoid *)data size:(GLsizeiptr)size target:(GLenum)target 
                                usage:(GLenum)usage identifier:(GLuint *)identifier
{    
    
    GLuint bo;
    [GLVEngine genBufferObjectWithData:data size:size target:target usage:usage identifier:&bo];
    [self storeBufferObjectID:bo];
    
    if (identifier != NULL)
        *identifier = bo;
    
    return [self.bufferObject count];
}

/**
    Get frame buffer identifier
    @param idx frame buffer position in <a>frameBuffer</a> array
    @return FBO identifier
 */
-(GLuint) frameBufferID:(NSUInteger)idx
{
    NSNumber *n = (NSNumber *)[self.frameBuffer objectAtIndex:idx];
    return [n unsignedIntValue];
}

/**
    Get render buffer identifier
    @param idx render buffer position in <a>frameBuffer</a> array
    @return render buffer identifier
 */
-(GLuint) renderBufferID:(NSUInteger)idx
{
    NSNumber *n = (NSNumber *)[self.renderBuffer objectAtIndex:idx];
    return [n unsignedIntValue];    
}

/**
    Get buffer object identifier
    @param idx buffer object position in <a>bufferObject</a> array
    @return buffer object identifier
 */
-(GLuint) bufferObjectID:(NSUInteger)idx
{
    NSNumber *n = (NSNumber *)[self.bufferObject objectAtIndex:idx];
    return [n unsignedIntValue];
}

/**
    Get texture identifier
    @param idx texture position in <a>texture</a> array
    @return texture identifier
 */
-(GLuint) textureID:(NSUInteger)idx
{
    NSNumber *n = (NSNumber *)[self.texture objectAtIndex:idx];
    return [n unsignedIntValue];
}

/**
    Get program handler
    @param idx program handler position in <a>program</a> array
    @return program handler object
 */
-(GLVProgramHandler *) programHandler:(NSUInteger)idx
{
    return (GLVProgramHandler *)[self.program objectAtIndex:idx];
}

/**
    Store program handler for future use
    @param programHandler program handler
 
    ProgramHandler is stored at the end of the <a>program</a> array.
 */
-(void) storeProgramHandler:(GLVProgramHandler *)programHandler
{
    [self.program addObject:programHandler];
}

/**
    Store frame buffer id for future use
    @param buffer frame buffer id

    The id is stored at the end of the <a>frameBuffer</a> array.
 */
-(void) storeFrameBufferID:(GLuint)buffer
{
    [self.frameBuffer addObject:[NSNumber numberWithUnsignedInt:buffer]];
}

/**
    Store render buffer id for future use
    @param buffer render buffer id   
 
    The id is stored at the end of the <a>renderBuffer</a> array.
 */
-(void) storeRenderBufferID:(GLuint)buffer
{
    [self.renderBuffer addObject:[NSNumber numberWithUnsignedInt:buffer]];
}

/**
    Store buffer object id for future use
    @param buffer buffer object id

    The id is stored at the end of the <a>bufferObject</a> array.
*/
-(void) storeBufferObjectID:(GLuint)buffer
{
    [self.bufferObject addObject:[NSNumber numberWithUnsignedInt:buffer]];    
}

/**
    Store texture id for future use
    @param tex texture id
 
    The id is stored at the end of the <a>texture</a> array.
*/
-(void) storeTextureID:(GLuint)tex
{
    [self.texture addObject:[NSNumber numberWithUnsignedInt:tex]];
}

/**
    Delete frame buffer
    @param idx frame buffer position in <a>frameBuffer</a> array
    @note NSRangeException is not catched
 */
-(void) deleteFrameBuffer:(NSUInteger)idx
{
    GLuint buffer = [self frameBufferID:idx];
    glDeleteFramebuffers(1, &buffer);
    [self.frameBuffer removeObjectAtIndex:idx];
}
     
/**
    Delete render buffer
    @param idx render buffer position in <a>renderBuffer</a> array
    @note NSRangeException is not catched
 */
-(void) deleteRenderBuffer:(NSUInteger)idx
{
    GLuint buffer = [self frameBufferID:idx];
    glDeleteRenderbuffers(1, &buffer);
    [self.renderBuffer removeObjectAtIndex:idx];    
}

/**
    Delete buffer object
    @param idx buffer object position in <a>bufferObject</a> array
    @note NSRangeException is not catched
 */
-(void) deleteBufferObject:(NSUInteger)idx
{
    GLuint buffer = [self bufferObjectID:idx];
    glDeleteBuffers(1, &buffer);
    [self.bufferObject removeObjectAtIndex:idx];
}

/**
    Delete texture
    @param idx texture position in <a>texture</a> array
    @note NSRangeException is not catched
 */
-(void) deleteTexture:(NSUInteger)idx
{
    GLuint tex = [self textureID:idx];
    glDeleteTextures(1, &tex);
    [self.texture removeObjectAtIndex:idx];
}

/**
    Delete program handler
    @param idx program handler position in <a>program</a> array
    @note NSRangeException is not catched
 */
-(void) deleteProgramHandler:(NSUInteger)idx
{
    [self.program removeObjectAtIndex:idx];
}

/**
    Delete all GL frame buffers
 */
-(void) deleteFrameBuffers
{
    for (NSNumber *buffNumber in self.frameBuffer)
    { 
        GLuint buffer = [buffNumber unsignedIntValue];
        glDeleteFramebuffers(1, &buffer);        
    }
    [self.frameBuffer removeAllObjects];
}

/** 
    Delete all render buffers
 */
-(void) deleteRenderBuffers
{
    for (NSNumber *buffNumber in self.renderBuffer)
    { 
        GLuint buffer = [buffNumber unsignedIntValue];
        glDeleteRenderbuffers(1, &buffer);        
    }
    [self.renderBuffer removeAllObjects];
}

/**
    Delete all GL buffer objects
 */
-(void) deleteBufferObjects
{
    for (NSNumber *buffNumber in self.bufferObject)
    { 
        GLuint buffer = [buffNumber unsignedIntValue];
        glDeleteBuffers(1, &buffer);        
    }
    [self.bufferObject removeAllObjects];    
}

/**
    Delete all GL textures
 */
-(void) deleteTextures
{
    for (NSNumber *texNum in self.texture)
    { 
        GLuint tex = [texNum unsignedIntValue];
        glDeleteTextures(1, &tex);        
    }
    [self.texture removeAllObjects];    
}

/**
    Delete all GL programs
 */
-(void) deletePrograms
{
    [self.program removeAllObjects];
}

/**
    Deletes all stored frame buffers, buffer objects, textures and programs
 */
-(void) clear
{
    [self deleteFrameBuffers];
    [self deleteBufferObjects];
    [self deleteTextures];
    [self deletePrograms];
}


@end

@implementation GLVEngine (StaticGLHelpers)

/**
    Check for OpenGL error
    @param callingPlace where the error was checked
    @return was there an error?
 */
+(BOOL) glError:(NSString*)callingPlace
{
    BOOL gotError = FALSE;
    GLenum err = glGetError();
    while (err != GL_NO_ERROR)
    {
        gotError = TRUE;
        NSString *errorMsg = nil;
        switch (err) {
            case GL_INVALID_ENUM:
                errorMsg = [NSString stringWithFormat:@"An unacceptable value is specified for an enumerated argument."];
                break;
            case GL_INVALID_VALUE:
                errorMsg = [NSString stringWithFormat:@"A numeric argument is out of range."];
                break;
            case GL_INVALID_OPERATION:
                errorMsg = [NSString stringWithFormat:@"The specified operation is not allowed in the current state."];
                break;
            case GL_OUT_OF_MEMORY:
                errorMsg = [NSString stringWithFormat:@"There is not enough memory left to execute the command. The state of the GL is undefined, except for the state of the error flags, after this error is recorded."];
                break;
            case 0x0506: //GL_INVALID_FRAMEBUFFER_OPERATION_EXT:
                errorMsg = [NSString stringWithFormat:@"GL_INVALID_FRAMEBUFFER_OPERATION_EXT?"];
                break;
            default:
                errorMsg = [NSString stringWithFormat:@"??"];
        }
        
        NSLog(@"ERROR (%@): OpenGL returned error code %d - %@", callingPlace, err, errorMsg);
        err = glGetError();
    }
    return gotError;
}

/**
    Generate buffer object
    @param data buffer object data
    @param size data size (usually sizeof(data) from calling code)
    @param target target (e.g. GL_ARRAY_BUFFER, GL_ELEMENT_ARRAY_BUFFER, etc)
    @param usage data usage (e.g. GL_STATIC_DRAW, GL_DYNAMIC_DRAW, etc)
    @param identifier object identifier (output parameter)
 */
+(void) genBufferObjectWithData:(GLvoid *)data size:(GLsizeiptr)size target:(GLenum)target 
                          usage:(GLenum)usage identifier:(GLuint *)identifier
{    
    GLuint bo;
    glGenBuffers(1, &bo);
    glBindBuffer(target, bo);
    glBufferData(target, size, data, usage);
    
    if (identifier != NULL || identifier != 0)
        *identifier = bo;
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

/**
    Set up generic rectangle index element array
    @return index element array
 
    The buffer object usage mode is set to GL_STATIC_DRAW. This means that the GPU
    expects its values to be used for drawing much, but not to be changed often. Take
    this with caution, as as it can affect performance.
 
    @note This function is usually used in conjunction with @see setUpGenericRectTexWithSize.
 */
+(GLuint) setUpGenericRectTexIdx
{
    GLuint idxElemArray = 0;
    GLubyte rectangleIdx[] = 
    {
        0, 1, 2,
        2, 3, 0
    };
    [GLVEngine genBufferObjectWithData:rectangleIdx size:sizeof(rectangleIdx) 
                                target:GL_ELEMENT_ARRAY_BUFFER usage:GL_STATIC_DRAW 
                            identifier:&idxElemArray];
    return idxElemArray;
}

/**
    Set up a generic rectangle with texture coordinates in Z=0
    @param size rectangle size (width, height)
    @param origin rectangle origin (x,y)
    @param rectArray output parameter with array buffer identifier
    @param idxElemArray output parameter with index element array
 
    Loads a generic rectangle into the GPU for drawing images (loads both the buffer 
    array with the vertices and the element array with the drawing indices). 
    The rectangle vertices include their 3D positions and texture coordinates. 
 
    Both buffer objects usage modes are set to GL_STATIC_DRAW. This means that the GPU
    expects their values to be used for drawing much, but not to be changed often. Take
    this with caution, as as it can affect performance.
    
    We assume that the world view is set up with orthographic projection, such that
    the origin of coordinates resides in the left-top corner. The vertices of
    the rectagle are then constructed as: (x+w, y+h), (x+w,y), (x,y) and (x, y+h).
 
    @note First we load the array buffer with vertex information, and then the element 
    array with the triangle indices. If either <a>rectArray</a> or <a>idxElemArray</a> is NULL, their
    respective buffer object is not created. If <a>rectArray</a> is null, <a>size</a> and 
    <a>origin</a> won't have any effect. In that case, it seems better to use the function 
    <a>setUpGenericRectTexIdx</a>.
 */
+(void) setUpGenericRectTexWithSize:(CGSize)size origin:(CGPoint)origin 
                              array:(GLuint *)rectArray idxElementArray:(GLuint *)idxElemArray
{
    if (rectArray != NULL || rectArray != 0)
    {
        Vertex3Tex rectangle[] = 
        {
            {{origin.x + size.width, origin.y + size.height, 0}, {1,0}},
            {{origin.x + size.width, origin.y, 0}, {0,0}},
            {{origin.x, origin.y, 0}, {0,1}},
            {{origin.x, origin.y + size.height, 0}, {1,1}}
        };
        [GLVEngine genBufferObjectWithData:rectangle size:sizeof(rectangle) 
                                    target:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW 
                                identifier:rectArray];
        NSLog(@"VBA %u = {(%f %f) (%f %f) (%f %f) (%f %f)",
              *rectArray,
              rectangle[0].position[0], rectangle[0].position[1],
              rectangle[1].position[0], rectangle[1].position[1],
              rectangle[2].position[0], rectangle[2].position[1],
              rectangle[3].position[0], rectangle[3].position[1]);

    }
    
    if (idxElemArray != NULL || idxElemArray != 0)
    {
        *idxElemArray = [GLVEngine setUpGenericRectTexIdx];
    }
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

+(void) setUpGenericRectTexInvWithSize:(CGSize)size origin:(CGPoint)origin 
                              array:(GLuint *)rectArray idxElementArray:(GLuint *)idxElemArray
{
    if (rectArray != NULL || rectArray != 0)
    {
        Vertex3Tex rectangle[] = 
        {
            {{origin.x + size.width, origin.y + size.height, 0}, {1,0}},
            {{origin.x + size.width, origin.y, 0}, {1,1}},
            {{origin.x, origin.y, 0}, {0,1}},
            {{origin.x, origin.y + size.height, 0}, {0,0}}
        };
        [GLVEngine genBufferObjectWithData:rectangle size:sizeof(rectangle) 
                                    target:GL_ARRAY_BUFFER usage:GL_STATIC_DRAW 
                                identifier:rectArray];
        NSLog(@"VBA %u = {(%f %f) (%f %f) (%f %f) (%f %f)",
              *rectArray,
              rectangle[0].position[0], rectangle[0].position[1],
              rectangle[1].position[0], rectangle[1].position[1],
              rectangle[2].position[0], rectangle[2].position[1],
              rectangle[3].position[0], rectangle[3].position[1]);
        
    }
    
    if (idxElemArray != NULL || idxElemArray != 0)
    {
        *idxElemArray = [GLVEngine setUpGenericRectTexIdx];
    }
    
#ifdef PERFORM_GL_CHECKS
    [GLVEngine glError:GLVDebugFile];
#endif
}

@end
