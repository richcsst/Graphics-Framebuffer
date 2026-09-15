#!/usr/bin/env perl
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case);
use File::Spec;

# File locations in shared memory
my $SHM_DIR    = '/dev/shm';
my $FB_FILE    = "$SHM_DIR/gfb_screen";
my $INFO_FILE  = "$SHM_DIR/gfb_screen.info";

# Configuration defaults
my $res_param  = '1280x720x32';
my $framerate  = 15;

GetOptions(
    'r|res=s' => \$res_param,
    'f|fps=i' => \$framerate,
    'h|help'  => \&show_help,
) or exit 1;

# Accept standalone geometry argument if passed directly (e.g. ./gfb_viewer 800x600x32)
$res_param = $ARGV[0] if (defined $ARGV[0] && $ARGV[0] =~ /^\d+x\d+(?:x\d+)?$/i);

# Parse resolution (WIDTHxHEIGHTxBPP)
my ($width, $height, $bpp);
if ($res_param =~ /^(\d+)x(\d+)(?:x(\d+))?$/i) {
    $width  = int($1);
    $height = int($2);
    $bpp    = defined($3) ? int($3) : 32;
} else {
    die "Error: Invalid resolution format '$res_param'. Expected WIDTHxHEIGHTxBPP (e.g., 1024x720x32).\n";
}

# Determine matching raw video pixel format for ffplay / mplayer
my $pix_fmt;
if ($bpp == 32) {
    $pix_fmt = 'bgr0';
} elsif ($bpp == 24) {
    $pix_fmt = 'bgr24';
} elsif ($bpp == 16) {
    $pix_fmt = 'rgb565le';
} else {
    die "Error: Unsupported bits-per-pixel: $bpp (Supported: 16, 24, 32).\n";
}

my $buffer_size = $width * $height * int($bpp / 8);

# Set up signal traps to guarantee cleanup if interrupted
$SIG{INT}  = sub { exit 0; };
$SIG{TERM} = sub { exit 0; };
$SIG{HUP}  = sub { exit 0; };

# Create/truncate /dev/shm/gfb_screen
open(my $fh_fb, '>', $FB_FILE)
    or die "Error: Cannot open $FB_FILE: $!\n";
truncate($fh_fb, $buffer_size)
    or die "Error: Cannot truncate $FB_FILE to $buffer_size bytes: $!\n";
close($fh_fb);

# Create /dev/shm/gfb_screen.info (expects space-delimited: "WIDTH HEIGHT BPP")
open(my $fh_info, '>', $INFO_FILE)
    or die "Error: Cannot write $INFO_FILE: $!\n";
print $fh_info "$width $height $bpp\n";
close($fh_info);

print "[gfb_viewer] Initialized: $FB_FILE ($width x $height @ ${bpp}bpp, $buffer_size bytes)\n";
print "[gfb_viewer] Config:      $INFO_FILE ($width $height $bpp)\n";

# Construct media player command
# Calculate the sleep delay in seconds based on target framerate
my $sleep_delay = sprintf("%.3f", (1.0 / $framerate) * 0.85);

my $cmd_str = sprintf(
    'while [ -e %s ]; do cat %s; sleep %s; done | ffplay -loglevel quiet -nostats -f rawvideo -pixel_format %s -video_size %dx%d -framerate %d -window_title "Graphics::Framebuffer Viewer [%dx%d]" -i -',
    $FB_FILE, $FB_FILE, $sleep_delay,
    $pix_fmt,
    $width, $height,
    $framerate,
    $width, $height
);

system('bash', '-c', $cmd_str);

# END block ensures cleanup executes regardless of how the script terminates
END {
    if (-e $FB_FILE) {
        unlink($FB_FILE) or warn "Warning: Could not remove $FB_FILE: $!\n";
    }
    if (-e $INFO_FILE) {
        unlink($INFO_FILE) or warn "Warning: Could not remove $INFO_FILE: $!\n";
    }
    print "[gfb_viewer] Shared memory files removed cleanly.\n";
}

sub show_help {
    print <<"HELP";
Usage: $0 [options] [WIDTHxHEIGHTxBPP]

Options:
  -r, --res <WxHxB>    Set display resolution (default: 1280x720x32)
  -f, --fps <num>      Set frame rate polling (default: 15)
  -h, --help           Display this help screen

Examples:
  $0
  $0 1920x1080x32
  $0 -r 800x600x16 -f 60
HELP
    exit 0;
}