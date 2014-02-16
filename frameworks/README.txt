This folder contains the main building blocks of the assisted photography application, split into various frameworks. If all you want to do is compile the frameworks so that you can run the Assisted Photography app, then try running the "compile.sh" bash script that is in this folder.

[Content]

frameworks - frameworks folder for built libraries
src - xcode projects with source code
compile.sh - script that compiles the frameworks in the "src" directory into the "frameworks" folder

[Compile]

The Assisted Photography application looks for frameworks inside the "frameworks" folder. To compile the source code, you can use  the compile.sh script to automatically build the source code, package it, and copy it over the "frameworks" folder. Alternatively, you can manually open each of the Xcode projects in the src directory, and run the build aggregate target (named as "Build X", with X the framework name).

[Extras]

There are additional testing apps for the iPhone inside the framework projects. See the README.txt file in the "src" directory for more imformation.

