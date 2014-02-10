//
//  RenderView.m
//  Framework-See
//
//  Created by Marynel Vazquez on 11/1/11.
//  Copyright (c) 2011 Robotics Institute. Carnegie Mellon University. All rights reserved.
//

#import "RenderView.h"
#import <GLVision/GLVCommon.h>
#import <Accelerate/Accelerate.h>
#import <See/ImageConversion.h>
#import <See/ImageMotion.h>
#import <See/ImageBlurriness.h>
#import <DataLogging/DLTiming.h>

inline float maxi(int a, int b){ return (a > b ? a : b); }
inline float mini(int a, int b){ return (a < b ? a : b); }


#define TIME_FEATURE_COMPUTATION
#define TIME_FEATURE_DATA_EXTRACTION
#define TIME_FEATURE_DATA_COPYING

static Matrix4 projection;
static Matrix4 resizeProjection;

@implementation RenderView
@synthesize delegate;
@synthesize pResize;
@synthesize pScreenRender;
@synthesize resetWhenPossible;
@synthesize doNotProcess;

- (id) initWithFrame:(CGRect)frame maxProcessingSize:(GLVSize)maxSize
{
    self = [super initWithFrame:frame maxProcessingSize:maxSize]; 
    if (self)
    {        
        // set up template tracker data
        [self setUpTracker];
        
        // set up rectangled to be rendered
        [self setUpBufferObjects];
        
        //        glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
        
        self.pResize = [[GLVProgramGray alloc] init];
        if (!self.pResize)
        {
            NSLog(@"ERROR: Could not set up texture program shader to resize image.");
            self = nil;
            return self;            
        }
        [self.pResize useProgram];
        [self.pResize enableAttributes];
        pResize_attr_position = [self.pResize attributeWithIndex:PROG_TEXTURE_ATTR_POSITION];
        pResize_attr_texCoord = [self.pResize attributeWithIndex:PROG_TEXTURE_ATTR_TEXCOORD];
        pResize_uni_projection = [self.pResize uniformWithIndex:PROG_TEXTURE_UNI_PROJECTION];
        pResize_uni_texture = [self.pResize uniformWithIndex:PROG_TEXTURE_UNI_TEXTURE];
        
        resizeProjection = Matrix4::orthographic(0, self.maxProcessingSize.width, 
                                                 self.maxProcessingSize.height, 0, 0, 1);
        
        resizeTexture.textureID = 0;
        resizeTexture.size = self.maxProcessingSize;
        glActiveTexture(GL_TEXTURE0);
        glGenTextures(1, &(resizeTexture.textureID));
        glBindTexture(GL_TEXTURE_2D, resizeTexture.textureID);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RED_EXT, (int)(resizeTexture.size.width), (int)(resizeTexture.size.height),
                     0, GL_RED_EXT, GL_UNSIGNED_BYTE, NULL);
        
        // creates and links the screen renderer program
        self.pScreenRender = [[GLVProgramTexture alloc] init];
        if (!self.pScreenRender)
        {
            NSLog(@"ERROR: Could not set up texture program shader to render on screen.");
            self = nil;
            return self;
        }
        [self.pScreenRender useProgram];
        [self.pScreenRender enableAttributes];
        pScreenRender_attr_position = [self.pScreenRender attributeWithIndex:PROG_TEXTURE_ATTR_POSITION];
        pScreenRender_attr_texCoord = [self.pScreenRender attributeWithIndex:PROG_TEXTURE_ATTR_TEXCOORD];
        pScreenRender_uni_projection = [self.pScreenRender uniformWithIndex:PROG_TEXTURE_UNI_PROJECTION];
        pScreenRender_uni_texture = [self.pScreenRender uniformWithIndex:PROG_TEXTURE_UNI_TEXTURE];
        //        [self.pScreenRender enableAttributes];
        //        [self.glvEngine storeProgramHandler:programTexture];
        
        projection = Matrix4::orthographic(0, self.frame.size.width, self.frame.size.height, 0, 0, 1); 
        
    }
    return self;
}

- (void) dealloc
{
    if (resizeTexture.textureID)
        glDeleteTextures(1, &(resizeTexture.textureID));
    if (prevIm != 0) 
        free(prevIm);
}

- (void) setUpBufferObjects
{
    viewRect = 0, viewRectIdx = 0;
    [GLVEngine setUpGenericRectTexWithSize:self.frame.size origin:CGPointMake(0,0) 
                                     array:&viewRect idxElementArray:&viewRectIdx]; 
    //    [GLVEngine setUpGenericRectTexWithSize:CGSizeMake(self.frame.size.width, self.frame.size.width) origin:CGPointMake(0,0) 
    //                                     array:&viewRect idxElementArray:&viewRectIdx]; 
    //    [self.glvEngine storeBufferObjectID:camRect];
    //    [self.glvEngine storeBufferObjectID:rectIdx];  
    
    [GLVEngine setUpGenericRectTexWithSize:CGSizeMake(self.maxProcessingSize.width, self.maxProcessingSize.height) 
                                    origin:CGPointMake(0, 0) 
                                     array:&resizeRect idxElementArray:NULL];
}

- (void) setUpTracker
{
    self.doNotProcess = NO;
    self.resetWhenPossible = NO;
    if (prevIm != 0) free(prevIm);
    prevIm = 0;
    int tempWidth = TEMPLATE_MAX_SIZE; int tempHeight = TEMPLATE_MAX_SIZE;
    templateBox = Rectangle(floor(self.maxProcessingSize.height/2 - tempWidth/2),
                            floor(self.maxProcessingSize.width/2 - tempHeight/2),
                            floor(self.maxProcessingSize.height/2 + tempWidth/2),
                            floor(self.maxProcessingSize.width/2 + tempHeight/2));
}

- (img) intensityFromPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{    
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return 0;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, fboTexture[GLVVSAL_FBO_TEXTURE_1]); 
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, 
                           resizeTexture.textureID, 0); 
    
    glViewport(0, 0, (int)(resizeTexture.size.width), (int)(resizeTexture.size.height));
    
    [self.pResize useProgram];
    
    glBindBuffer(GL_ARRAY_BUFFER, resizeRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, imageRectIdx);
    glVertexAttribPointer(pResize_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pResize_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    
    glUniformMatrix4fv(pResize_uni_projection, 1, 0, resizeProjection.elem);
    
    glActiveTexture(GL_TEXTURE1);
    [self textureFromPixelBuffer:pixelBufferRef pixelFormat:GL_BGRA textureFormat:GL_RGBA];
    // and assign it to saliency features shader uniform
    GLuint pixelBufferTexture = CVOpenGLESTextureGetName(pbTexture);
    glBindTexture(GL_TEXTURE_2D, pixelBufferTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);    
    glUniform1i(pResize_uni_texture, 1); // GL_TEXTURE1
    [GLVEngine glError:GLVDebugFile];
    
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    [GLVEngine glError:GLVDebugFile];
    
    glBindTexture(GL_TEXTURE_2D, 0);
    glUseProgram(0);
    
    GLubyte *resizedData = getRedUByteDataFromFBOTexture(0, 0, resizeTexture.size.width, resizeTexture.size.height);
    [GLVEngine glError:GLVDebugFile];
    
    img resizedImg = (float *)malloc(sizeof(float)*resizeTexture.size.width*resizeTexture.size.height);
    for (int r=0; r<resizeTexture.size.height; r++)
    {   
        GLubyte * src = resizedData + (resizeTexture.size.height - r)*resizeTexture.size.width - 1;
        long srcStride = -1;
        long dstStride = resizeTexture.size.height;
        vDSP_Length length = resizeTexture.size.width;
        vDSP_vfltu8(src, srcStride, resizedImg + r, dstStride, length);
    }
    
    free(resizedData);
    return resizedImg;
}

- (unsigned char*) trackTemplate:(img)nextIm
{
    
    size_t imSize = resizeTexture.size.width*resizeTexture.size.height;
    
    img nextImNorm = (float *)malloc(sizeof(float)*imSize);
    cblas_scopy(imSize, nextIm, 1,  nextImNorm, 1);
    see_scaleTo(nextImNorm, imSize, 1.0);
    
    img templateIm = 0; Rectangle templateRect;
    img trackedIm = 0; Rectangle trackedRect;
    
    if (prevIm == 0) { prevIm = nextImNorm; }
    else if (!self.doNotProcess)
    {
    
        Vector2 motion(0,0);
        TRACKINGRESULT trackingResult;
        size_t templateWidth = resizeTexture.size.height, templateHeight = resizeTexture.size.width;
//        img gradX = 0;
        
        trackingResult = see_FlexibleLKTemplateMatching(templateWidth, templateHeight, prevIm, nextImNorm, templateBox, 
                                                        0.4, motion, 0, 0, TEMPLATE_EPSILON, TEMPLATE_MAX_ITER, 0, 0, 
                                                        &templateIm, &templateRect, &trackedIm, &trackedRect);
//        trackingResult = see_PyramidalLKTemplateMatching(templateWidth, templateHeight, prevIm, nextImNorm, templateBox, 
//                                                         PYRAMID_LEVELS, motion, 0, 0, TEMPLATE_EPSILON, TEMPLATE_MAX_ITER, 0, 0);        
//        trackingResult = see_LKPyramidalLK(templateWidth, templateHeight, prevIm, nextImNorm,
//                                           templateBox, PYRAMID_LEVELS, motion,
//                                           0, TEMPLATE_EPSILON, TEMPLATE_MAX_ITER, 0, 0);
        
        if (trackingResult != TRACKING_OK)
        {
            self.doNotProcess = YES;
            
            NSLog(@"Tracking result = %d", trackingResult);
            free(nextImNorm);
            
            NSString *message;
            switch (trackingResult) {
                case TRACKING_EMPTY:
                    message = @"Empty template.";
                    break;
                case TRACKING_OUTSIDEBOUNDS:
                    message = @"Template went outside bounds.";
                    break;
                case TRACKING_STOPPEDBYBOUNDS:
                    message = @"Don't know how to handle bounds.";
                    break;
                default:
                    message = @"?";
                    break;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSObject *del = (NSObject*)self.delegate;
                if ([del respondsToSelector:@selector(alertTrackingFailure:)])
                {
                    [self.delegate alertTrackingFailure:message];
                }
            });
//            [self setUpTracker];   
        }
        else 
        {
            templateBox.origin.x += motion.x;
            templateBox.origin.y += motion.y;
            
            free(prevIm);
            prevIm = nextImNorm;
        }
        
//        if (gradX != 0)
//        { // show normalized gradient image
//            see_scaleTo(gradX, int(templateBox.width()+6)*int(templateBox.height()+6), 255);
//            for (int r = 0; r < templateBox.height() + 6; r++)
//            {
//                img gradAddr = gradX + int(r*(templateBox.width() + 6));
//                cblas_scopy(templateBox.width() + 6, gradAddr, 1, 
//                            nextIm + r*resizeTexture.size.height, 1);
//            }
//            free(gradX);
//        }
        
    }
    
    // use non-normalized nextIm for display
    unsigned char* nextImRGB = see_floatArrayToUCharRGB(nextIm, resizeTexture.size.width*resizeTexture.size.height);
    if (templateIm != 0)
    {
        see_scaleTo(templateIm, int(templateRect.width()*templateRect.height()), 255.0);
//        NSLog(@"templateRect %f %f %f %f", templateRect.origin.x, templateRect.origin.y, templateRect.width(), templateRect.height());
        for(int r=0; r<templateRect.height(); r++)
        {
            vDSP_vfixru8(templateIm + int(r*templateRect.width()),1,nextImRGB + r*int(resizeTexture.size.height)*3    ,3,int(templateRect.width()));
            vDSP_vfixru8(templateIm + int(r*templateRect.width()),1,nextImRGB + r*int(resizeTexture.size.height)*3 + 1,3,int(templateRect.width()));
            vDSP_vfixru8(templateIm + int(r*templateRect.width()),1,nextImRGB + r*int(resizeTexture.size.height)*3 + 2,3,int(templateRect.width()));
        }
        // how blur?
        float b = perceptualBlurMetric(templateIm, int(templateRect.width()), int(templateRect.height()), 
                                       int(templateRect.width()), FILTER_AVERAGE3, FSIZE_AVERAGE3);
        NSLog(@"Blurriness: %f",b);
        
        free(templateIm); templateIm = 0;
        
        if (trackedIm != 0)
        {
            see_scaleTo(trackedIm, int(trackedRect.width()*trackedRect.height()), 255.0);
            for(int r=0; r<trackedRect.height(); r++)
            {
                vDSP_vfixru8(trackedIm + int(r*trackedRect.width()),1,nextImRGB + int(templateRect.width()*3) + r*int(resizeTexture.size.height)*3    ,3,int(trackedRect.width()));
                vDSP_vfixru8(trackedIm + int(r*trackedRect.width()),1,nextImRGB + int(templateRect.width()*3) + r*int(resizeTexture.size.height)*3 + 1,3,int(trackedRect.width()));
                vDSP_vfixru8(trackedIm + int(r*trackedRect.width()),1,nextImRGB + int(templateRect.width()*3) + r*int(resizeTexture.size.height)*3 + 2,3,int(trackedRect.width()));
            }
            
            free(trackedIm); trackedIm = 0;
        }
    }
    
    
//    std::cout << templateBox;// << std::endl;
    unsigned char red = 255;
    int top = int(templateBox.top())*int(resizeTexture.size.height)*3, 
        bottom = int(templateBox.bottom())*int(resizeTexture.size.height)*3,
        left = maxi(int(templateBox.left()), 0),
        right = mini(int(templateBox.right()),resizeTexture.size.height - 1);
    
    if (top >= 0 && top < resizeTexture.size.height*resizeTexture.size.width*3)
        for (int c=left; c<right; c++) 
        {
            nextImRGB[c*3 + top] = red;
//            nextImRGB[c*3 + top + 1] = 0;
//            nextImRGB[c*3 + top + 2] = 0;
        }
    
    if (bottom >= 0 && bottom < resizeTexture.size.height*resizeTexture.size.width*3)
        for (int c=left; c<right; c++) 
        {
            nextImRGB[c*3 + bottom] = red;
//            nextImRGB[c*3 + bottom + 1] = 0;
//            nextImRGB[c*3 + bottom + 2] = 0;
        }
            
    // color on image...
    top = maxi(int(templateBox.top()), 0);
    bottom = mini(int(templateBox.bottom()), resizeTexture.size.width - 1);
    left = int(templateBox.left())*3;
    right = int(templateBox.right())*3;
    
    if (left >= 0 && left < resizeTexture.size.height*3)
        for (int r=top; r<bottom; r++)
        {
            nextImRGB[r*int(resizeTexture.size.height)*3 + left] = red;
            nextImRGB[r*int(resizeTexture.size.height)*3 + left + 1] = 0;
            nextImRGB[r*int(resizeTexture.size.height)*3 + left + 2] = 0;
        }
    
    if (right >= 0 && right < resizeTexture.size.height*3)
        for (int r=top; r<bottom; r++) 
        {
            nextImRGB[r*int(resizeTexture.size.height)*3 + right] = red;
            nextImRGB[r*int(resizeTexture.size.height)*3 + right + 1] = 0;
            nextImRGB[r*int(resizeTexture.size.height)*3 + right + 2] = 0;
        }
    // end color on image
    
    return nextImRGB;
}

- (void) renderRGBImage:(unsigned char *)image width:(int)width height:(int)height
{
    if (![EAGLContext setCurrentContext:self.eaglContext])
    {
        GLVDebugLog(@"ERROR: Could not set up EAGLContext to process camera image.");
        return;
    }
    
    GLuint imageID;
    
    // set up the view
    glBindFramebuffer(GL_FRAMEBUFFER, fboScreen);
    glClearColor(1.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [GLVEngine glError:GLVDebugFile];
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    [GLVEngine glError:GLVDebugFile];
    
    [self.pScreenRender useProgram];
    
    // construct image texture
    glActiveTexture(GL_TEXTURE2);
    glGenTextures(1, &imageID);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, imageID);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB,  width,  height, 0, GL_RGB,
                 GL_UNSIGNED_BYTE, image);
    
    // pass texture uniform
    glUniform1i(pScreenRender_uni_texture, 0); // GL_TEXTURE0
    [GLVEngine glError:GLVDebugFile];
    
    // pass projection uniform
    glUniformMatrix4fv(pScreenRender_uni_projection, 1, 0, projection.elem);
    [GLVEngine glError:GLVDebugFile];
    
    // pass vertex shader attributes
    glBindBuffer(GL_ARRAY_BUFFER, viewRect);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, viewRectIdx);
    glVertexAttribPointer(pScreenRender_attr_position, 3, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), 0); //@todo try offsetof(structure, variable)
    glVertexAttribPointer(pScreenRender_attr_texCoord, 2, GL_FLOAT, 
                          GL_FALSE, sizeof(Vertex3Tex), (GLvoid *)(sizeof(float)*3));
    [GLVEngine glError:GLVDebugFile];
    
    // draw image
    glDrawElements(GL_TRIANGLES, 6 /* we have 2 triangles per rect */, GL_UNSIGNED_BYTE, 0);
    [GLVEngine glError:GLVDebugFile];
    
    glBindTexture(GL_TEXTURE_2D, 0);   
    [GLVEngine glError:GLVDebugFile];
    
    glDeleteTextures(1, &imageID);
    
    // present rendered buffer on screen
    glBindRenderbuffer(GL_RENDERBUFFER, rbColorScreen);
    [self.eaglContext presentRenderbuffer:GL_RENDERBUFFER];     
    [GLVEngine glError:GLVDebugFile];
}


- (void) processPixelBufferRef:(CVPixelBufferRef)pixelBufferRef
{
    if (resetWhenPossible) [self setUpTracker];
    
    // get intensity image
    img nextIm = [self intensityFromPixelBufferRef:pixelBufferRef];
    // convert to float img
    unsigned char* rgbIm = [self trackTemplate:nextIm];
    // release nextIm (relevant copies are made in trackTemplate)
    free(nextIm);
    
    // display
    if (rgbIm != 0)
    {
        [self renderRGBImage:rgbIm 
                       width:resizeTexture.size.height 
                      height:resizeTexture.size.width];
    
        free(rgbIm);
    }
}

@end
