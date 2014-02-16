Assisted Photography
====================

This repository contains the assisted photography application of the RERC-APT lab at Carnegie Mellon University (http://www.rercapt.org). The goal of this work was to enable assisted photography for people who would normally have trouble taking a picture due to a visual impairment.

The code was developed for iOS6, and was updated to run on iOS7. After the update, the code was not tested for backward compatibility with iOS6, but it should compile for that target if settings are adjusted appropriately.


[Code organization]

The assisted photography application is in the AssistedPhoto folder. This app relies on the libraries in the frameworks directory, so you should compile them before running AssistedPhoto.


[Quick compilation instructions]

1. Go into the frameworks folder, and run the compile script from the command line: ./compile.sh
2. Go into the AssistedPhoto folder, and open the XCode project
3. Change the Bundle identifier if need to
4. Build the AssistedPhoto target


[Note]

This code is not actively maintained and I can no longer offer support for it. However, it should be fairly easy to get the code running if you program for the iPhone and are familiar with XCode.

[License]

This application and libraries were created by Marynel Vazquez.
Copyright 2014 Carnegie Mellon University.

This work was developed under the Rehabilitation Engineering Research Center on Accessible Public Transportation (www.rercapt.org) and is funded by grant number H133E080019 from the United States Department of Education through the National Institute on Disability and Rehabilitation Research. No endorsement should be assumed by NIDRR or the United States Government for the content contained on this code.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
