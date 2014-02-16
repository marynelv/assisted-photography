[Frameworks] 

Basic Math: basic math operations
Data Logging: logging routines
Audio Feedback: audio feedback and sample sound files
GL Vision: OpenGL-based low-level vision operations 
See: CPU-based vision operations

[Extra applications]

The above xcode projects include some applications to test individual components:

AudioFeedback/TestAudioFeedback: Test audio feedback. Use a clock-wise rotation gesture to change audio mode.
GLVision/GLVTest: Test OpenGL rendering and grayscale image conversion
GLVision/GLVFeatures: Test OpenGL-based feature computation for image saliency
See/TestCamera: Test getting camera data
See/TestPyramid: Test constructing image pyramid
See/TestTemplateTracking: Test template tracking
See/FrameRecording: Test recoding image data
See/Blurry: Test image blur estimation

[NOTE]

The latest version of the code was updated for iOS 7, and tested on an iPhone 5. We did not check for backward compatibility with iOS6. You will probably have to adjust compilation targets to run our apps for the latter.
