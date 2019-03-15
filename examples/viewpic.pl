#!/usr/bin/perl

# A simple utility to view a picture from the command line
#
# The first option should be the file name to show

use strict;

use Graphics::Framebuffer;
use Time::HiRes qw(sleep time alarm);
use Getopt::Long;

# use Data::Dumper::Simple;$Data::Dumper::Sortkeys=1;
exit(0) unless(scalar(@ARGV));
my $file = $ARGV[-1];

my $full    = FALSE;
my $noclear = FALSE;
my $delay   = 10;
my $alpha   = 255;

GetOptions(
    'full'    => \$full,
    'wait=i'  => \$delay,
    'noclear' => \$noclear,
    'alpha=i' => \$alpha,
);

our $f = Graphics::Framebuffer->new(
    'SPLASH'      => FALSE,
    'SHOW_ERRORS' => FALSE,
    'RESET'       => 1 - $noclear,
);

$SIG{'KILL'} = $SIG{'QUIT'} = $SIG{'INT'} = $SIG{'HUP'} = sub { exec('reset'); };

my $info = $f->screen_dimensions();

system('clear');
$f->cls('OFF');

# This centers and shows the picture by proportionally scaling the height and width
my %p = (
    'file'   => $file,
    'center' => CENTER_XY
);
if ($full) {
    $p{'width'}  = $f->{'XRES'};
    $p{'height'} = $f->{'YRES'};
}

my $image = $f->load_image(\%p);

if (ref($image) eq 'ARRAY') {
    my $s = time + $delay;
    while (time < $s) {
        $f->play_animation($image, 1);
    }
} else {
    if ($alpha < 255) {
        my $size = length($image->{'image'}) / $f->{'BYTES'};
        $image->{'image'} &= pack('C4', 255, 255, 255, 0) x $size;
        $image->{'image'} |= pack('C4', 0, 0, 0, $alpha) x $size;
        $f->alpha_mode();
    } else {
        $f->normal_mode();
    }
    $f->blit_write($image);
    sleep $delay if ($delay);
}

=head1 NAME

Picture View

=head1 DESCRIPTION

Single image (or animation) viewer

=head1 SYNOPISIS

 perl viewpic.pl [options] "path to image"

=head1 OPTIONS

=over 2

=item B<--full>

Tells it to scale (proportionally) all images (and animations) to full screen.

=item B<--alpha>=1-254

Alpha value to overlay an image on what is already there.  Usually used to just dim the image.  Comes in handy for using with fbterm to make a background image.

=item B<--wait>=seconds

Wait number of seconds before returning (0=don't wait)

=back

=head1 COPYRIGHT

Copyright (C) 2010 - 2019 Richard Kelsch
All Rights Reserved

=head1 LICENSE

GNU Public License Version 3.0

* See the "LICENSE" file in this distribution for this license.

=cut
