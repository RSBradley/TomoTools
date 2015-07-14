Release date: Sep 1, 2005


Contact Info
------------

Send feedback and bug reports to the spam obfuscated e-mail below.

   matthew (underscore) kidd at ghctechnologies dot com


Installation
------------

freadss() is a mex function. Just drop freadss.dll and freadss.m into the same directory. If you want to dump images from PowerPoint files, copy pptimgdump.m as well.


Motivation
----------

freadss() was developed to support directly reading a vendor's proprietary format because that vendor's export capabilities were limited. Due to an NDA, I can not share the vendor specific interface code. Instead, I have included pptimgdump() as an example of how to use the code.


Basic Documentation
-------------------

Type 'help freadss' or 'help pptimgdump' in Matlab.

Technical details on Structured Storage can be found at:

http://msdn.microsoft.com/library/default.asp?url=/library/en-us/stg/stg/structured_storage_reference.asp

A more gentle introduction can be found at:

   http://www.endurasoft.com/vcd/ststo.htm

To help troubleshoot work with Structured Storage I highly recommend the Compound File Explorer, a shareware tool from CoCo available at the URL below:

    http://www.coco.co.uk/developers/CFX.html


Tested Platforms
----------------

freadss() has only been tested on XP but should run on any Win32 platform. It has been tested on Matlab 2006a, Matlab 7 (R14) SP2/SP3, and Matlab 6.5. It will probably work
on Matlab 6.1, 6.0, and possibly even Matlab 5.

pptimgdump() has been tested on files created with PowerPoint and PowerPoint 2003 SP1/SP2.
It  should also work on files created with PowerPoint 2000. pptimgdump() is a dirty hack;
it is exactly the sort of thing one should not do! One should use a published API instead.
But Microsoft has not been forthcoming here.


Unicode Support
---------------

freadss() should be fully Unicode compliant although this has not been rigorously tested. The filename, storage name(s), and stream name(s) are all handled as Unicode without going through any non-Unicode transformations betweeen Matlab and the Windows API calls. Specifically, I have avoided the non-Unicode Matlab API functions mxGetString() and mxCreateString() choosing to manipulated the string copies directly using mxGetPr(). I expect this approach to be stable as the Matlab API evolves, but would prefer to see the Mathworks adds Unicode versions of mxGetString() and mxCreateString().

Matlab 7 (R14) character arrays (strings) are Unicode. This situation prior to Matlab 7 is confusing. An amusing comment in the Matlab header file matrix.h, refers to a "schizophrenic rep(resentation)" when Unicode is not enabled, which I think amounts to Multibyte Character Set (MBCS) under certain circumstances. However, Matlab has always used two bytes per character, exactly like Unicode. So if you simply treat the string as Unicode in Matlab 6.5 or early for the purposes of calling freadss() you should be okay. Consider this in Matlab 6.5

  >>  sname = char( hex2dec( ['0648'; '064e'; '0641'; '0650'; '064a'; '0642'] )' )

  sname =

    HNAPJB

  >> double(sname)

  ans =

        1608  1614  1601  1616  1610  1602

On the display Matlab prints 'HNAPJB', but internally it preserves the Unicode values for the Arabic characters.

Stream data may be interpreted as a standard C string or as Unicode, by choosing 'char' or 'unicode' respectively for the stream class. When interpreted as a C string, the stream data is expanded to two bytes per character in the Matlab character array. When interpreted as unicode it is simply copied.


Quirks
------

Internally, Matlab strings are not terminated with 0x0000 as Unicode strings are because the array object stores the number of elements in the character array. Hence, ['a', char(0), 'b'] is a perfectly legitimate 1x3 character array in Matlab. Thus when interpreting stream data as 'char' or 'unicode', freadss() does not stop reading the stream data when it encounters a 0x00 or 0x0000 respectively. Curiously, Matlab R14 SP2 seems to map nuls 0x0000 to spaces (0x0032) after exiting the mex function. Unable to figure out what was going on, I choose to map nuls to 0x0100 so that they could be distinguished from legitimate space characters.


Limitations
-----------

If you need to read Storages or Streams which contain backslash(es) in their names, you will have to modify the code because it interprets backslashes as separating Storages along the way to the final Storage or Stream.


Compilation
-----------

The freadss.cpp top comment has some notes about how to compile. If you have MSVC, you just have to link in ole32.lib.
