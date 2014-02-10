//
//  GLView.h
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

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GLVProgramHandler.h"
#import "GLVEngine.h"


/**
    OpenGLES 2.0 view
    Base view for any OpenGL render. Includes one frame buffer and one color render buffer (linked with EAGLContext).
    Subclasses should configure the following to render:
    <ul>
        <li>glvEngine (frame buffers, render buffers, textures, etc)</li>
        <li>attributes and uniforms (to be passed to the programs in glvEngine)</li>
        <li>render methods</li>
    </ul>
 */
@interface GLVView : UIView
{
    GLuint rbColorScreen;   //!< render buffer object to render on screen
    GLuint fboScreen;       //!< frame buffer object to render on screen
}

@property (nonatomic, retain) GLVEngine *glvEngine;                 //!< OpenGLES 2 vision engine
@property (nonatomic, retain) CAEAGLLayer *eaglLayer;               //!< rendered layer
@property (nonatomic, retain) EAGLContext *eaglContext;             //!< EAGL context

-(GLuint) mainFrameBuffer;
-(GLuint) colorRenderBuffer;


@end
