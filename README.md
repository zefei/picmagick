Picmagick (www.picmagick.com) is a Flash (ActionScript) based photo editor I programmed in 2008. I wanted it to be a very simple photo editor that people can use for basic functionalities, and I think it isn't bad for that purpose. It was a personal project that gave me the chance to learn image processing and Flash programming, also to give some free utilities back to the community. Over the years, Picmagick gained some popularity but not much, since I never had the time to either improve it or advertise it. Now (end of 2011), after some revisits to this old app, I thought it would be a good time to open source it, since I haven't seen a good embeddable image editor, so here it is.

Source Structure
================

The original project was developed using Flex SDK 3. I refactored the code under SDK 4.5 (using Flash Builder 4.5), since the newer SDK has some improvements on bitmap data handling and performance.

The .mxml files under src/ are front ends that I put there as a demo of the image processing utilities. These files are a bit messy, but they are intended to be modified to whatever you want.

All the .as files under src/picmagick/ are utility classes that you don't have to change: src/picmagick/display contains the main image viewer class DraggableCanvas, and a simple cursor manager used by DraggableCanvas; src/picmagick/graphics contains the image processing utility BitmapDataEx; src/picmagick/utils contains ImageIO, a utility class to open/save image files.

The libs/ folder contains one dependency Picmagick uses: as3_jpeg_wrapper.swc, a fast jpeg encoder using Alchemy and libjpeg, from here: http://segfaultlabs.com/devlogs/alchemy-asynchronous-jpeg-encoding

Future Plan
===========

I do not intend to add any big features to Picmagick in the future, since Flash is dying due to the mobile market, and I'm planning to build a fast embeddable image editor in HTML5 next year (2012). Shortly after Picmagick, I coded a more complete image processing library in Alchemy and C++, and used it to build another app Simplycontrast (www.simplycontrast.com). However, despite the speed Alchemy and C brings, the app performs poorly on platforms other than Windows; and I don't think Flash has any future compared to HTML5.

License
=======

Picmagick is opened under MIT license:

Copyright (C) 2011 by Zefei Xuan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
