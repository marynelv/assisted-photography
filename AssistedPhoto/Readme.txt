This folder contains the Xcode project and source code of our assisted photography application. This app is a prototype and, as such, is only meant to demo our assisted photography framework. 

How does the app work?
=====================

The application is meant to be used while holding the phone vertically. It can operate in two modes: simulated pinhole camera, or assisted photography. The former relies on the inertial sensors inside the phone, and is meant for testing camera aiming. The latter processes images from the back camera in the phone, and tries to guide the user towards centering the estimated region of interest in the composition. You can change in which mode the application operates by going to Settings->AssistedPhoto->Estimator.

In general, the application behaves as follows:

1) When the application is opened, it first waits for users to tap the screen (indicating that he/she is ready to take a picture)
2) The system will process the first image captured afterwards, and will estimate a region of interest based on visual saliency
3) The system will then suggest a new center for the image (ball marker) and wait for the user to center this region in the middle of the composition
4) If audio feedback is enabled, the system will provide audio guidance to help users re-aim the camera
5) The application will stop the interactive aiming phase when the suggested center is positioned in the middle of the composition, the application fails to track it, or the user has taken too long to improve the picture
6) Once the application stops processing new frames, the best one captured so far will be presented to the user and saved into the camera roll (if permissions were given to the app)
7) To take a new picture, you should close and open up the app again

NOTE: If the phone was held vertically, but slightly tilted, the application will automatically correct the extra rotation. 

More details about our interactive aiming phase can be found in:

Marynel Vazquez, Aaron Steinfeld. "Helping visually impaired users properly aim a camera". Proceedings of the 14th international ACM SIGACCESS Conference on Computers and Accessibility, 2012

Our region of interest approach is detailed in:

Marynel Vazquez, Aaron Steinfeld. "An assisted photography method for street scenes". IEEE Workshop on Applications of Computer Vision (WACV), 2011.


Settings
========

The settings of the application include:

Estimator: application mode (as explained above)
Acceptance Distance: Minimum distance at which the suggested center has to be from the middle of the composition for the app to say that the user has centered the target
Sound Type: Audio feedback (silent, piano, piano beep, speech)


Audio feedback
==============

Speech: Spoken words provide information about the relative orientation of the suggested center with respect to the middle, as well as the distance between the two. The system repeatedly speaks "up", "down", "left" or "right" to indicate orientation, depending on whether the suggested center is located in the upper part of the image, the lower part, etc. Words are spoken with different pitch as a cue on how close the suggested center is to the middle. Higher pitch means closer.

Piano: The pitch of a looping tone indicates distance from the suggested center to the middle of the image. Higher pitch means closer as before. No orientation information is provided.

Piano Beep: Same as above, but the tone is not continuous.

Silent feedback: The system lets the user capture the scene continuously, without providing any audible guidance.


Logging
======= 

By default, the application logs a lot of data (images, intertial measurements, etc). Most of this can be disabled by commenting the definition of LOG_EXPERIMENT_DATA in AssistedPhoto/AssistedPhotographyTargetEstimator.h
