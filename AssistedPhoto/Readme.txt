This folder contains the Xcode project and source code of our assisted photography application. This app is a prototype and, as such, is only meant to demo our assisted photography framework. 

How does the app work?
=====================

The application is meant to be used while holding the phone verically. It can operate in two modes: simulated pinhole camera, or assisted photography. The former relies on the intertial sensors inside the phone, and is meant for testing camera aiming. The latter processes images from the back camera in the phone, and tries to guide the user towards centering the estimated region of interest in the composition. You can change in which mode the application operates by going to Settings->AssistedPhoto->Estimator.

In general, the application behaves as follows:

1) When the application is opened, it first waits for users to tap the screen (indicating that he/she is ready to take a picture)
2) The system will process the first image captured afterwards, and will estimate a region of interest based on visual saliency
3) The system will then suggest a new center for the image (ball marker) and wait for the user to center this region in the middle of the composition
4) If audio feedback is enabled, the system will provide audio guidance to help users re-aim the camera
5) The application will stop the interactive aiming phase when the suggested center is positioned in the middle of the composition, the application fails to track it, or the user has taken too long to improve the picture
6) Once the application stops processing new frames, the best one captured so far will be presented to the user and saved into the camera roll (if permissions were given to the app)
7) To take a new picture, you should close and open up the app again

NOTE: If the phone was held vertically, but slightly tilted, the application will automatically correct the extra rotation. 

Full rational of how the app works can be found in:

Marynel Vazquez, Aaron Steinfeld. "Helping visually impaired users properly aim a camera". Proceedings of the 14th international ACM SIGACCESS Conference on Computers and Accessibility, 2012

More details about how the region of interest is estimated are in:

Marynel Vazquez, Aaron Steinfeld. "An assisted photography method for street scenes". IEEE Workshop on Applications of Computer Vision (WACV), 2011.


Settings
========

The settings of the application include:

Estimator: application mode (as explained above)
Acceptance Distance: Minimimum distance at which the suggested center has to be from the middle of the composition for the app to say that the user has centered the target
Sound Type: Audio feedback (silent, piano, piano beep, speech)


Audio feedback
==============



 
