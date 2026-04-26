# Graphics::Framebuffer Manual

   Graphics::Framebuffer - A Simple Framebuffer Graphics Library

[![Graphics::Framebuffer Logo](pics/GFB.png?raw=true "Graphics::Framebuffer Click For Demo Video")](https://www.youtube.com/watch?v=X8RpFBq6F9I)

![Divider](pics/pink.jpg?raw=true "Divider")

# Contents

* [Synopsis](#synopsis)
* [Description](#description)
* [Installation](#installation)
* [Operational Theory](#operational-theory)
* [Special Variables](#special-variables)
* [Methods](#methods)
* [Troubleshooting](#troubleshooting)
* [Author](#author)
* [Copyright](#copyright)
* [License](#license)
* [Version](#version)
* [Thanks](#thanks)
* [Tell Me About Your Project](#tell-me-about-your-project)
* [YouTube](#youtube)
* [GitHub](#github)

![Divider](pics/pink.jpg?raw=true "Divider")

# SYNOPSIS

   Direct drawing for 32/24/16 bit framebuffers (others would be supported if asked for, and I have the means to test it)

   ```perl
    use Graphics::Framebuffer;

    our $fb = Graphics::Framebuffer->new();
   ```

Drawing is this simple

   ```perl
    $fb->cls('OFF'); # Clear screen and turn off the console cursor
    $fb->graphics_mode();

    $fb->set_color({'red' => 255, 'green' => 255, 'blue' => 255, 'alpha' => 255});
    $fb->plot({'x' => 28, 'y' => 79});
    $fb->drawto({'x' => 405,'y' => 681});
    $fb->circle({'x' => 200, 'y' => 200, 'radius' => 100, 'filled' => 1});
    $fb->polygon({'coordinates' => [20,20,  53,3,  233,620]});
    $fb->box({'x' => 95, 'y' => 100, 'xx' => 400, 'yy' => 600, 'filled' => 1});
    # ... and many many more

    $fb->text_mode();
    $fb->cls('ON'); # Clear screen and turn on the console cursor
   ```

   Methods requiring parameters require a hash (or anonymous hash) reference passed to the method (for speed).  All parameters have easy to understand english names, all lower case, to understand exactly what the method is doing.

   While reading this man page will describe how each method works, looking at the source code of "examples/primitives.pl" will demonstrate how each works.

![Divider](pics/pink.jpg?raw=true "Divider")

# DESCRIPTION

   A (mostly) Perl graphics library for exclusive use in a Linux console framebuffer environment.  It is written for simplicity, without the need for complex API's and drivers with "surfaces" and such.

   Back in the old days, computers drew graphics this way, and it was simple and easy to do.  I was writing a console based media playing program, and was not satisfied with the limited abilities offered by the nCurses library, and I did not want the overhead of the X-Windows environment to get in the way.  My intention was to create a mobile media server.

   There are places where Perl just won't cut it.  So I use the **Imager** library to take up the slack, or my own C code.  **Imager** is just used to load images,, save images, merge, rotate, and draw TrueType/Type1 text.  I am also incorporating compiled C to further assist with speed.  That is being implemented step by step, but "acceleration" will always be optional, and pure Perl routines always available for those systems without a C compiler or ```Inline:C``` available.

   I cannot guarantee this will work on your video card, but I have successfully tested it on NVidia GeForce, AMD Radeon, Matrox, Raspberry PI, Odroid XU3/XU4, and VirtualBox displays.  However, you MUST remember, your video driver MUST be framebuffer based.  The proprietary Nvidia and AMD drivers (with DRM) will NOT work with this module unless you specifically enable the framebuffer. You must use the open source video drivers, such as Nouveau, to be able to use this library (with output to see).  Also, it is not going to work from within X-Windows, so don't even try it, it will either crash X, or make a mess on the screen.  This is a console only graphics library.

   * *NVidia or AMD may or may not have support in other versions.  You may have to specifically enable framebuffer support.*

   I _highly recommend_ that you use a 32/24 bit graphics mode instead of 16 bit.  Normally one might think that 16 bits are less and should be faster... WRONG.  This module uses the **Imager** module to do complex tasks and this module only works in 32/24 bit modes.  This means in order to do things on a 16 bit framebuffer, GFB must run a conversion to 16 bit on EVERY complex operation, slowing things down.  Also, CPUs today hate 16 bit accessing and prefer 32 bit, hence faster.  If you have no choice but to use 16 bit mode, then now you know it can be slower.

NOTE:

   If a framebuffer is not available, the module will go into emulation mode and open a pseudo-screen in the object's hash variable 'SCREEN'

   You can write this to a file, whatever.  It defaults to a 640x480x32 RGB graphics 'buffer'.  However, you can change that by passing parameters to the 'new' method.

   You will not be able to see the output directly when in emulation mode.  I mainly created this mode so that you could install this module (on systems without a framebuffer) and test code you may be writing to be used on other devices that have accessible framebuffer devices.  Nevertheless, I have learned that people use emulation mode as an offscreen drawing surface, and blit from one to the other.  Which is pretty clever.

   Make sure you have read/write access to the framebuffer device.  Usually this just means adding your account to the "video" group (make sure you log out and log in again after doing that).  Alternately, you can just run your script as root.  Although I don't recommend it.

![Divider](pics/pink.jpg?raw=true "Divider")

# INSTALLATION

   Read the file [installing/INSTALL.md](installing/INSTALL.md) and follow its instructions.

   When you install this module, please do it within a console, not a console window in X-Windows, but the actual Linux console outside of X-Windows.

   If you are in X-Windows, and don't know how to get to a console, then just hit CTRL-ALT-F1 (actually CTRL-ALT-F1 through CTRL-ALT-F6 works) and it should show you a console.  ALT-F7 or ALT-F8 will get you back to X-Windows, ALT-F1 works in the latest Ubuntu and Zorin-OS.

![Divider](pics/pink.jpg?raw=true "Divider")

# OPERATIONAL THEORY

   How many Perl modules actually tell you how they work?  Well, I will tell you how this one works.

   The framebuffer is simply a special file that is mapped to the screen on Unix style systems like Linux.  How the driver does this can be different.  Some may actually directly map the display memory to this file, and some install a second copy of the display to normal memory and copy it to the display on every vertical blank, usually with a fast DMA transfer.

   This module maps that file to a string, and that ends up making the string exactly the same size as the physical display.  Plotting is simply a matter of calculating where in the string that pixel is and modifying it, via "substr" (never using "=" directly).  It's that simple.

   Drawing lines etc. requires some algorithmic magic though, but they all call the plot routine to do their eventual magic.

   Originally everything was done in Perl, and the module's speed was mostly acceptable, unless you had a really slow system.  It still can run in pure Perl, if you turn off the acceleration feature, although I do not recommend it, if you want speed.

![Divider](pics/pink.jpg?raw=true "Divider")

# SPECIAL VARIABLES

   The following are hash keys to the main object variable.  For example, if you use the variable $fb as the object variable, then the following are:

   ```perl
   $fb->{VARIABLE_NAME}
   ```

   \* *NOTE:  Do NOT set these variables directly.  They are for internal use and reference only.  Use the approprate method to change settings.*

* **FONTS**

   List of system fonts

   Contains a list of hashes of every font found in the system in the format:

   ```perl
   'FaceName' => {
       'path' => 'Path To Font',
       'font' => 'File Name of Font'
   },
   # ... all of the fonts in an array list
   ```

* **Imager-Has-TrueType**

   If your installation of Imager has TrueType font capability, then this will be 1

* **Imager-Has-Type1**

   If your installation of Imager has Adobe Type 1 font capability, then this will be 1

* **Imager-Has-Freetype2**

   If your installation of Imager has the FreeType2 library rendering capability, then this will be 1

* **Imager-Image-Types**

   An anonymous array of supported image file types.

* **HATCHES**

   An anomyous array of hatch names for hatch fills.

   This is also exported as @HATCHES

* **X\_CLIP**

   The top left-hand corner X location of the clipping region

* **Y\_CLIP**

   The top left-hand corner Y location of the clipping region

* **XX\_CLIP**

   The bottom right-hand corner X location of the clipping region

* **YY\_CLIP**

   The bottom right-hand corner Y location of the clipping region.

* **CLIPPED**

   If this is true, then the clipping region is smaller than the full screen

   If false, then the clipping region is the screen dimensions.

* **DRAW\_MODE**

   The current drawing mode.  This is a numeric value corresponding to the constants described in the method 'draw\_mode'

* **RAW\_FOREGROUND\_COLOR**

   The current foreground color encoded as a string.

* **RAW\_BACKGROUND\_COLOR**

   The current background color encoded as a string.

* **ACCELERATED**

   Indicates if C code or hardware acceleration is being used.

   - **Possible Values**
  
     - 0 = Perl code only
     - 1 = Some functions accelerated by compiled C code (Default)
     - 2 = All of #1 plus additional functions accelerated by hardware (currently not supported, and likely never will)

* **IS_BVOX**

   A boolean value that indicates if running inside of VirtualBox.  Since VirtualBox version 7.2.6, it has an issue with poor framebuffer implementation and delayed updates a buffer flushing.  This allows your code to detect this environment and add
manual flushing if affected.

* **LAST_FLUSHED**

   A timestamp of when the screen was last flushed.  This allows you to throttle screen flushing to prevent bottlenecks, if you have screen flushing in your code.  For example:
   
   ```perl
   if ($FB->{'IS_VBOX') {
       $FB->_flush_screen() if ((time - (1/15)) > $FB->{'LAST_FLUSHED'});
   }
   ```

Many of the parameters you pass to the "new" method are also special variables.

![Divider](pics/pink.jpg?raw=true "Divider")

# CONSTANTS

   The following constants can be used in the various methods.  Each method example will have the possible constants to use for that method.

   The value of the constant is in parenthesis:

**CONSTANT** ( *defined value* )

   Boolean constants

   * **TRUE**  ( *1* )
   * **FALSE** ( *0* )

   Draw mode constants

   * **NORMAL\_MODE**   ( *0*  )
   * **XOR\_MODE**      ( *1*  )
   * **OR\_MODE**       ( *2*  )
   * **AND\_MODE**      ( *3*  )
   * **MASK\_MODE**     ( *4*  )
   * **UNMASK\_MODE**   ( *5*  )
   * **ALPHA\_MODE**    ( *6*  )
   * **ADD\_MODE**      ( *7*  )
   * **SUBTRACT\_MODE** ( *8*  )
   * **MULTIPLY\_MODE** ( *9*  )
   * **DIVIDE\_MODE**   ( *10* )

   Draw Arc constants

   * **ARC**       ( *0* )
   * **PIE**       ( *1* )
   * **POLY\_ARC** ( *2* )

   Virtual framebuffer color mode constants

   * **RGB** ( *0* )
   * **RBG** ( *1* )
   * **BGR** ( *2* )
   * **BRG** ( *3* )
   * **GBR** ( *4* )
   * **GRB** ( *5* )

   Text rendering centering constants

   * **CENTER\_NONE** ( *0* )
   * **CENTER\_X**    ( *1* )
   * **CENTER\_Y**    ( *2* )
   * **CENTER\_XY**   ( *3* )

   Acceleration method constants

   * **PERL**     ( *0* )
   * **SOFTWARE** ( *1* )
   * **HARDWARE** ( *2* )

![Divider](pics/pink.jpg?raw=true "Divider")

# METHODS

   With the exception of "new" and some other methods that only expect one parameter, the methods expect a single hash reference to be passed.  This may seem unusual, but it was chosen for speed, and speed is important in a Perl graphics module.

   The following are names you can search to get to the desired method:

   * Instantiation
     - [new](#new) - Create the Graphics::Framebuffer object
   * Clipping
     - [clip\_off](#clip-off) - Turn off clipping
     - [clip\_reset](#clip-reset) - Turn off clipping
     - [clip\_rset](#clip-rset) - Set clipping rectangle using relative height and width.
     - [clip\_set](#clip-set) - Set clipping using specific coordinates.
   * Settings & Control
     - [acceleration](#acceleration) - Toggle acceleration (perl only, C accelerated or hardware accelerated)
     - [active\_console](#active-console) - Get the current active console.
     - [attribute\_reset](#attribute-reset) - Reset the attributes to the global defaults.
     - [clear\_screen](#clear-screen) - Clear the screen.
     - [cls](#cls) - Clear the screen.
     - [graphics\_mode](#graphics-mode) - Turn on console graphics mode.
     - [hardware](#hardware) - Set to hardware acceleration mode.
     - [perl](#perl) - Set to Perl only acceleration mode.
     - [replace\_color](#replace-color) - Replace a specific color in the clipping region.
     - [screen\_dimension](#screen-dimensions) - Return the screen dimensions.
     - [setbcolor](#setbcolor) - Set the background color.
     - [set\_b\_color](#set-b-color) - Set the background color.
     - [set\_background\_color](#set-background-color) - Set the background color.
     - [setcolor](#setcolor) - Set the foreground color.
     - [set\_color](#set-color) - Set the foreground color.
     - [set\_foreground\_color](#set-foreground-color) - Set the foreground color.
     - [software](#software) - Set to Software (C accelerated) drawing.
     - [text\_mode](#text-mode) - Set the console to text mode.
     - [vsync](#vsync) - Block drawing until the vertical sync.
     - [wait\_for\_console](#wait-for-console) - Blocking if not the correct console.
     - [which\_console](#which-console) - Returnsd the current console.
   * Primitives
     - [ball](#ball) - Draw pseudo 3D ball.
     - [bezier](#bezier) - Draw bezier curved lines.
     - [box](#box) - Draw a box.
     - [circle](#circle) - Draw a circle.
     - [draw\_arc](#draw-arc) - Draw an arc.
     - [draw\_to](#draw-to) - Draw a line from the last plotted position.
     - [ellipse](#ellipse) - Draw an ellipse.
     - [fill](#fill) - Flood fill.
     - [filled\_pie](#filled-pie) - Draw a filled pie.
     - [getpixel](#getpixel) - Return the last plotted pixel coordinate.
     - [get\_pixel](#get-pixel) - Return the last plotted pixel coordinate.
     - [last\_plot](#last-plot) - Return the last plotted pixel coordinate.
     - [line](#line) - Draw a line at the specific coordinates.
     - [pixel](#pixel) - Plots a pixel.
     - [plot](#plot) - Plots a pixel.
     - [poly\_arc](#poly-arc) - Draw a polygon with an arc.
     - [polygon](#polygon) - Draw a polygon.
     - [rounded\_box](#rounded-box) - Draw a box with rounded corners.
     - [rbox](#rbox) - Draw a box with rounded corners.
     - [setpixel](#setpixel) - Plots a pixel.
     - [set\_pixel](#set-pixel) - Plots a pixel.
   * Drawing Modes
     - [add\_mode](#add-mode) - Draw in ADD mode.
     - [and\_mode](#add-mode) - Draw in AND mode.
     - [alpha\_mode](#alpha-mode) - Draw using alpha blending.
     - [mask\_mode](#mask-mode) - Draw using color masking.  Draws only the non-background color of the source image.
     - [multiply\_mode](#multiply-mode) - Draw using multiply mode.
     - [normal\_mode](#normal-mode) - Draw using normal mode.
     - [or\_mode](#or-mode) - Draw using OR mode.
     - [unmask\_mode](#unmask-mode) - Draw using color masking.  Draws only on the background of the destination.
     - [xor\_mode](#xor-mode) - Draw using XOR mode.
   * Image Handling
     - [load\_image](#load-image) - Load an image or animation (JPEG, GIF, PNG, PNM, TGA and TIFF)
     - [play\_animation](#play-animation) - Play an animated GIF already loaded.
     - [screen\_dump](#screen-dump) - Dump the framebuffer to disk.
   * Blitting
     - [blit\_copy](#blit-copy) - Copy a screen region to a new location leaving the original location untouched.
     - [blit\_move](#blit-move) - Move a screen region from one location to another, removing the original.
     - [blit\_read](#blit-read) - Reads in a screen region to a variable.
     - [blit\_transform](#blit-transform) - Transform a blit variable.
     - [blit\_write](#blit-write) - Writes a blit variable to a screen location.
   * Text Drawing
     - [get\_face\_name](#get-face-name) - Get the face name of a font file name.
     - [get\_font\_list](#get-font-list) - Get a list of fonts including their attributes.
     - [ttf\_paragraph](#ttf-paragraph) - Print a paragraph.
     - [ttf\_print](#ttf-print) - Print text.
   * Conversion
     - [monochrome](#monochrome) - Create a monochrome blit image variable from a color blit image variable.
     - [RGB565\_to\_RGB888](#rgb565-to-rgb888) - Converts 16 bit blit variable to 24 bit blit variable.
     - [RGB565\_to\_RGBA8888](#rgb565-to-rgba8888) - Converts 16 bit blit variable to 32 bit blit variable.
     - [RGB888\_to\_RGB565](#rgb888-to-rgb565) - Converts 24 bit blit variable to 16 bit blit variable.
     - [RGB888\_to\_RGBA8888](#rgb888-to-rgba8888) - Converts 24 bit blit variable to 32 bit blit variable.
     - [RGBA8888\_to\_RGB565](#rgba8888-to-rgb565) - Converts 32 bit blit variable to 16 bit blit variable.
     - [RGBA8888\_to\_RGB888](#rgba8888-to-rgb888) - Converts 32 bit blit variable to 24 bit blit variable.

## **new**

   This instantiates the framebuffer object

   ```perl
   my $fb = Graphics::Framebuffer->new(parameter => value);
   ```

   \* *The parameters are usually optional.*

### PARAMETERS

   * **FB\_DEVICE**

      Framebuffer device name.  If this is not defined, then it tries the following devices in the following order:

      -  /dev/fb0 - 31
      -  /dev/graphics/fb0 - 31

      If none of these work, then the module goes into emulation mode.

      You really only need to define this if there is more than one framebuffer device in your system, and you want a specific one (else it always chooses the first it finds).  If you have only one framebuffer device, then you likely do not need to define this.

      Use "EMULATED" instead of an actual framebuffer device, and it will open a memory only or "emulated" framebuffer.  You can use this mode to have multiple "layers" for loading and manipulating images, but a single main framebuffer for displaying them.

   * **FOREGROUND**

      Sets the default (global) foreground color for when 'attribute\_reset' is called.  It is in the same format as "set\_color" expects:

      ```perl
      { # This is the default value
          'red'   => 255,
          'green' => 255,
          'blue'  => 255,
          'alpha' => 255
      }
      ```

      \* *Do not use this to change colors, as "set\_color" is intended for that.  Use this to set the DEFAULT foreground color for when "attribute\_reset" is called.*

   * **BACKGROUND**

      Sets the default (global) background color for when 'attribute\_reset' is called.  It is in the same format as "set\_b\_color" expects:

      ```perl
      { # This is the default value
          'red'   => 0,
          'green' => 0,
          'blue'  => 0,
          'alpha' => 0
      }
      ```

      \* *Do not use this to change background colors, as "set\_b\_color" is intended for that.  Use this to set the DEFAULT background color for when "attribute\_reset" is called.*

   * **SPLASH**

      The splash screen is or is not displayed

      A value other than zero turns on the splash screen, and the value is the wait time to show it (default 2 seconds)
      A zero value turns it off

   * **IGNORE\_X\_WINDOWS**

      Bypasses the **X-Windows/Wayland** check and loads anyway (dangerous).
      Set to 1 to disable X-Windows/Wayland check. Default is 0.

   * **FONT\_PATH**

      Overrides the default font path (_/usr/share/fonts/truetype/freefont_) for TrueType/Type1 fonts.

      If 'ttf\_print' is not displaying any text, then this may need to be overridden.

   * **FONT\_FACE**

      Overrides the default font filename (_FreeSans.ttf_) for TrueType/Type 1 fonts.

      If 'ttf\_print' is not displaying any text, then this may need to be overridden.

   * **SHOW\_ERRORS**

      Normally this module is completely silent and does not display errors or warnings (to the best of its ability).  This is to prevent corruption of the graphics.  However, you can enable error reporting by setting this to 1.

      This is helpful for troubleshooting.

   * **DIAGNOSTICS**

      If true, it shows images as they load, and displays benchmark informtion in the loading process.

   * **RESET** \[0 or 1 (default)\]

      When the object is created, it automatically creates a simple signal handler for **INT** and **QUIT** to run **exec('reset')** as a clean way of exiting your script and restoring the screen to defaults.

      Also, when the object is destroyed, it is assumed you are exiting your script.  This causes Graphics::Framebuffer to execute "exec('reset')" as its method of exiting instead of having you use "exit".

      You can disable this behavior by setting this to 0.

   ### EMULATION MODE OPTIONS

   The options here only apply to emulation mode.

   Emulation mode can be used as a secondary off-screen drawing surface, if you are clever.

   * **FB\_DEVICE** => 'EMULATED'

      Sets this object to be in emulation mode.

      Emulation mode special variables for "new" method:

   * **VXRES**

      Width of the emulation framebuffer in pixels.  Default is 640.

   * **VYRES**

      Height of the emulation framebuffer in pixels.  Default is 480.

   * **BITS**

      Number of bits per pixel in the emulation framebuffer.  Default is 32.

   * **BYTES**

      Number of bytes per pixel in the emulation framebuffer.  It's best to keep it BITS/8.  Default is 4.

   * **COLOR\_ORDER**

      Defines the colorspace for the graphics routines to draw in.  The possible (and only accepted) string values are:

      -  'RGB'  for Red-Green-Blue (the default)
      -  'RBG'  for Red-Blue-Green
      -  'GRB'  for Green-Red-Blue
      -  'GBR'  for Green-Blue-Red
      -  'BRG'  for Blue-Red-Green
      -  'BGR'  for Blue-Green-Red (Many video cards are this)

      Why do many video cards use the BGR color order?  Simple, their GPUs operate with the high to low byte order for long words.  To the video card, it is RGB, but to a CPU that stores bytes in low to high byte order.
   
## text\_mode

   Sets the TTY into text mode, where text can interfere with the display

## graphics\_mode

   Sets the TTY in exclusive graphics mode, where text and cursor cannot interfere with the display.  Please remember, you must call text\_mode before exiting, else your console will not show any text!

## screen\_dimensions

   When called in an array/list context:

   Returns the size and nature of the framebuffer in X,Y pixel values.

   It also returns the bits per pixel.

   ```perl
   my ($width,$height,$bits_per_pixel) = $fb->screen_dimensions();
   ```

   When called in a scalar context, it returns a hash reference:

   ```perl
   {
       'width'          => pixel width of physical screen,
       'height'         => pixel height of physical screen,
       'bits_per_pixel' => bits per pixel (16, 24, or 32),
       'bytes_per_line' => Number of bytes per scan line,
       'top_clip'       => top edge of clipping rectangle (Y),
       'left_clip'      => left edge of clipping rectangle (X),
       'bottom_clip'    => bottom edge of clipping rectangle (YY),
       'right_clip'     => right edge of clipping rectangle (XX),
       'width_clip'     => width of clipping rectangle,
       'height_clip'    => height of clipping rectangle,
       'color_order'    => RGB, BGR, etc,
   }
   ```

## splash

   Displays the Splash screen.  It automatically scales and positions to the clipping region.

   This is automatically displayed when this module is initialized, and the variable 'SPLASH' is true (which is the default).

   ```perl
   $fb->splash();
   ```

## get\_font\_list

   Returns an anonymous hash containing the font face names as keys and another anonymous hash assigned as the values for each key. This second hash contains the path to the font and the font's file name.

   ```perl
   'face name' => {
       'path' => 'path to font',
       'font' => 'file name of font'
   },
   # ... The rest of the system fonts here
   ```

   You may also pass in a face name and it will return that face's information:

   ```perl
   my $font_info = $fb->get_font_list('DejaVuSerif');
   ```

   Would return something like:

   ```perl
   {
       'font' => 'dejavuserif.ttf',
       'path' => '/usr/share/fonts/truetype/'
   }
   ```

   When passing a name, it will return a hash reference (if only one match), or an array reference of hashes of fonts matching that name.  Passing in "Arial" would return the font information for "Arial Black", "Arial Narrow", and "Arial Rounded" (if they are installed on your system).

## draw\_mode

   Sets or returns the drawing mode, depending on how it is called.

   ```perl
   my $draw_mode = $fb->draw_mode(); # Returns the current
                                     # Drawing mode.

   # Modes explained.  These settings are global

                                     # When you draw it...

   $fb->draw_mode(NORMAL_MODE);      # Replaces the screen pixel with the new
                                     # pixel. Imager assisted drawing
                                     # (acceleration) only works in this mode.

   $fb->draw_mode(XOR_MODE);         # Does a bitwise XOR with the new pixel and
                                     # screen pixel.

   $fb->draw_mode(OR_MODE);          # Does a bitwise OR with the new pixel and
                                     # screen pixel.  This has the benefit of
                                     # not writing pure black to the screen
                                     # (usually the background)

   $fb->draw_mode(AND_MODE);         # Does a bitwise AND with the new pixel and
                                     # screen pixel.

   $fb->draw_mode(MASK_MODE);        # If pixels in the source are equal to the
                                     # global background color, then they are
                                     # not drawn (transparent).

   $fb->draw_mode(UNMASK_MODE);      # Draws the new pixel on screen areas only
                                     # equal to the background color.

   $fb->draw_mode(ALPHA_MODE);       # Draws the new pixel on the screen using
                                     # the alpha channel value as a transparency
                                     # value.  This means the new pixel will not
                                     # be opague.

   $fb->draw_mode(ADD_MODE);         # Draws the new pixel on the screen by
                                     # mathematically adding its pixel value to
                                     # the existing pixel value

   $fb->draw_mode(SUBTRACT_MODE);    # Draws the new pixel on the screen by
                                     # mathematically subtracting the new pixel
                                     # value from the existing value

   $fb->draw_mode(MULTIPLY_MODE);    # Draws the new pixel on the screen by
                                     # mathematically multiplying it with the
                                     # existing pixel value (usually not too
                                     # useful, but here for completeness)

   $fb->draw_mode(DIVIDE_MODE);      # Draws the new pixel on the screen by
                                     # mathematically dividing it with the
                                     # existing pixel value (usually not too
                                     # useful, but here for completeness)
   ```

## normal\_mode

   This is an alias to draw\_mode(NORMAL\_MODE)

   ```perl
   $fb->normal_mode();
   ```

## xor\_mode

   This is an alias to draw\_mode(XOR\_MODE)

   ```perl
   $fb->xor_mode();
   ```

## or\_mode

   This is an alias to draw\_mode(OR\_MODE)

   ```perl
   $fb->or_mode();
   ```

## alpha\_mode

   This is an alias to draw\_mode(ALPHA\_MODE)

   ```perl
   $fb->alpha_mode();
   ```

## and\_mode

   This is an alias to draw\_mode(AND\_MODE)

   ```perl
   $fb->and_mode();
   ```

## mask\_mode

   This is an alias to draw\_mode(MASK\_MODE)

   ```perl
   $fb->mask_mode();
   ```

## unmask\_mode

   This is an alias to draw\_mode(UNMASK\_MODE)

   ```perl
   $fb->unmask_mode();
   ```

## add\_mode

   This is an alias to draw\_mode(ADD\_MODE)

   ```perl
   $fb->add_mode();
   ```

## subtract\_mode

   This is an alias to draw\_mode(SUBTRACT\_MODE)

   ```perl
   $fb->subtract_mode();
   ```

## multiply\_mode

   This is an alias to draw\_mode(MULTIPLY\_MODE)

   ```perl
   $fb->multiply_mode();
   ```

## divide\_mode

   This is an alias to draw\_mode(DIVIDE\_MODE)

   ```perl
   $fb->divide_mode();
   ```

## clear\_screen

   Fills the entire screen with the background color

   You can add an optional parameter to turn the console cursor on or off too.

   ```perl
   $fb->clear_screen();      # Leave cursor as is.
   $fb->clear_screen('OFF'); # Turn cursor OFF (Does nothing with emulated framebuffer mode).
   $fb->clear_screen('ON');  # Turn cursor ON (Does nothing with emulated framebuffer mode).
   ```

## cls

   This is an alias to 'clear\_screen'

## attribute\_reset

   Resets the plot point at 0,0.  Resets clipping to the current screen size.  Resets the global color to whatever 'FOREGROUND' is set to, and the global background color to whatever 'BACKGROUND' is set to, and resets the drawing mode to NORMAL.

   ```perl
   $fb->attribute_reset();
   ```

## plot

   Set a single pixel in the set foreground color at position x,y with the given pixel size (or default).  Clipping applies.

   ```perl
   $fb->plot(
       {
           'x'          => 20,
           'y'          => 30,
       }
   );
   ```

## setpixel

   An alias to plot.

## set\_pixel

   An alias to plot.

## pixel

   Returns the color of the pixel at coordinate x,y, if it lies within the clipping region.  It returns undefined if outside of the clipping region.

   ```perl
   my $pixel = $fb->pixel({'x' => 20,'y' => 25});

   $pixel is a hash reference in the form:

   {
       'red'   => integer value, # 0 - 255
       'green' => integer value, # 0 - 255
       'blue'  => integer value, # 0 - 255
       'alpha' => integer value, # 0 - 255
       'hex'   => hexadecimal string of the values from 00000000 to FFFFFFFF
       'raw'   => 16/24/32bit encoded string (depending on screen mode)
   }
   ```

## getpixel

   Alias for 'pixel'.

## get\_pixel

   Alias for 'pixel'.

## last\_plot

   Returns the last plotted position

   ```perl
   my $last_plot = $fb->last_plot();
   ```

   This returns an anonymous hash reference in the form:

   ```perl
   {
       'x' => x position,
       'y' => y position
   }
   ```

   Or, if you want a simple array returned:

   ```perl
   my ($x,$y) = $fb->last_plot();
   ```

   This returns the position as a two element array:

   ```perl
   ( x position, y position )
   ```

## line

   Draws a line, in the foreground color, from point x,y to point xx,yy.  Clipping applies.

   ```perl
   $fb->line({
       'x'           => 50,
       'y'           => 60,
       'xx'          => 100,
       'yy'          => 332
       'antialiased' => TRUE # Antialiasing is slower
   });
   ```

## angle\_line

   Draws a line, in the global foreground color, from point x,y at an angle of 'angle', of length 'radius'.  Clipping applies.

   ```perl
   $fb->angle_line({
       'x'           => 50,
       'y'           => 60,
       'radius'      => 50,
       'angle'       => 30.3, # Compass coordinates (0-360)
       'antialiased' => FALSE
   });
   ```

## drawto

   Draws a line, in the foreground color, from the last plotted position to the position x,y.  Clipping applies.

   ```perl
   $fb->drawto({
       'x'           => 50,
       'y'           => 60,
       'antialiased' => TRUE
   });
   ```

   \* *Antialiased lines are not accelerated.*

## bezier

   Draws a Bezier curve, based on a list of control points.

   ```perl
   $fb->bezier(
       {
           'coordinates' => [
               x0,y0,
               x1,y1,
               # ...              # As many as needed, there MUST be an even number of elements
           ],
           'points'     => 100, # Number of total points plotted for curve
                                # The higher the number, the smoother the curve.
           'closed'     => 1,   # optional, close it and make it a full shape.
           'filled'     => 1    # Results may vary, optional
           'gradient' => {
               'direction' => 'horizontal', # or vertical
               'colors'    => { # 2 to any number of transitions allowed
                   'red'   => [255,255,0], # Red to yellow to cyan
                   'green' => [0,255,255],
                   'blue'  => [0,0,255]
               }
           }
       }
   );
   ```

   \* *This is not affected by the Acceleration setting.*

## cubic\_bezier

   *DISCONTINUED, use 'bezier' instead (now just an alias to 'bezier').*

## draw\_arc

   Draws an arc/pie/poly arc of a circle at point x,y.

   ```perl
   # x             = x of center of circle
   # y             = y of center of circle
   # radius        = radius of circle

   # start_degrees = starting point, in degrees, of arc

   # end_degrees   = ending point, in degrees, of arc

   # granularity   = This is used for accuracy in drawing
   #                 the arc.  The smaller the number, the
   #                 more accurate the arc is drawn, but it
   #                 is also slower.  Values between 0.1
   #                 and 0.01 are usually good.  Valid values
   #                 are any positive floating point number
   #                 down to 0.0001.  Anything smaller than
   #                 that is just silly.

   # mode          = Specifies the drawing mode.
   #                   0 > arc only
   #                   1 > Filled pie section
   #                       Can have gradients, textures, and hatches
   #                   2 > Poly arc.  Draws a line from x,y to the
   #                       beginning and ending arc position.

   $fb->draw_arc({
       'x'             => 100,
       'y'             => 100,
       'radius'        => 100,
       'start_degrees' => -40, # Compass coordinates
       'end_degrees'   => 80,
       'granularity'   => .05,
       'mode'          => 2    # The object hash has 'ARC', 'PIE',
                               # and 'POLY_ARC' as a means of filling
                               # this value.
   });
   ```

   \* *Only PIE is affected by the acceleration setting.*

## arc

   Draws an arc of a circle at point x,y.  This is an alias to draw\_arc above, but no mode parameter needed.

   ```perl
   # x             = x of center of circle

   # y             = y of center of circle

   # radius        = radius of circle

   # start_degrees = starting point, in degrees, of arc

   # end_degrees   = ending point, in degrees, of arc

   # granularity   = This is used for accuracy in drawing
   #                 the arc.  The smaller the number, the
   #                 more accurate the arc is drawn, but it
   #                 is also slower.  Values between 0.1
   #                 and 0.01 are usually good.  Valid values
   #                 are any positive floating point number
   #                 down to 0.0001.

   $fb->arc({
       'x'             => 100,
       'y'             => 100,
       'radius'        => 100,
       'start_degrees' => -40,
       'end_degrees'   => 80,
       'granularity    => .05,
   });
   ```

   \* *This is not affected by the Acceleration setting.*

## filled\_pie

   Draws a filled pie wedge at point x,y.  This is an alias to draw\_arc above, but no mode parameter needed.

   ```perl
   # x             = x of center of circle

   # y             = y of center of circle

   # radius        = radius of circle

   # start_degrees = starting point, in degrees, of arc

   # end_degrees   = ending point, in degrees, of arc

   # granularity   = This is used for accuracy in drawing
   #                 the arc.  The smaller the number, the
   #                 more accurate the arc is drawn, but it
   #                 is also slower.  Values between 0.1
   #                 and 0.01 are usually good.  Valid values
   #                 are any positive floating point number
   #                 down to 0.0001.

   $fb->filled_pie({
       'x'             => 100,
       'y'             => 100,
       'radius'        => 100,
       'start_degrees' => -40,
       'end_degrees'   => 80,
       'granularity'   => .05,
       'gradient'      => {  # optional
           'direction' => 'horizontal', # or vertical
           'colors'    => { # 2 to any number of transitions allowed
               'red'   => [255,255,0], # Red to yellow to cyan
               'green' => [0,255,255],
               'blue'  => [0,0,255],
               'alpha' => [255,255,255],
           }
       },
       'texture'       => { # Same as what blit_read or load_image returns
           'width'  => 320,
           'height' => 240,
           'image'  => $raw_image_data
       },
       'hatch'         => 'hatchname' # The exported array @HATCHES contains
                                      # the names of all the hatches
   });
   ```

   \* *This is affected by the Acceleration setting.*

## poly\_arc

   Draws a poly arc of a circle at point x,y.  This is an alias to draw\_arc above, but no mode parameter needed.

   ```perl
   # x             = x of center of circle

   # y             = y of center of circle

   # radius        = radius of circle

   # start_degrees = starting point, in degrees, of arc

   # end_degrees   = ending point, in degrees, of arc

   # granularity   = This is used for accuracy in drawing
   #                 the arc.  The smaller the number, the
   #                 more accurate the arc is drawn, but it
   #                 is also slower.  Values between 0.1
   #                 and 0.01 are usually good.  Valid values
   #                 are any positive floating point number
   #                 down to 0.0001.

   $fb->poly_arc({
       'x'             => 100,
       'y'             => 100,
       'radius'        => 100,
       'start_degrees' => -40,
       'end_degrees'   => 80,
       'granularity'   => .05,
   });
   ```

   \* *This is not affected by the Acceleration setting.*

## ellipse

   Draw an ellipse at center position x,y with XRadius, YRadius.  Either a filled ellipse or outline is drawn based on the value of $filled.  The optional factor value varies from the default 1 to change the look and nature of the output.

   ```perl
   $fb->ellipse({
       'x'          => 200, # Horizontal center
       'y'          => 250, # Vertical center
       'xradius'    => 50,
       'yradius'    => 100,
       'factor'     => 1, # Anything other than 1 has funkiness
       'filled'     => 1, # optional

       ## Only one of the following may be used

       'gradient'   => {  # optional, but 'filled' must be set
           'direction' => 'horizontal', # or vertical 90 degree directions only
           'colors'    => { # 2 to any number of transitions allowed
               'red'   => [255,255,0], # Red to yellow to cyan
               'green' => [0,255,255],
               'blue'  => [0,0,255],
               'alpha' => [255,255,255],
           }
       }
       'texture'    => {  # Same format blit_read or load_image uses.
           'width'   => 320,
           'height'  => 240,
           'image'   => $raw_image_data
       },
       'hatch'      => 'hatchname' # The exported array @HATCHES contains
                                   # the names of all the hatches
   });
   ```

   \* *This is not affected by the Acceleration setting.*

   *\\* *Also note, ellipses are only drawn with 90 degree angles.  You can rotate it to get other angles.*

## ball

   Draws a filled circle resembling a 3D ball, similar to a Christmas tree globe.  It draws it at point x,y with radius 'radius' and the brightest color.  It ignores the current foreground color and uses its own color definition.
   
   ```perl
   $fb->ball({
       'x' => 300, #n Horizontal center
       'x'        => 300, # Horizontal center
       'y'        => 300, # Vertical center
       'radius'   => 100,
	   'colors'   => { # Highest intensity of desired color
           'red' => 255,
           'green' => 0,
           'blue'  => 128,
           'alpha' => 64, # OPTIONAL, else alpha is ignored
	   },
   });
   ```

## circle

   Draws a circle at point x,y, with radius 'radius'.  It can be an outline, solid filled, or gradient filled.  Outlined circles can have any pixel size.

   ```perl
   $fb->circle({
       'x'        => 300, # Horizontal center
       'y'        => 300, # Vertical center
       'radius'   => 100,
       'filled'   => 1, # optional
       'gradient' => {  # optional
           'direction' => 'horizontal', # or vertical
           'colors'    => { # 2 to any number of transitions allowed
               'red'   => [255,255,0], # Red to yellow to cyan
               'green' => [0,255,255],
               'blue'  => [0,0,255],
               'alpha' => [255,255,255],
           }
       },
       'texture'  => { # Same as what blit_read or load_image returns
           'width'  => 320,
           'height' => 240,
           'image'  => $raw_image_data
       },
       'hatch'      => 'hatchname' # The exported array @HATCHES contains
                                   # the names of all the hatches
   });
   ```

   \* *This is affected by the Acceleration setting.*

## polygon

   Creates a polygon drawn in the foreground color value.  The parameter 'coordinates' is a reference to an array of x,y values.  The last x,y combination is connected automatically with the first to close the polygon.  All x,y values are absolute, not relative.

   It is up to you to make sure the coordinates are "sane".  Weird things can result from twisted or complex filled polygons.

   ```perl
   $fb->polygon({
       'coordinates' => [
           5,5,
           23,34,
           70,7
       ],
       'antialiased' => 1, # optional only for non-filled
       'filled'      => 1, # optional

       ## Only one of the following, "filled" must be set

       'gradient'    => {  # optional
           'direction' => 'horizontal', # or vertical
           'colors'    => { # 2 to any number of transitions allowed
               'red'   => [255,255,0], # Red to yellow to cyan
               'green' => [0,255,255],
               'blue'  => [0,0,255],
               'alpha' => [255,255,255],
           }
       },
       'texture'     => { # Same as what blit_read or load_image returns
           'width'  => 320,
           'height' => 240,
           'image'  => $raw_image_data
       },
       'hatch'      => 'hatchname' # The exported array @HATCHES contains
                                   # the names of all the hatches
   });
   ```

   \* *Filled polygons are affected by the acceleration setting.*

## box

   Draws a box from point x,y to point xx,yy, either as an outline, if 'filled' is 0, or as a filled block, if 'filled' is 1.  You may also add a gradient or texture.

   ```perl
   $fb->box({
       'x'          => 20,
       'y'          => 50,
       'xx'         => 70,
       'yy'         => 100,
       'radius'     => 0,                # if rounded, optional
       'filled'     => 1,                # optional

       ## Only one of the following, "filled" must be set

       'gradient'    => {                # optional
           'direction' => 'horizontal',  # or vertical
           'colors'    => {              # 2 to any number of transitions allowed, and all colors must have the same number of transitions
               'red'   => [255,255,0],   # Red to yellow to cyan
               'green' => [0,255,255],
               'blue'  => [0,0,255],
               'alpha' => [255,255,255], # Yes, even alpha transparency can vary
           }
       },
       'texture'     => {                # Same as what blit_read or load_image returns
           'width'  => 320,
           'height' => 240,
           'image'  => $raw_image_data
       },
       'hatch'      => 'hatchname'       # The exported array @HATCHES contains
                                         # the names of all the hatches
   });
   ```

## rbox

   Draws a box at point x,y with the width 'width' and height 'height'.  It draws a frame if 'filled' is 0 or a filled box if 'filled' is 1. Filled boxes draw faster than frames. Gradients or textures are also allowed.

   ```perl
   $fb->rbox({
       'x'          => 100,
       'y'          => 100,
       'width'      => 200,
       'height'     => 150,
       'radius'     => 0,               # if rounded, optional
       'filled'     => 0,               # optional

       ## Only one of the following, "filled" must be set

       'gradient'    => {  # optional
           'direction' => 'horizontal', # or vertical
           'colors'    => {             # 2 to any number of transitions allowed
               'red'   => [255,255,0],  # Red to yellow to cyan
               'green' => [0,255,255],
               'blue'  => [0,0,255],
               'alpha' => [255,255,255],
           }
       },
       'texture'     => {               # Same as what blit_read or load_image returns
           'width'  => 320,
           'height' => 240,
           'image'  => $raw_image_data
       },
       'hatch'      => 'hatchname'      # The exported array @HATCHES contains
                                        # the names of all the hatches
   });
   ```

## rounded\_box

   This is an alias to rbox

## set\_color

   Sets the drawing color in red, green, and blue, absolute 8 bit values.

   Even if you are in 16 bit color mode, use 8 bit values.  They will be automatically scaled.

   ```perl
   $fb->set_color({
       'red'   => 255,
       'green' => 255,
       'blue'  => 0,
       'alpha' => 255
   });
   ```

## setcolor

   This is an alias to 'set\_color'

## set\_foreground\_color

   This is an alias to 'set\_color'

## set\_b\_color

   Sets the background color in red, green, and blue values.

   The same rules as set\_color apply.

   ```perl
    $fb->set_b_color({
       'red'   => 0,
       'green' => 0,
       'blue'  => 255,
       'alpha' => 255
   });
   ```

## setbcolor

   This is an alias to 'set\_b\_color'

## set\_background\_color

   This is an alias to 'set\_b\_color'

## fill

   Does a flood fill starting at point x,y.  It samples the color at that point and determines that color to be the "background" color, and proceeds to fill in, with the current foreground color, until the "background" color is replaced with the new color.

   *NOTE:  The accelerated version of this routine may (and it is a small may) have issues.  If you find any issues, then temporarily turn off C-acceleration when calling this method.*

   ```perl
   $fb->fill({'x' => 334, 'y' => 23});
   ```

   \* *This one is greatly affected by the acceleration setting, and likely the one that may give the most trouble.  I have found on some systems Imager just doesn't do what it is asked to, but on others it works fine.  Go figure.  Some of you are getting your entire screen filled and know you are placing the X,Y coordinate correctly, then disabling acceleration before calling this should fix it.  Don't forget to re-enable acceleration when done.*

## replace\_color

   This replaces one color with another inside the clipping region.  Sort of like a fill without boundary checking.

   ```perl
   $fb->replace_color({
       'old' => { # Changed as of 5.56
           'red'   => 23,
           'green' => 48,
           'blue'  => 98
           # alpha is ignored
       },
       'new' => {
           'red'   => 255,
           'green' => 255,
           'blue'  => 0
           # alpha is ignored
       }
   });

   $fb->replace_color({
       'old' => {
           'raw' => "raw encoded string of color",
       },
       'new' => {
           'raw' => "raw encoded string of color",
       }
   });

   # Encoded color strings are 4 bytes wide for 32 bit, 3 bytes for 24 bit and 2 bytes for 16 bit color.
   ```

   \* *This is not affected by the Acceleration setting, and is just as fast in 16 bit as it is in 24 and 32 bit modes.  Which means, very fast.*

## blit\_copy

   Copies a square portion of screen graphic data from x,y,w,h to x\_dest,y\_dest.  It copies in the current drawing mode.

   ```perl
   $fb->blit_copy({
       'x'      => 20,
       'y'      => 20,
       'width'  => 30,
       'height' => 30,
       'x_dest' => 200,
       'y_dest' => 200
   });
   ```

## blit\_move

   Moves a square portion of screen graphic data from x,y,w,h to x\_dest,y\_dest.  It moves in the current drawing mode.  It differs from "blit\_copy" in that it removes the graphic from the original location (via XOR).

   It also returns the data moved like "blit\_read"

   ```perl
   $fb->blit_move({
       'x'      => 20,
       'y'      => 20,
       'width'  => 30,
       'height' => 30,
       'x_dest' => 200,
       'y_dest' => 200,
       'image'  => $raw_image_data, # This is optional, but can speed things up
   });
   ```

## play\_animation

   Plays an animation sequence loaded from "load\_image"

   ```perl
   my $animation = $fb->load_image(
       {
           'file'            => 'filename.gif',
           'center'          => CENTER_XY,
       }
   );

   $fb->play_animation($animation,$rate_multiplier);
   ```

   The animation is played at the speed described by the file's metadata multiplied by "rate\_multiplier".

   You need to enclose this in a loop if you wish it to play more than once.

## acceleration

   Enables/Disables all Imager or C language acceleration.

   GFB uses the Imager library to do some drawing.  In some cases, these may not function as they should on some systems.  This method allows you to toggle this acceleration on or off.

   When acceleration is off, the underlying (slower) Perl algorithms are used.  It is advisable to leave acceleration on for those methods which it functions correctly, and only shut it off when calling the problem ones.

   When called without parameters, it returns the current setting.

   ```perl
   $fb->acceleration(HARDWARE); # Turn hardware acceleration ON, along with some C acceleration (HARDWARE IS NOT YET IMPLEMENTED!)

   $fb->acceleration(SOFTWARE); # Turn C (software) acceleration ON

   $fb->acceleration(PERL);     # Turn acceleration OFF, using Perl

   my $accel = $fb->acceleration(); # Get current acceleration state.  0 = PERL, 1 = SOFTWARE, 2 = HARDWARE (not yet implemented)

   my $accel = $fb->acceleration('english'); # Get current acceleration state in an english string.
                                             # "PERL"     = PERL     = 0
                                             # "SOFTWARE" = SOFTWARE = 1
                                             # "HARDWARE" = HARDWARE = 2
   ```

   \* *The "Mask" and "Unmask" drawing modes are greatly affected by acceleration, as well as 16 bit conversions in image loading and ttf\_print(ing).*

## perl

   This is an alias to "acceleration(PERL)"

## software

   This is an alias to "acceleration(SOFTWARE)"

## hardware

   This is an alias to "acceleration(HARDWARE)"

   *Hardware acceleration is not implemented.*

## blit\_read

   Reads in a square portion of screen data at x,y,width,height, and returns a hash reference with information about the block, including the raw data as a string, ready to be used with 'blit\_write'.

   Passing no parameters automatically grabs the clipping region (the whole screen if clipping is off).

   ```perl
   my $blit_data = $fb->blit_read({
       'x'      => 30,
       'y'      => 50,
       'width'  => 100,
       'height' => 100
   });
   ```

   Returns:

   ```perl
   {
       'x'      => original X position,
       'y'      => original Y position,
       'width'  => width,
       'height' => height,
       'image'  => string of image data for the block
   }
   ```

   All you have to do is change X and Y, and just pass it to "blit\_write" and it will paste it there.

## blit\_write

   Writes a previously read block of screen data at x,y,width,height.

   It takes a hash reference.  It draws in the current drawing mode.

   ```perl
   $fb->blit_write({
       'x'      => 0,
       'y'      => 0,
       'width'  => 100,
       'height' => 100,
       'image'  => $blit_data
   });
   ```

## blit\_transform

   This performs transformations on your blit objects.

   You can only have one of "rotate", "scale", "merge", "flip", or make "monochrome".  You may use only one transformation per call.

   * **blit\_data** (mandatory)

      Used by all transformations.  It's the image data to process, in the format that "blit\_write" uses.  See the example below.

   * **flip**

      Flips the image either "horizontally, "vertically, or "both"

   * **merge**

      Merges one image on top of the other.  "blit\_data" is the top image, and "dest\_blit\_data" is the background image.  This takes into account alpha data values for each pixel (if in 32 bit mode).

      This is very usefull in 32 bit mode due to its alpha channel capabilities.

   * **rotate**

      Rotates the "blit\_data" image an arbitrary degree.  Positive degree values are counterclockwise and negative degree values are clockwise.

      Two types of rotate methods are available, an extrememly fast, but visually slightly less appealing method, and a slower, but looks better, method.  Seriously though, the fast method looks pretty darn good anyway.  I recommend "fast".

   * **scale**

      Scales the image to "width" x "height".  This is the same as how scale works in "load\_image".  The "type" value tells it how to scale (see the example).

   ```perl
   $fb->blit_transform(
       {
           # blit_data is mandatory
           'blit_data' => { # Same as what blit_read or load_image returns
               'x'      => 0, # This is relative to the dimensions of "dest_blit_data" for "merge"
               'y'      => 0, # ^^
                   'width'  => 300,
                   'height' => 200,
                   'image'  => $image_data
           },

           'merge'  => {
               'dest_blit_data' => { # MUST have same or greater dimensions as 'blit_data'
                    'x'      => 0,
                    'y'      => 0,
                    'width'  => 300,
                    'height' => 200,
                    'image'  => $image_data
                }
            },

            'rotate' => {
                'degrees' => 45, # 0-360 degrees. Negative numbers rotate clockwise.
                'quality' => 'high', # "high" or "fast" are your choices, with "fast" being the default
            },

            'flip' => 'horizontal', # or "vertical" or "both"

            'scale'  => {
                'x'          => 0,
                'y'          => 0,
                'width'      => 500,
                'height'     => 300,
                'scale_type' => 'min' #  'min'     = The smaller of the two
                                      #              sizes are used (default)
                                      #  'max'     = The larger of the two
                                      #              sizes are used
                                      #  'nonprop' = Non-proportional sizing
                                      #              The image is scaled to
                                      #              width x height exactly.
            },

            'monochrome' => TRUE      # Makes the image data monochrome
        }
   );
   ```

   It returns the transformed image in the same format the other BLIT methods use.  Note, the width and height may be changed!  So always use the returned data as the correct new data.

   ```perl
   {
       'x'      => 0,     # copied from "blit_data"
       'y'      => 0,     # copied from "blit_data"
       'width'  => 100,   # width of transformed image data
       'height' => 100,   # height of transformed image data
       'image'  => $image # image data
   }
   ```

   \* *Rotate and Flip are affected by the acceleration setting.*

## clip\_reset

   Turns off clipping, and resets the clipping values to the full size of the screen.

   ```perl
   $fb->clip_reset();
   ```

## clip\_off

   This is an alias to 'clip\_reset'

## clip\_set

   Sets the clipping rectangle starting at the top left point x,y and ending at bottom right point xx,yy.

   ```perl
   $fb->clip_set({
       'x'  => 10,
       'y'  => 10,
       'xx' => 300,
       'yy' => 300
   });
   ```

## clip\_rset

   Sets the clipping rectangle to point x,y,width,height

   ```perl
   $fb->clip_rset({
       'x'      => 10,
       'y'      => 10,
       'width'  => 600,
       'height' => 400
   });
   ```

## monochrome

   Removes all color information from an image, and leaves everything in greyscale.

   It applies the following formula to calculate greyscale:

   * grey_color = (red * 0.2126) + (green * 0.7155) + (blue * 0.0722)

   Expects two parameters, 'image' and 'bits'.  The parameter 'image' is a string containing the image data.  The parameter 'bits' is how many bits per pixel make up the image.  Valid values are 16, 24, and 32 only.

   ```perl
   $fb->monochrome({
       'image' => "image data",
       'bits'  => 32
   });
   ```

   It returns 'image' back, but now in greyscale (still the same RGB format though).

   ```perl
   {
       'image' => "monochrome image data"
   }
   ```

   \* *You should normally use "blit\_transform", but this is a more raw way of affecting the data.*

## ttf\_print

   Prints TrueType text on the screen at point x,y in the rectangle width,height, using the color 'color', and the face 'face' (using the Imager library as its engine).

   *Note, 'y' is the baseline position, not the top left of the bounding box.*

   This is best called twice, first in bounding box mode, and then in normal mode.

   Bounding box mode gets the actual values needed to display the text.

   If draw mode is "normal", then mask mode is automatically used for best output.

   ```perl
   my $bounding_box = $fb->ttf_print({
       'x'            => 20,
       'y'            => 100, # baseline position
       'height'       => 16,
       'wscale'       => 1,   # Scales the width.  1 is normal
       'color'        => 'FFFF00FF', # Hex value of color 00-FF (RRGGBBAA)
       'text'         => 'Hello World!',
       'font_path'    => '/usr/share/fonts/truetype', # Optional
       'face'         => 'Arial.ttf',                 # Optional
       'bounding_box' => TRUE,
       'center'       => CENTER_X,
       'antialias'    => TRUE
   });

   $fb->ttf_print($bounding_box);
   ```

   Here's a shortcut:

   ```perl
   $fb->ttf_print(
       $fb->ttf_print({
           'x'            => 20,
           'y'            => 100, # baseline position
           'height'       => 16,
           'color'        => 'FFFF00FF', # RRGGBBAA
           'text'         => 'Hello World!',
           'font_path'    => '/usr/share/fonts/truetype', # Optional
           'face'         => 'Arial.ttf',                 # Optional
           'bounding_box' => TRUE,
           'rotate'       => 45,    # optonal
           'center'       => CENTER_X,
           'antialias'    => 1,
           'shadow'       => shadow size
        })
   );
   ```

   \* *Failures of this method are usually due to it not being able to find the font.  Make sure you have the right path and name.*

## ttf\_paragraph

   Very similar to an ordinary Perl "print", but uses TTF fonts instead.  It will automatically wrap text like a terminal.

   This uses no bounding boxes, and is only needed to be called once.  It uses a very simple wrapping model.

   It uses the clipping rectangle.  All text will be fit and wrapped within the clipping rectangle.

   Text is started at "x" and wrapped to "x" for each line, no indentation.

   \* *This does _NOT_ scroll text.  It merely truncates what doesn't fit.  It returns where in the text string it last printed before truncation.  It's also quite slow.*

   ```perl
   $fb->ttf_paragraph(
       {
           'text'         => 'String to print',

           'x'            => 0,                  # Where to start printing
           'y'            => 20,                 #

           'size'         => 12,                 # Optional Font size, default is 16

           'color'        => 'FFFF00FF',         # RRGGBBAA in hex

           'justify'      => 'justified'         # Optional justification, default
                                                 # is "left".  Posible values are:
                                                 #  "left", "right", "center", and
                                                 #  "justified"

           'line_spacing' => 5,                  # This adjusts the default line
                                                 # spacing by positive or negative
                                                 # amounts.  The default is 0.

           'face'         => 'Ariel',            # Optional, overrides the default

           'font_path'    => '/usr/share/fonts', # Optional, else uses the default
       }
   );
   ```

## get\_face\_name

   Returns the TrueType face name based on the parameters passed.

   ```perl
   my $face_name = $fb->get_face_name({
       'font_path' => '/usr/share/fonts/TrueType/',
       'face'      => 'FontFileName.ttf'
   });
   ```

## load\_image

   Loads an image at point x,y\[,width,height\].  To display it, pass it to blit\_write.

   If you give centering options, the position to display the image is part of what is returned, and is ready for blitting.

   If 'width' and/or 'height' is given, the image is resized.  Note, resizing is CPU intensive.  Nevertheless, this is done by the Imager library (compiled C) so it is relatively fast.

   ```perl
   my $image_data = $fb->load_image(
       {
           'x'          => 0,     # Optional (only applies if CENTER_X or
                                  # CENTER_XY is not used)

           'y'          => 0,     # Optional (only applies if CENTER_Y or
                                  # CENTER_XY is not used)

           'width'      => 1920,  # Optional. Resizes to this maximum width.
                                  # It fits the image to this size.

           'height'     => 1080,  # Optional. Resizes to this maximum height.
                                  # It fits the image to this size

           'scale_type' => 'min', # Optional. Sets the type of scaling
                                  #
                                  #  'min'     = The smaller of the two sizes
                                  #              are used (default)
                                  #  'max'     = The larger of the two sizes
                                  #              are used
                                  #  'nonprop' = Non-proportional sizing
                                  #              The image is scaled to
                                  #              width x height exactly.

           'autolevels' => FALSE, # Optional.  It does a color correction.
                                  # Sometimes this works well, and sometimes
                                  # it looks quite ugly.  It depends on the
                                  # image

           'center'     => CENTER_XY, # Optional
                                      # Three centering options are available
                                      #  CENTER_X  = center horizontally
                                      #  CENTER_Y  = center vertically
                                      #  CENTER_XY = center horizontally and
                                      #              vertically.  Placing it
                                      #              right in the middle of
                                      #              the screen.

           'file'       => 'image.png', # Usually needs full path

           'convertalpha' => TRUE, # Converts the color matching the global
                                   # background color to have the same alpha
                                   # channel value as the global background,
                                   # which is beneficial for using 'merge'
                                   # in 'blit_transform'.

           'preserve_transparency' => FALSE,
                                   # Preserve the transparency of GIFs for
                                   # use with "mask_mode" playback.
                                   # This can allow for slightly faster
                                   # playback of animated GIFs on systems
                                   # using the acceration features of this
                                   # module.  However, not all animated
                                   # GIFs look right when this is done.
                                   # the safest setting is to not use this,
                                   # and playback using normal_mode.

           'fpsmax' => 10,
                                   # If the file is a video file, it will be
                                   # converted to a GIF file.  This value
                                   # determines the maximum number of frames
                                   # per second allowed in the conversion.
                                   # Note, the higher the number, the slower
                                   # the conversion process.  This only works
                                   # if "ffmpeg" is installed.
           }
     );
   ```

   If a single image is loaded, it returns a reference to an anonymous hash, of the format:

   ```perl
   {
       'x'      => horizontal position calculated (or passed through),
       'y'      => vertical position calculated (or passed through),
       'width'  => Width of the image,
       'height' => Height of the image,
       'tags'   => The tags of the image (hashref)
       'image'  => [raw image data]
   }
   ```

   If the image has multiple frames, then a reference to an array of hashes is returned:

   ```perl
   # NOTE:  X and Y positions can change frame to frame, so use them for each
   #        frame!  Also, X and Y are based upon what was originally passed
   #        through, else they reference 0,0 (but only if you didn't give an X,Y
   #        value initially).

   # ALSO:  The tags may also specify offsets, and they will be taken into account.

   [
       { # Frame 1
           'x'      => horizontal position calculated (or passed through),
           'y'      => vertical position calculated (or passed through),
           'width'  => Width of the image,
           'height' => Height of the image,
           'tags'   => The tags of the image (hashref)
           'image'  => [raw image data]
       },
       { # Frame 2 (and so on)
           'x'      => horizontal position calculated (or passed through),
           'y'      => vertical position calculated (or passed through),
           'width'  => Width of the image,
           'height' => Height of the image,
           'tags'   => The tags of the image (hashref)
           'image'  => [raw image data]
       }
   ]
   ```

## screen\_dump

   Dumps the screen to a file given in 'file' in the format given in 'format'

Formats can be (they are case-insensitive):

- **JPEG**

    The most widely used format.  This is a "lossy" format.  The default quality setting is 75%, but it can be overriden with the "quality" parameter.

- **GIF**

    The CompuServe "Graphics Interchange Format".  A very old and outdated format made specifically for VGA graphics modes, but still widely used.  It only allows up to 256 "indexed" colors, so quality is very lacking.  The "dither" paramter determines how colors are translated from 24 bit truecolor to 8 bit indexed.

- **PNG**

    The Portable Network Graphics format.  Widely used, very high quality.

- **PNM**

    The Portable aNy Map format.  These are typically "PPM" files.  Not widely used.

- **TGA**

    The Targa image format.  This is a high-color, lossless format, typically used in photography

- **TIFF**

    The Tagged Image File Format.  Sort of an older version of PNG (but not the same, just similar in capability).  Sometimes used in FAX formats.

   ```perl
   $fb->screen_dump(
       {
           'file'   => '/path/filename', # name of file to be written
           'format' => 'jpeg',           # jpeg, gif, png, pnm, tga, or tiff

           # for JPEG formats only
           'quality' => 75,              # quality of the JPEG file 1-100% (the
                                         # higher the number, the better the
                                         # quality, but the larger the file)

           # for GIF formats only
           'dither'  => 'floyd',         # Can be "floyd", "jarvis" or "stucki"
       }
   );
   ```

## RGB565\_to\_RGB888

   Convert a 16 bit color value to a 24 bit color value.  This requires the color to be a two byte packed string.

   ```perl
   my $color24 = $fb->RGB565_to_RGB888(
       {
           'color' => $color16
       }
   );
   ```

## RGB565\_to\_RGB8888

   Convert a 16 bit color value to a 32 bit color value.  This requires the color to be a two byte packed string.  The alpha value is either a value passed in or the default 255.

   ```perl
   my $color32 = $fb->RGB565_to_RGB8888(
       {
           'color' => $color16, # Required
           'alpha' => 128       # Optional
       }
   );
   ```

## RGB888\_to\_RGB565

   Convert 24 bit color value to a 16 bit color value.  This requires a three byte packed string.

   ```perl
   my $color16 = $fb->RGB888_to_RGB565(
       {
           'color' => $color24
       }
   );
   ```

   This simply does a bitshift, nothing more.

## RGBA8888\_to\_RGB565

   Convert 32 bit color value to a 16 bit color value.  This requires a four byte packed string.

   ```perl
   my $color16 = $fb->RGB8888_to_RGB565(
       {
           'color' => $color32,
       }
   );
   ```

   This simply does a bitshift, nothing more

## RGB888\_to\_RGBA8888

   Convert 24 bit color value to a 32 bit color value.  This requires a three byte packed string.  The alpha value is either a value passed in or the default 255.

   ```perl
   my $color32 = $fb->RGB888_to_RGBA8888(
       {
           'color' => $color24,
           'alpha' => 64
       }
   );
   ```

   This just simply adds an alpha value.  No actual color conversion is done.

## RGBA8888\_to\_RGB888

   Convert 32 bit color value to a 24 bit color value.  This requires a four byte packed string.

   ```perl
   my $color24 = $fb->RGBA8888_to_RGB888(
       {
           'color' => $color32
       }
   );
   ```

   This just removes the alpha value.  No color conversion is actually done.

## vsync

   Waits for the vertical blank before returning

   \* *Not all framebuffer drivers have this capability and ignore this call.  Results may vary, as this cannot be emulated.  The only way to know is to just test it.*

## which\_console

   Returns the active console and the expected console

   ```perl
   my ($active_console, $expected_console) = $fb->which_console();
   ```

## active\_console

   Indicates if the current console is the expected console.  It returns true or false.

   ```perl
   if ($self->active_console()) {
       # Do something
   }
   ```

## wait\_for\_console

   Blocks actions until the expected console is active.  The expected console is determined at the time the module is initialized.

   Due to speed considerations, YOU must do use this to do blocking, if desired.  If you expect to be changing active consoles, then you will need to use this.  However, if you do not plan to do ever change consoles when running this module, then don't use this feature, as your results will be faster.

   If a TRUE or FALSE is passed to this, then you can enable or disable blocking for subsequent calls.

## initialize\_mouse

   Turns on/off the mouse handler.

   \* *Note:  This uses Perl's "alarm" feature.  If you want to use threads, then don't use this to turn on the mouse.*

   ```perl
   $fb->initialize\_mouse(1);  # Turn on the mouse handler
   ```

   or

   ```perl
   $fb->initialize\_mouse(0);  # Turn off the mouse handler
   ```

## poll\_mouse

   The mouse handler.  The "initialize\_mouse" routine sets this as the "alarm" routine to handle mouse events.

   An alarm handler just works, but can possibly block if used as ... an alarm handler.

   I suggest running it in a thread instead, using your own code.

## get\_mouse

   Returns the mouse coordinates.

   Return as an array:

   ```perl
   my ($mouseb, $mousex, $mousey) =  $fb->get_mouse();
   ```

   Return as a hash reference:

   ```perl
   my $mouse = $fb->get_mouse();
   ```

   Returns

   ```perl
   {
       'button' => button value, # Button state according to bits
                                 #  Bit 0 = Left
                                 #  Bit 1 = Right
                                 # Other bits according to driver
       'x'      => Mouse X coordinate,
       'y'      => Mouse Y coordinate,
   }
   ```

## set\_mouse

   Sets the mouse position

   ```perl
   $fb->set_mouse(
       {
           'x' => 0,
           'y' => 0,
       }
   );
   ```

   \* *NOTE:  Mouse support is very primitive and will not be further developed, as the framebuffer is not exactly mouse-friendly.*

![Divider](pics/pink.jpg?raw=true "Divider")

# USAGE HINTS

## GRADIENTS

   Gradients can have any number (actually 2 or greater) of color key points (transitions).  Vertical gradients cannot have more key points than the object is high.  Horizontal gradients cannot have more key points that the object is wide.  Just keep your gradients "sane" and things will go just fine.

   Make sure the number of color key points matches for each primary color (red, green, and blue);

## PERL OPTIMIZATION

   This module is highly CPU dependent.  So the more optimized your Perl installation is, the faster it will run.

## THREADS

   The module (using the 'threads' module) canNOT have separate threads calling the same object.  You WILL crash. However, you can instantiate an object for each thread to use on the same framebuffer, and it will work just fine.

   See the "examples/multiprocessing" directory for "threads\_primitives.pl" as an example of a threading script that uses this module.

## FORKS

   For unthreaded Perl, Install the modules **forks** and **forks::shared** and you will have the same features as **threads** and **threads::shared** (and perhaps better performance for unthreaded perls).

## MCE

   Mario Roy has tested **Graphics::Framebuffer** with various methods to use the **MCE** modules for multiprocessing, and creating a single shared library.  See the [examples/multiprocessing/MCE-README.md](examples/multiprocessing/MCE-README.md) file for more.  I highly recommend this for multiprocessing, as it should save on memory.

## BLITTING

   Use "blit\_read" and "blit\_write" to save portions of the screen instead of redrawing everything.  It will speed up response tremendously.

## SPRITES

   Someone asked me about sprites.  Well, that's what blitting is for.  You'll have to do your own collision detection.  Use **MASK\_MODE** and **UNMASK\_MODE** for drawing, and **XOR\_MODE** for removing.

   Most framebuffer drivers do not have access to GPU features.  It's just a memory map of the framebuffer.

   Listen folks, this library does everything in software (as is typical for the framebuffer), so your results will vary depending on CPU speed and screen resolution, as well as blit resolution.

## HORIZONTAL "MAGIC"

   Horizontal lines and filled boxes draw very fast, even in Perl mode, seriously.  Learn to exploit them.

## MULTIPLE "HEADS" (monitors)

   As long as each framebuffer for each display is accessible, you can open an instance of the module for each framebuffer and access each screen.

## RUNNING IN MICROSOFT WINDOWS

   It doesn't work natively, (other than in emulation mode) and likely never will.  However...

   You can run Linux inside VirtualBox and it works fine.  Put it in full screen mode, and voila, it's "running in Windows" in an indirect kinda-sorta way.  Make sure you install the VirtualBox extensions, as it has the correct video driver for framebuffer access.  It's as close as you'll ever get to get it running in MS Windows.  Seriously...

   This isn't a design choice, nor preference, nor some anti-Windows ego trip.  It's simply because of the fact MS Windows does not allow file mapping of the display, nor variable memory mapping of the display (that I know of), both are the techniques this module uses to achieve its magic.  DirectX is more like OpenGL in how it works, and thus defeats the purpose of this module.  You're better off with SDL instead, if you want to draw in MS Windows from Perl.

   \* *However, if someone knows how to access the framebuffer (or simulate one) in MS Windows, and be able to do it reasonably from within Perl, then send me instructions on how to do it, and I'll do my best to get it to work.*

![Divider](pics/pink.jpg?raw=true "Divider")

# TROUBLESHOOTING

   Ok, you've installed the module, but can't seem to get it to work properly.  Here  are some things you can try:

   \* *make sure you turn on the **SHOW\_ERRORS** parameter when calling **new** to create the object.  This helps with troubleshooting (but turn it back off for normal use).*

   - **You Have To Run From The Console**

       A console window doesn't count as "the console".  You cannot use this module from within X-Windows/Wayland.  It won't work, and likely will only go into emulation mode if you do, or maybe crash, or even corrupt your X-Windows/Wayland screen.

       If you want to run your program within X-Windows/Wayland, then you have the wrong module.  Use SDL, QT, or GTK or something similar.

       You MUST have a framebuffer based video driver for this to work.  The device ("/dev/fb0" for example) must exist.

       If it does exist, but is not "/dev/fb0", then you can define it in the **new** method with the **FB\_DEVICE** parameter, although the module is pretty good at finding it automatically.

       \* *It may be possible to get a framebuffer device with a proprietary driver by forcing Grub to go into a VESA VGA mode for the console (worked for me with NVidia).*

   - **It's Crashing**

       Ok, segfaults suck.  Believe me, I had plenty in the early days of writing this module.  There is hope for you.

       This is almost always caused by the module incorrectly calculating the framebuffer memory size, and it's guessing too large or small a memory footprint, and the system doesn't like it.

       Try running the "primitives.pl" in the "examples" directory in the following way (assuming your screen is larger than 640x480):

   ```bash
   perl examples/primitives.pl --x=640 --y=480
   ```

   This forces the module to pretend it is rendering for a smaller resolution (by placing this screen in the middle of the actual one).  If it works fine, then try changing the "x" value back to your screen's actual width, but still make the "y" value slightly smaller.  Keep decreasing this "y" value until it works.

   If you get this behavior, then it is a bug, and the author needs to be notified, although as of version 6.06 this should no longer be an issue.

- **It Only Partially Renders**

   Yeah this can look weird.  This is likely because there's some buffering going on.  The module attempts to turn it off, but if, for some reason, it is buffering anyway, try adding the following to points in your code where displaying a full render is necessary:

   ```perl
   $fb->_flush_screen();
   ```

   This should force a full screen flush, but only use this if you really need it.

   Why?  You see, the framebuffer is actually a file.  Therefore, file operations must be used to access it.  File operations are buffered.  Therefore buffers need to be flushed instead of cached for the framebuffer device.  This module actually maps this file to a variable and even more weirdness results.  Normally turning off buffering in Perl is easy, but on rare occasions it can be stubborn.  Therefore, this command was made to force it to flush, if it isn't already.

   - **It Just Plain Isn't Working**

      Well, either your system doesn't have a framebuffer driver, or perhaps the module is getting confusing data back from it and can't properly initialize (see the previous items).

      First, make sure your system has a framebuffer by seeing if `/dev/fb0` (actually "fb" then any number) exists.  If you don't see any "fb0" - "fb31" files inside "/dev" (or "/dev/fb/"), then you don't have a framebuffer driver running.  You need to fix that first.  Sometimes you have to manually load the driver with "modprobe -a drivername" (replacing "drivername" with the actual driver name).

      Second, you did the above, but still nothing.  You need to check permissions.  The account you are running this under needs to have permission to use the screen.  This typically means being a member of the "**video**" group.  Let's say the account is called "username", and you want to give it permission.  In a Linux (Debian/Ubuntu/Mint/RedHat/Fedora) environment you would use this to add "username" (your account name) to the "video" group:

   ```bash
   sudo usermod -a -G video username
   ```

   Once that is run (changing "username" to whatever your username is), log out, then log back in, and it should work.

   - **The Text Cursor Is Messing Things Up**

      It is?  Well then turn it off.  Use the $fb->cls('OFF') method to do it.  Use $fb->cls('ON') to turn it back on.

      If your script exits without turning the cursor back on, then it will still be off.  To get your cursor back, just type the command "reset" (and make sure you turn it back on before your code exits, so it doesn't do that).

      \* *UPDATE:  The new default behavior is to do this for you via the **RESET** parameter when creating the object.  See the **new** method documentation above for more information.*

   - **TrueType Printing isn't working**

      This is likely caused by the Imager library either being unable to locate the font file, or when it was compiled, it couldn't find the FreeType development libraries, and was thus compiled without TrueType text support.

      See the INSTALLATION instructions (above) on getting Imager properly compiled.  If you have a package based Perl installation, then installing the Imager (usually "libimager-perl") package will always work.  If you already installed Imager via CPAN, then you should uninstall it via CPAN, then go install the package version, in that order.  You may also install "libfreetype6-dev" and then re-install Imager via CPAN with a forced install.  If you don't want the package version but still want the CPAN version, then still uninstall what is there, then go an make sure the TrueType and FreeType development libraries are installed on your system, along with PNG, JPEG, and GIF development libraries.  Now you can go to CPAN and install Imager.

   - **It's Too Slow**

      Ok, it does say a PERL graphics library in the description, if I am not mistaken.  This means Perl is doing most of the work.  This also means it is only as fast as your system and its CPU, as it does not use your GPU at all.

      First, check to make sure the C acceleration routines are compiling properly.  Call the "acceleration" method without parameters.  It SHOULD return 1 and not 0 if C is properly compiling.  If it's not, then you need to make sure "Inline::C" is properly installed in your Perl environment.  _THIS WILL BE THE BIGGEST HELP TO YOU, IF YOU GET THIS SOLVED FIRST_.

      Second, (and this is very advanced) you could try recompiling Perl with optimizations specific to your hardware.  That can help, but this is very advanced and you should know what you are doing before attempting this.  Keep in mind that if you do this, then ALL of the modules installed via your distribution packager won't work, and will have to be reinstalled via CPAN for the new perl.  Try using **perlbrew** to do this simply for you.

      You can also try simplifying your drawing to exploit the speed of horizontal lines.  Horizonal line drawing is incredibly fast, even for very slow systems.

      Only use pixel sizes of 1.  Anything larger requires a box to be drawn at the pixel size you asked for.  Pixel sizes of 1 only use plot to draw, (so no boxes) so it is much faster.

      Try using 'polygon' to draw complex shapes instead of a series of plot or line commands.

      Does your device have more than one core?  Well, how about using threads (or MCE)?  Just make sure you do it according to the examples in the "examples" directory.  Yes, I know this can be too advanced for the average coder, but the option is there.

      Plain and simple, your device just may be too slow for some CPU intensive operations, specifically anything involving animated images and heavy blitting.  If you must use images, then make sure they are already the right size for your needs.  Don't force the module to resize them when loading, as this takes CPU time (and memory).

   - **Ask For Help**

      If none of these ideas work, then send me an email, and I may be able to get it functioning for you.  Please run the `dump.pl` script inside the "examples" directory inside this module's package:

   ```bash
   perl dump.pl
   ```

   Please include the dump file it creates (dump.log) **as a file attachment** to your email.  Please do _not_ include it inline as part of the message text.

   Also, please include a copy of your code (or at least the portion of it where you initialize this module and are having issues), AND explain to me your hardware and OS it is running under.

   Screen shots and photos are also helpful.

   **KNOW THIS:**  I want to get it working on your system, and I will do everything I can to help you get it working, but there may be some conditions where that may not be possible.  It's very rare (and I haven't seen it yet), but possible.

   I am not one of those arrogant ogres that spout "RTFM" every time someone asks for help (although it helps if you do read the manual).  I actually will help you.  Please be patient, as I do have other responsibilities that may delay a response, but a response will come.

   *\\* *Making the subject of your [email](mailto:rich@rk-internet.com) "**PERL GFB HELP**" is most helpful for me, and likely will get your email seen sooner.*

![Divider](pics/pink.jpg?raw=true "Divider")

# AUTHOR

   Richard Kelsch <rich@rk-internet.com>

![Divider](pics/pink.jpg?raw=true "Divider")

# COPYRIGHT

   Copyright © 2003-2026 Richard Kelsch, All Rights Reserved.

   This program is free software; you can redistribute it and/or modify it under the GNU software license.

![Divider](pics/pink.jpg?raw=true "Divider")

# LICENSE

   This program is free software; you can redistribute it and/or modify it under the terms of the the Artistic License (2.0). You may obtain a copy of the full license at:

   [https://perlfoundation.org/artistic-license-20.html](https://perlfoundation.org/artistic-license-20.html)

   Any use, modification, and distribution of the Standard or Modified Versions is governed by this Artistic License. By using, modifying or distributing the Package, you accept this license. Do not use, modify, or distribute the Package, if you do not accept this license.

   If your Modified Version has been derived from a Modified Version made by someone other than you, you are nevertheless required to ensure that your Modified Version complies with the requirements of this license.

   This license does not grant you the right to use any trademark, service mark, tradename, or logo of the Copyright Holder.

   This license includes the non-exclusive, worldwide, free-of-charge patent license to make, have made, use, offer to sell, sell, import and otherwise transfer the Package with respect to any patent claims licensable by the Copyright Holder that are necessarily infringed by the Package. If you institute patent litigation (including a cross-claim or counterclaim) against any party alleging that the Package constitutes direct or contributory patent infringement, then this Artistic License to you shall terminate on the date that such litigation is filed.

   Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES. THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

![Divider](pics/pink.jpg?raw=true "Divider")

# VERSION

   Version 6.96 (Apr 06, 2026)

![Divider](pics/pink.jpg?raw=true "Divider")

# THANKS

   My thanks go out to those using this module and submitting helpful patches and suggestions for improvement, as well as those who asked for help.  Your requests for help actually gave me ideas.

   Thank you Mario Roy for showing how to use MCE to multiprocess instead of threads.  Very handy.  Look for the "get\_mce\_demos" in the "examples" directory.  NOTE: I do not support MCE bug issues.

![Divider](pics/pink.jpg?raw=true "Divider")

# TELL ME ABOUT YOUR PROJECT

   I'd love to know if you are using this library in your project.  So send me an email, with pictures and/or a URL (if you have one) showing what it is.  If you have a YouTube video, then that would be cool to see too.

   If project has a specific need that the module does not support (or support easy), then suggest a feature to me.

![Divider](pics/pink.jpg?raw=true "Divider")

# YOUTUBE

   There is a YouTube channel with demonstrations of the module's capabilities.  Eventually it will have examples of output from a variety of different types of hardware.

   [YouTube Graphics::Framebuffer Channel](https://www.youtube.com/@richardkelsch3640)

![Divider](pics/pink.jpg?raw=true "Divider")

# GITHUB

   [GitHub Graphics::Framebuffer](https://github.com/richcsst/Graphics-Framebuffer)

   Clone

   ```bash
   git clone https://github.com/richcsst/Graphics-Framebuffer.git
   ```
