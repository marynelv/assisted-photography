This folder contains the main building blocks of the assisted photography application, split into various frameworks.

[Content]

frameworks - frameworks folder for built libraries
src - xcode projects


[Compile]

Each framework has a "Build Aggregate" target that compiles the source code, packages it, and copies it over to the frameworks folder.


[Extras]

There are additional testing apps for the iPhone inside the xcode projects. This allows to test various components of the system independently, 
and evaluate running performance.
