#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use File::Map qw(map_file);
use Time::HiRes qw(sleep time);

# File locations in shared memory
my $SHM_DIR   = '/dev/shm';
my $FB_FILE   = "$SHM_DIR/gfb_screen";
my $INFO_FILE = "$SHM_DIR/gfb_screen.info";

# Configuration defaults
my $res_param = '1280x720x32';
my $framerate = 30;

GetOptions(
    'r|res=s' => \$res_param,
    'f|fps=i' => \$framerate,
    'h|help'  => \&show_help,
) or exit 1;

$res_param = $ARGV[0] if (defined $ARGV[0] && $ARGV[0] =~ /^\d+x\d+(?:x\d+)?$/i);

my ($width, $height, $bpp);
if ($res_param =~ /^(\d+)x(\d+)(?:x(\d+))?$/i) {
    $width  = int($1);
    $height = int($2);
    $bpp    = defined($3) ? int($3) : 32;
} else {
    die "Error: Invalid resolution format '$res_param'.\n";
}

my $pitch = $width * int($bpp / 8);
my $buffer_size = $pitch * $height;

# Clean termination handlers
my $running = 1;
$SIG{INT}  = sub { $running = 0; };
$SIG{TERM} = sub { $running = 0; };
$SIG{HUP}  = sub { $running = 0; };

# Create/truncate /dev/shm/gfb_screen
open(my $fh_fb, '+>', $FB_FILE) or die "Cannot open $FB_FILE: $!\n";
truncate($fh_fb, $buffer_size)   or die "Cannot truncate $FB_FILE: $!\n";
close($fh_fb);

# Write screen info
open(my $fh_info, '>', $INFO_FILE) or die "Cannot write $INFO_FILE: $!\n";
print $fh_info "$width $height $bpp\n";
close($fh_info);

print "[gfb_viewer] Initialized: $FB_FILE ($width x $height @ ${bpp}bpp)\n";

END {
    unlink($FB_FILE)   if -e $FB_FILE;
    unlink($INFO_FILE) if -e $INFO_FILE;
    print "[gfb_viewer] Cleaned up /dev/shm files.\n";
}

# Map the shared memory directly
map_file(my $shm_buffer, $FB_FILE, '+<');

# Load SDL
require SDL;
require SDL::Video;
require SDL::Surface;
require SDL::Event;
require SDL::Events;

SDL::init(SDL::INIT_VIDEO());

my $screen = SDL::Video::set_video_mode(
    $width, $height, $bpp,
    SDL::SWSURFACE() | SDL::RESIZABLE()
);
die "Error: Failed to create SDL window: " . SDL::get_error() . "\n" unless $screen;

SDL::Video::wm_set_caption("Graphics::Framebuffer Viewer [$width x $height]", "GFB Viewer");

# Define color channel masks according to bpp
my ($rmask, $gmask, $bmask, $amask) = (0, 0, 0, 0);
if ($bpp == 32) {
    $rmask = 0x00FF0000;
    $gmask = 0x0000FF00;
    $bmask = 0x000000FF;
    $amask = 0xFF000000;
} elsif ($bpp == 16) {
    $rmask = 0xF800;
    $gmask = 0x07E0;
    $bmask = 0x001F;
}

my $event = SDL::Event->new();
my $delay = 1.0 / $framerate;

print "[gfb_viewer] Window active. Polling at ${framerate} FPS...\n";

while ($running) {
    my $t0 = time;

    # Properly pass the pre-allocated $event object
    while (SDL::Events::poll_event($event)) {
        my $type = $event->type();
        if ($type == SDL::QUIT() || ($type == SDL::KEYDOWN() && $event->key_sym() == SDL::SDLK_ESCAPE())) {
            $running = 0;
            last;
        }
    }

    # Blit shared memory buffer to the SDL screen
    my $source = SDL::Surface->new_from(
        $shm_buffer,
        $width, $height, $bpp,
        $pitch,
        $rmask, $gmask, $bmask, $amask
    );

    if ($source) {
        SDL::Video::blit_surface($source, SDL::Rect->new(0, 0, $width, $height),
                                 $screen, SDL::Rect->new(0, 0, $width, $height));
        SDL::Video::update_rect($screen, 0, 0, $width, $height);
    }

    my $elapsed = time - $t0;
    my $sleep_time = $delay - $elapsed;
    sleep($sleep_time) if ($sleep_time > 0);
}

sub show_help {
    print "Usage: $0 [options] [WIDTHxHEIGHTxBPP]\n";
    exit 0;
}