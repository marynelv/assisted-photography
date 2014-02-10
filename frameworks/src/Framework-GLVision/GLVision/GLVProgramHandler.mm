//
//  GLProgramHandler.m
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

#import "GLVProgramHandler.h"
#import "GLVEngine.h"

/** Info callback function */
typedef void (*GLInfoFunction)(GLuint program, 
                               GLenum pname, 
                               GLint* params);
/** Log callback function */
typedef void (*GLLogFunction) (GLuint program, 
                               GLsizei bufsize, 
                               GLsizei* length, 
                               GLchar* infolog);

#pragma mark - Private extension

@interface GLVProgramHandler()
-(BOOL) compileShaderFile:(NSString *)file ofType:(GLenum)type withIdentifier:(GLuint *)shader;
-(NSString *)logForOpenGLObject:(GLuint)object infoCallback:(GLInfoFunction)infoFunction logCallback:(GLLogFunction)logFunction;
@end

#pragma mark 

@implementation GLVProgramHandler

/**
    With with vertex and fragment shaders name
    @param vertexShaderName name of vertex shader in the app bundle but without the extension (the extension must be .vsh)
    @param fragmentShaderName name of fragment shader in the app bundle but without the extension (the extension must be .fsh)
    @return Program handler     
    @note If an error occurs, the program handler is still initialized (incompletely) so logs can be checked after...
 */
-(id) initWithVertexShaderFilename:(NSString *)vertexShaderFilename fragmentShaderFilename:(NSString *)fragmentShaderFilename
{    
    if (self = [super init])
    {
        vertexShader = 0;
        fragmentShader = 0;
        program = 0;
        
        // modify path to shaders
        NSString *vertexShaderFullName = [NSString stringWithFormat:@"GLVision.framework/Resources/%@", vertexShaderFilename];
        NSString *fragmentShaderFullName = [NSString stringWithFormat:@"GLVision.framework/Resources/%@", fragmentShaderFilename];
        
        // create OpenGLES 2.0 program
        program = glCreateProgram();
        // set up vertex shader
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *vertexShaderPath = [bundle pathForResource:vertexShaderFullName ofType:@"vsh"];
        if (![self compileShaderFile:vertexShaderPath ofType:GL_VERTEX_SHADER withIdentifier:&vertexShader])
        {
            GLVDebugLog(@"Could not compile vertex shader ('%@'). Please check the file.", vertexShaderFilename);
        }
        
        // set up fragment shader
        NSString *fragmentShaderPath = [bundle pathForResource:fragmentShaderFullName ofType:@"fsh"];
        if (![self compileShaderFile:fragmentShaderPath ofType:GL_FRAGMENT_SHADER withIdentifier:&fragmentShader])
        {
            GLVDebugLog(@"Could not compile fragment shader ('%@'). Please check the file.", fragmentShaderFilename);           
        }
        
        glAttachShader(program, vertexShader);
        glAttachShader(program, fragmentShader);
    }
    return self;
}

/** 
    Release GL objects
    \todo check why delete shader returns either error INVALID_OPERATION or INVALID_VALUE
 */
-(void) dealloc
{
//    NSLog(@"vertex: %u fragment: %u program: %u", vertexShader, fragmentShader, program);
//    
//    GLuint attachedShaders[10] = {0,0,0,0,0,0,0,0,0,0};
//    GLsizei shadersCount = 0;
//    glGetAttachedShaders(program, 10,
//                         &shadersCount,
//                         attachedShaders);
//    for (int i = 0; i<shadersCount; i++)
//    {
//        NSLog(@"Shader %u is attached to program %u", attachedShaders[i], program);
//    }
//    if (shadersCount == 0) NSLog(@"No shaders are attached to program %u", program);
//    
//    [GLVEngine glError:GLVDebugFile];    
//    glUseProgram(0);
//    [GLVEngine glError:GLVDebugFile];
    
    if (vertexShader && fragmentShader){
        glDetachShader(program, vertexShader);
        [GLVEngine glError:GLVDebugFile];
        glDetachShader(program, fragmentShader);
        [GLVEngine glError:GLVDebugFile];
    }
    if (program) {
        glDeleteProgram(program);
    }
//    glDeleteShader(vertexShader);
//    [GLVEngine glError:GLVDebugFile];
//    glDeleteShader(fragmentShader);
//    [GLVEngine glError:GLVDebugFile];

    [GLVEngine glError:GLVDebugFile];
}

/**
    Compile shader file
    @param file shader path in app bundle
    @param type shader type (GL_VERTEX_SHADER or GL_FRAGMENT_SHADER)
    @param shader shader id (output parameter)
    @return <a>TRUE</a> if shader file was compiled successfully
 */
-(BOOL) compileShaderFile:(NSString *)file ofType:(GLenum)type withIdentifier:(GLuint *)shader
{
    NSError *error;
    NSString *shaderString;
    const GLchar *source;
    GLint status;
    
    // load shader string from app bundle
    shaderString = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString)
    {
        GLVDebugLog(@"Error loading shader string from %@: %@", file, error.localizedDescription);
        return FALSE;
    }
                    
    // convert shader string to GLchar
    source = (GLchar *)[shaderString UTF8String];
    
    // create, load and compile shader
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    // return whether or not compilation succeeded
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    return status == GL_TRUE;
}

/**
    Get attribute index
    @param attributeName name of the attribute defined in the vertex shader
    @return attribute index
 */
-(GLint) attributeIndex:(const GLchar *)attributeName
{
    return glGetAttribLocation(program, attributeName);
}

/**
    Get uniform index
    @param uniformName name of the uniform defined in the shaders
    @return uniform index
 */
-(GLint) uniformIndex:(const GLchar *)uniformName
{
    return glGetUniformLocation(program, uniformName);
}

/**
    Link program
    Deletes the shaders if linking succeeds
    @param validate whether or not to validate the program
    @return <a>TRUE</a> if program was linked successfully
 */
-(BOOL) linkProgamAndValidate:(BOOL)validate
{
    GLint status;
    
    // link program
    glLinkProgram(program);
    
    if (validate)
    {
        glValidateProgram(program);
    }
    
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    if (status == GL_FALSE)
    {
        return FALSE;
    }
    
    if (vertexShader)
        glDeleteShader(vertexShader);
    if (fragmentShader) 
        glDeleteShader(fragmentShader);
    
    return TRUE;
}

/**
    Check program linking
    @return is the program linked?
 */
-(BOOL) isProgramLinked
{
    GLint status;
    glGetProgramiv(program, GL_LINK_STATUS, &status);
    return status == GL_TRUE;
}

/**
    Make program active
    This method can be used to switch between different shaders (when various program handlers are in use)
 */
-(void) useProgram
{
    glUseProgram(program);
}

/**
    Get log for OpenGLES 2.0 object
    @param object OpenGLES object
    @param infoFunction information callback function
    @param logFunction log callback function
    @return object log
 */
-(NSString *)logForOpenGLObject:(GLuint)object infoCallback:(GLInfoFunction)infoFunction logCallback:(GLLogFunction)logFunction
{
    GLint logLength = 0;
    
    infoFunction(object, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength < 1)
        return nil;     // no log to retrieve
    
    char *logBytes = new char[logLength];
    logFunction(object, logLength, NULL, logBytes);
    NSString *log = [[NSString alloc] initWithBytes:logBytes length:logLength encoding:NSUTF8StringEncoding];
    delete logBytes;
    
    return log;
}

/**
    If linking went wrong, this method informs about the status of the vertex shader
 */
-(NSString *)vertexShaderLog
{
    return [self logForOpenGLObject:vertexShader 
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                        logCallback:(GLLogFunction)&glGetProgramInfoLog];
}

/**
    If linking went wrong, this method informs about the status of the fragment shader
 */
-(NSString *)fragmentShaderLog
{
    return [self logForOpenGLObject:fragmentShader
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                        logCallback:(GLLogFunction)&glGetProgramInfoLog];    
}

/**
    If linking went wrong, this method informs about the status of the program
 */
-(NSString *)programLog
{
    return [self logForOpenGLObject:program 
                       infoCallback:(GLInfoFunction)&glGetProgramiv 
                        logCallback:(GLLogFunction)&glGetProgramInfoLog];
}

/**
 Set up OpenGL ES 2.0 program (and links shaders)
 @param programHandler program handler
 @param vertexShaderFileName vertex shader file name (without extension - assumed to be .vsh -)
 @param fragmentShaderFileName fragment shader file name (without extension - assumed to be .fsh -)
 @return ProgramHandler if program was successfully created and linked
 @note The newly created program is released if it cannot be linked
 */
+(GLVProgramHandler *) setUpGLProgramWithVertexShader:(NSString *)vertexShaderFileName fragmentShader:(NSString *)fragmentShaderFileName
{
    GLVProgramHandler *programHandler = [[GLVProgramHandler alloc] initWithVertexShaderFilename:vertexShaderFileName 
                                                                         fragmentShaderFilename:fragmentShaderFileName];
    
    if (![programHandler linkProgamAndValidate:YES])
    {
        GLVDebugLog(@"Could not link shaders program.");
        NSString *programLog = [programHandler programLog];
        GLVDebugLog(@"- Program log - %@", programLog);
        NSString *vertexLog = [programHandler vertexShaderLog];
        GLVDebugLog(@"- Vertex Shader log - %@", vertexLog);
        NSString *fragmentLog = [programHandler fragmentShaderLog];
        GLVDebugLog(@"- Fragment Shader log - %@", fragmentLog);
        return nil;
    }
    
    return programHandler;
}

@end

// To be implemented by subclasses...
@implementation GLVProgramHandler (Virtual)

/**
    Array with all attribute indices
    @param indices output parameter with attribute indices
    @return number of elements in attribute indices array
 
    Subclasses must create the array using the new constructor. The particular
    number of attributes to be set depends on their particular implementation.
 
    Seems like a good idea to save the indices somewhere after retrieving them
    for the fist time.
 
    @note Some classes may impose the restriction to not *ever* modify the array 
    to accelerate processing. If this is the case, please specify in the documentation.
 */
-(int) allAttributeIndices:(GLuint **)indices
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                    userInfo:nil];    
}

/**
    Array with all uniform indices
    @param indices output parameter with uniform indices
    @return number of elements in uniform indices array
 
    Subclasses must create the array using the new constructor. The particular
    number of uniforms to be set depends on their particular implementation. 
 
    @note Some classes may impose the restriction to not *ever* modify the array 
    to accelerate processing. If this is the case, please specify in the documentation.

 */
-(int) allUniformIndices:(GLuint **)indices
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]                                 userInfo:nil];    
}

/**
    Get attribute id for a given index in the attributes array
    @param index attribute index in attributes array
    @return attribute id
    @note 0 should be returned by the subclass if <a>index</a> is invalid
 */
-(GLuint) attributeWithIndex:(int)index
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]                                 userInfo:nil];       
}

/**
    Get uniform id for a given index in the uniforms array
    @param index uniform index in attributes array
    @return uniform id
    @note 0 should be returned by the subclass if <a>index</a> is invalid
 */
-(GLuint) uniformWithIndex:(int)index
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]                                 userInfo:nil];   
}

/**
    Enable program attributes
    The attributes depend on the particular subclass implementation
 */
-(void) enableAttributes
{
    [NSException raise:NSInternalInconsistencyException 
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

/**
    Disable program attributes
    The attributes depend on the particular subclass implementation
 */
-(void) disableAttributes
{
    [NSException raise:NSInternalInconsistencyException 
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

/**
    Merge color texture channels into gray image
    @param storage reserved texture space id, or 0 if new texture needs allocation
    @param size storage size (or NULL if storage is 0)

    The parameter <a>storage</a> works as an input/output parameter. When it is NULL or 
    its value is zero, an output texture is created and its id returned. Otherwise,
    it is assumed that the provided texture has been allocated with enough space for
    rendering.
 
    @note Assumes that all attributes and uniforms are set up before rendering
 */
-(void) renderToTextureStorage:(GLuint*)storage size:(CGSize*)size
{
    [NSException raise:NSInternalInconsistencyException 
                format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
}

@end

