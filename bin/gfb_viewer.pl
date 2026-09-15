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

my $buffer_size = $width * $height * int($bpp / 8);

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

# END block cleans up SHM nodes on exit
END {
    unlink($FB_FILE)   if -e $FB_FILE;
    unlink($INFO_FILE) if -e $INFO_FILE;
    print "[gfb_viewer] Cleaned up /dev/shm files.\n";
}

# Map the shared memory directly into this process
map_file(my $shm_buffer, $FB_FILE, '+<');

# Prefer native SDL loop if installed, otherwise fallback to a pipe streamer
eval {
    require SDL;
    require SDLx::App;
    require SDL::Surface;
};

if (!$@) {
    print "[gfb_viewer] Running native SDL display loop...\n";
    my $app = SDLx::App->new(
        title  => "Graphics::Framebuffer Viewer [$width x $height]",
        width  => $width,
        height => $height,
        depth  => $bpp,
    );

    my $delay = 1.0 / $framerate;

    while ($running) {
        my $t0 = time;

        # Pump events so window stays responsive and moveable
        while (my $event = SDL::Events::poll_event()) {
            if ($event->type == SDL::Events::SDL_QUIT()) {
                $running = 0;
                last;
            }
        }

        # Create a surface directly from the shared memory buffer and blit
        my $source_surface = SDL::Surface->new_from(
            $shm_buffer,
            $width, $height, $bpp,
            $width * int($bpp / 8)
        );

        $source_surface->blit($app);
        $app->update();

        my $spent = time - $t0;
        my $sleep_time = $delay - $spent;
        sleep($sleep_time) if $sleep_time > 0;
    }
} else {
    # Fallback: Zero-overhead raw stream via ffmpeg pipe if SDL-perl is not installed
    print "[gfb_viewer] SDL-perl not detected, using continuous pipe reader...\n";
    my $pix_fmt = ($bpp == 32) ? 'bgr0' : ($bpp == 24 ? 'bgr24' : 'rgb565le');

    my $pipe_cmd = sprintf(
        'tail -f -c +1 %s 2>/dev/null | ffplay -loglevel quiet -stats 0 -f rawvideo -pixel_format %s -video_size %dx%d -framerate %d -window_title "Graphics::Framebuffer Viewer [%dx%d]" -i -',
        $FB_FILE, $pix_fmt, $width, $height, $framerate, $width, $height
    );

    system('bash', '-c', $pipe_cmd);
}

sub show_help {
    print "Usage: $0 [options] [WIDTHxHEIGHTxBPP]\n";
    exit 0;
}