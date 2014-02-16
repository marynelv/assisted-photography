#!/bin/bash

# Automatically compile all frameworks.
# Author: Marynel Vazquez (marynel@cmu.edu)
# Creation Date: 02/16/14
#
#    This work was developed under the Rehabilitation Engineering Research 
#    Center on Accessible Public Transportation (www.rercapt.org) and is funded 
#    by grant number H133E080019 from the United States Department of Education 
#    through the National Institute on Disability and Rehabilitation Research. 
#    No endorsement should be assumed by NIDRR or the United States Government 
#    for the content contained on this code.
#
#    Permission is hereby granted, free of charge, to any person obtaining a copy
#    of this software and associated documentation files (the "Software"), to deal
#    in the Software without restriction, including without limitation the rights
#    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#    copies of the Software, and to permit persons to whom the Software is
#    furnished to do so, subject to the following conditions:
#
#    The above copyright notice and this permission notice shall be included in
#    all copies or substantial portions of the Software.
#
#    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#    THE SOFTWARE.
#

# Run build aggregate on each framework..

cd src/Framework-AudioFeedback
xcodebuild -project Framework-AudioFeedback.xcodeproj -target "Build AudioFeedback" -configuration Release
cd -

cd src/Framework-BasicMath
xcodebuild -project BasicMath.xcodeproj -target "Build BasicMath" -configuration Release
cd -

cd src/Framework-DataLogging
xcodebuild -project Framework-DataLogging.xcodeproj -target "Build DataLogging" -configuration Release
cd -

cd src/Framework-GLVision
xcodebuild -project Framework-GLVision.xcodeproj -target "Build GLVision" -configuration Release
cd -

cd src/Framework-See
xcodebuild -project Framework-See.xcodeproj -target "Build See" -configuration Release
cd -





