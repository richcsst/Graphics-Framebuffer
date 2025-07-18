# Graphics-Framebuffer

![Graphics::Framebuffer Logo](GFB.png?raw=true "Graphics::Framebuffer")

### Windows Incompatibility

![Windows Incompatible](Win-No.png?raw=true "Windows Incompatible")

Note, this module does NOT work (natively) in Microsoft Windows.  It will only function in "emulation" mode, and you will not see any screen output.  See the documentation on emulation mode for more details.  Use a Virtual Machine like VirtualBox to use on Windows, with a Linux distribution installed.

## PREREQUISITES

This module REQUIRES access to the video framebuffer, usually "/dev/fb0".  You must be using a video device and driver that exposes this device to software.  Video cards with their proprietary drivers are not likely to work.  However, most open-sourced drivers, seem to work fine.  VirtualBox drivers work too.  You must also have the appropriate permissions to write to this device (usually membership with group "video").

Sometimes you can force a VESA framebuffer console driver to be loaded by adding a video mode to the grub command line.  You can do this with some proprietary video drivers that don't have their own framebuffer drivers.

### ATTENTION CPAN TESTERS!  Please make sure the above is noted before testing (and marking a fail)

If you want a more detailed instruction than this document, then read "INSTALL".

I highly recommend you install the system (or package) version of the "Imager" library, as it is already pre-compiled with all the needed C libraries for it to work with this module.  In Yum (RedHat) and Aptitude (Debian/Ubuntu) this module is called "libimager-perl" (or "perl-libImager").  However, if you desire to install it yourself, please do it manually, and not via CPAN.  When you do it manually, you can see the missing C libraries it is looking for in the "Makefile.PL" process and stop it there.  You can then install these libraries until it no longer says something is missing.  You see, it just turns off functionality if it can't find a library (when installing from CPAN), instead of stopping.  Libraries usually missing are those for GIF, JPEG, PNG, TrueType and FreeType fonts.  These are necessary not optional, if you wish to be able to work with fonts and images.

The "build-essential" tools need to be installed. This is generally a C compiler, linker, and standard C libraries (usually gcc variety).  The module "Inline::C", which this module uses, requires it.  Also, the package "kernel-headers".

You should also install typical TTF fonts as well.  I suggest the FreeType fonts, the Windows fonts (fonts-wine), Ubuntu fonts (fonts-ubuntu) and anything else you wish to use.

## INSTALLATION

You SHOULD install this module from the console, not X-Windows.

To make your system ready for this module, then please install the following:

### DEBIAN BASED SYSTEMS (Ubuntu, Mint, Raspian, etc):

```bash
installation/install-prerequisites-debian.sh
```

### REDHAT BASED SYSTEMS (Fedora, CentOS, etc):

```bash
installation/install-prerequisites-redhat.sh
```

You can use the following to detect your distribution type:

```bash
installation/detect.sh
```

## Continuing...

With that out of the way, you can now install this module.

To install this module, run the following commands:

```bash
       perl Makefile.PL
       make
       make test
[sudo] make install
```

*Build.PL is not supported by Inline::C, and thus not by this module as well.*

## FURTHER TEST SCRIPTS

To test the installation properly.  Log into the text console (not X).  Go to the 'examples' directory and run 'primitives.pl'.  It basically calls most of the features of the module.

The scripts beginning with 'thread' requires 'Sys::CPU'.  It is not listed as a prerequisite for this module (as it isn't), but if you want to run the threaded scripts, then this is a required module.  It demonstrates how to use this module in a threaded environment.

Mario Roy's MCE test scripts have been added (well, a script to go get them) to demonstrate alternate multiprocessing methods of using Graphics::Framebuffer, even with Perls built without threads support.

## GETTING STARTED

There is a script template in the 'examples' directory in this package.  You can use it as a starting point for your script.  It is conveniently called 'template.pl' or "threaded_template.pl".  I recommend copying it, renaming it, and leaving the original template intact for use on another project.

## COMPATIBILITY vs. SPEED

This module, suprisingly, runs on a variety of hardware with accessible framebuffer devices.  The only limitation is CPU power.  Why CPU power?  The module uses the CPU for its graphics calculations and drawing, not the GPU.  There are very little framebuffer drivers that use the GPU for anything, and thus no reliable libraries for calling the GPU at the framebuffer level.

Some lower clocked ARM devices may be too slow for practical use of all of the methods in this module, but the best way to find out is to run 'examples/primitives.pl' to see which are fast enough to use.

Here's what I have tested this module on (all 1920x1080x32):

* **Raspberry PI2/3** - Tollerable, I did 16 bit mode testing and coding on this machine.  Using a Perlbrew custom compiled Perl helps a bit.  The Raspberry PI are configured, by default, to be in 16 bit graphics mode.  This is not the best mode if you are going to be loading images or rendering TrueType text, as color space conversions can take a long time (with acceleration off).  Overall, 32 bit mode works best on this machine, especially for image loading and text rendering.  This performance limitation can, however, be minimized using the C acceleration features, if you still wish to use the 16 bit display mode.

* **Odroid XU3/XU4** - Surprisingly fast.  All methods plenty fast enough for heavy use.  Works great with threads too, 8 of them (when done properly).  Most coding for this module is done on this machine at 1920x1080x32.  This is fast enough for full screen (1920 x 1080 or less) animations at 30 fps.  If your resolution is lower, then your FPS rating will be higher.

* **Atom 1.60 GHz with NVidia Nouveau driver** - Decent, not nearly as fast as the Odroid XU3/4.  Works good with threads too (when done properly).  Great for normal graphical apps and static displayed output.  Recent versions of the Nouveau framebuffer driver have become noticably slower now days though.

* **2.6 GHz MacBook with VirtualBox** - Blazingly fast. Most primitives draw nearly instantly.

* **Windows 10 PC with VirtualBox, 4 GHz 6 core i7 CPU and 2 NVidia 970 Ti's** - Holy cow!  No, seriously, this sucker is fast!  I wonder how much faster if it were running Linux natively?  In addition, 3840x2160x32 (4K) is surprisingly fast.  Who'd have thought?  Full screen animations were choppy, but everything else was plenty fast enough.

* **Native Linux Mint with 4.2 GHz 6 core i7 CPU and 2 NVidia 1080 Ti's** - This is how I found out that the Nouveau driver is very poor when handling a framebuffer.  It's actually disgraceful at how bad and how slow it really is.  It doesn't appear to be using any DMA for the memory copy of the framebuffer, but CPU itself for transfers.  Running Virtual Box on Windows is much faster than running Linux natively with the Nouveau framebuffer drivers.  Sad, really sad.

* **NVidia Jetson Nano with 4GB of RAM** - Plenty zippy.  I am quite pleased with this offering by NVidia.

## SUPPORT AND DOCUMENTATION

After installing, you can find documentation for this module with the 'perldoc' command.

`perldoc Graphics::Framebuffer` *(You may have to install 'perldoc', but this usually works.)*

or

`man Graphics::Framebuffer` *(Installing 'perldoc' usually enables Perl module man pages)*

You can also look for information at:

* **AnnoCPAN** - Annotated CPAN documentation - http://annocpan.org/dist/Graphics-Framebuffer

* **CPAN Ratings** - http://cpanratings.perl.org/d/Graphics-Framebuffer

* **Search CPAN** - http://search.cpan.org/dist/Graphics-Framebuffer/

* **YouTube** - https://www.youtube.com/channel/UCxhjUfniyPze02GU4sWBJrw

* **GitHub** - https://github.com/richcsst/Graphics-Framebuffer

* **GitHub Clone** - https://github.com/richcsst/Graphics-Framebuffer.git

## LICENSE AND COPYRIGHT

Copyright © 2013-2025 Richard Kelsch

This program is free software; you can redistribute it and/or modify it under the terms of either: the GNU General Public License as published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
