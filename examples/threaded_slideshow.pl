#!/usr/bin/env perl

# Fixes to center image in its own assigned block.

use strict;

use threads (
    'yield',
    'stringify',
    'stack_size' => 16 * 4096, # No need for a large stack
    'exit'       => 'threads_only',
);
use threads::shared;
use Graphics::Framebuffer;
use Time::HiRes qw(sleep time alarm);
use List::Util qw(shuffle);
use Getopt::Long;
use Pod::Usage;
use Sys::CPU;
use File::HomeDir;

## I only use this for debugging
# use Data::Dumper::Simple; $Data::Dumper::Sortkeys = 1; $Data::Dumper::Purity = 1;

my $errors           = FALSE;
my $auto             = FALSE;
my $showall          = FALSE;
my $help             = FALSE;
my $delay            = 3;
my $nosplash         = FALSE;
my $noaccel          = FALSE;
my $threads          = Sys::CPU::cpu_count() * 2;
my $RUNNING : shared = TRUE;
my $default_path     = File::HomeDir->my_home() . '/Pictures/';
our $GO : shared     = FALSE;

GetOptions(
    'auto'         => \$auto,
    'errors'       => \$errors,
    'showall|all'  => \$showall,
    'help'         => \$help,
    'delay|wait=i' => \$delay,
    'nosplash'     => \$nosplash,
    'noaccel'      => \$noaccel,
    'threads=i'    => \$threads,
);
my @paths = @ARGV;

unless (scalar(@paths) && !$help) {
    push(@paths,$default_path);
}

if ($help) {
    pod2usage('-exitstatus' => 1, '-verbose' => $help);
}

my $splash = ($nosplash) ? 0 : 3;

my @devs;

our @fb;

# Look for all of the framebuffers
foreach my $dev (0 .. 31) {
    foreach my $path ('fb','graphics/fb') {
        if (-e "/dev/$path$dev") {
            push(@devs,"/dev/$path$dev");
        }
    }
}

$SIG{'QUIT'} = \&finish;
$SIG{'INT'}  = \&finish;
$SIG{'KILL'} = \&finish;
my $p = gather(@paths);

if ($errors) {
    print STDERR qq{

AUTO            = $auto
ERRORS          = $errors
SHOWALL         = $showall
DELAY           = $delay
NOSPLASH        = $nosplash
CPU             = }, Sys::CPU::cpu_type(), qq{
THREADS         = $threads
DEVICES         = }, join(', ',@devs), qq{
PATH(s)         = }, join('; ', @paths), "\n";

    sleep 5;
} ## end if ($errors)

my @thrd;

$threads /= scalar(@devs);

# Run the slides in threads and have the main thread do housekeeping.
my $showit = $splash;
for (my $t = 0; $t < $threads; $t++) {
    foreach my $f (@devs) {
        $thrd[$t] = threads->create({'context' => 'scalar'}, \&show, $f, $p, $threads, $t, $showit, $delay);
        sleep (1 / $threads); # Skew
    }
    sleep $showit if ($showit);
    $showit = FALSE;
}

while ($RUNNING) {    # Monitors the running threads and restores them if one dies
    my $num = scalar(threads::list(threads::running));
    if ($RUNNING && $num < $threads) {
        for (my $t = 0; $t < $threads; $t++) {
            if ($RUNNING) {
                unless ($thrd[$t]->is_running()) {
                    eval { $thrd[$t]->kill('KILL')->detach(); };
                    $thrd[$t] = threads->create({'context' => 'scalar'}, \&show, $p, $threads, $t, $delay);
                }
            } ## end if ($RUNNING)
        } ## end for (my $t = 0; $t < $threads...)
    } else {
        sleep 1;
    }
} ## end while ($RUNNING)

exit(0);

sub finish {
    $RUNNING = 0;
    alarm 0;
    $SIG{'ALRM'} = sub {
        exec('reset');
    };
    alarm 20;
    print "\n\nSHUTTING DOWN...\n\n";
    # Just brute for kill the threads for speed.  No need to be as elegant as before
    foreach my $thr (threads->list()) {
        $thr->kill('KILL')->detach();
    }
    exec('reset');
} ## end sub finish

sub gather {
    my @paths = @_;
    my @pics;
    foreach my $path (@paths) {
        chop($path) if ($path =~ /\/$/);
        print STDOUT "Scanning - $path\n";
        opendir(my $DIR, "$path") || die "Problem reading $path directory";
        chomp(my @dir = readdir($DIR));
        closedir($DIR);

        return if (!$showall && grep(/^\.nomedia$/, @dir));
        foreach my $file (@dir) {
            next if ($file =~ /^\.+/);
            if (-d "$path/$file") {
                my $r = gather("$path/$file");
                if (defined($r)) {
                    @pics = (@pics, @{$r});
                }
            } elsif (-f "$path/$file" && $file =~ /\.(jpg|jpeg|gif|tiff|bmp|png)$/i) {
                push(@pics, "$path/$file");
            }
        } ## end foreach my $file (@dir)
    } ## end foreach my $path (@paths)
    return (\@pics);
} ## end sub gather

sub calculate_window {
    my $max     = shift;
    my $current = shift;
    my $width   = shift;
    my $height  = shift;

    my $cr = [
        [ # 1
            [0,0,$width,$height],
        ],
        [ # 2 2x0
            [0,0,($width/2),$height],
            [($width/2),0,($width/2),$height]
        ],
        [ # 3 3x0
            [0,0,($width/3),$height],
            [($width/3),0,($width/3),$height],
            [(2 * ($width/3)), 0, ($width/3), $height ],
        ],
        [ # 4 2x2
            [0,0,($width/2),($height/2)],
            [($width/2),0,($width/2),($height/2)],

            [0,($height/2),($width/2),($height/2)],
            [($width/2),($height/2),($width/2),($height/2)],
        ],
        [ # 5 3x2
            [0,0,($width/3),($height/2)],
            [($width/3),0,($width/3),($height/2)],
            [(2 * ($width/3)),0,($width/3),($height/2)],

            [0,($height/2),($width/2),($height/2)],
            [($width/2),($height/2),($width/2),($height/2)],
        ],
        [ # 6 3x3
            [0,0,($width/3),($height/2)],
            [($width/3),0,($width/3),($height/2)],
            [( 2 * ($width/3)), 0, ($width/3), ($height/2)],

            [0,($height/2),($width/3),($height/2)],
            [($width/3),($height/2),($width/3),($height/2)],
            [(2 * ($width/3)),($height/2),($width/3),($height/2)],
        ],
        [ # 7 4x3
            [0, 0, ($width/4), ($height/2)],
            [($width/4), 0, ($width/4), ($height/2)],
            [(2 * ($width/4)), 0, ($width/4), ($height/2)],
            [(3 * ($width/4)), 0, ($width/4), ($height/2)],

            [0,($height/2),($width/3),($height/2)],
            [($width/3),($height/2),($width/3),($height/2)],
            [(2 * ($width/3)), ($height/2), ($width/3)],
        ],
        [ # 8 4x4
            [0, 0, ($width/4), ($height/2)],
            [($width/4), 0, ($width/4), ($height/2)],
            [(2 * ($width/4)), 0, ($width/4), ($height/2)],
            [(3 * ($width/4)), 0, ($width/4), ($height/2)],

            [0, ($height/2), ($width/4), ($height/2)],
            [($width/4), ($height/2), ($width/4), ($height/2)],
            [(2 * ($width/4)), ($height/2), ($width/4), ($height/2)],
            [(3 * ($width/4)), ($height/2), ($width/4), ($height/2)],
        ],
        [ # 9 5x4
            [0, 0, ($width/5), ($height/2)],
            [($width/5), 0, ($width/5), ($height/2)],
            [(2 * ($width/5)), 0, ($width/5), ($height/2)],
            [(3 * ($width/5)), 0, ($width/5), ($height/2)],
            [(4 * ($width/5)), 0, ($width/5), ($height/2)],

            [0, ($height/2), ($width/4), ($height/2)],
            [($width/4), ($height/2), ($width/4), ($height/2)],
            [(2 * ($width/4)), ($height/2), ($width/4), ($height/2)],
            [(3 * ($width/4)), ($height/2), ($width/4), ($height/2)],
        ],
        [ # 10 5x5
            [0, 0, ($width/5), ($height/2)],
            [($width/5), 0, ($width/5), ($height/2)],
            [(2 * ($width/5)), 0, ($width/5), ($height/2)],
            [(3 * ($width/5)), 0, ($width/5), ($height/2)],
            [(4 * ($width/5)), 0, ($width/5), ($height/2)],

            [0, ($height/2), ($width/5), ($height/2)],
            [($width/5), ($height/2), ($width/5), ($height/2)],
            [(2 * ($width/5)), ($height/2), ($width/5), ($height/2)],
            [(3 * ($width/5)), ($height/2), ($width/5), ($height/2)],
            [(4 * ($width/5)), ($height/2), ($width/5), ($height/2)],
        ],
        [ # 11 4x4x3
            [0, 0, ($width/4), ($height/3)],
            [($width/4), 0, ($width/4), ($height/3)],
            [(2 * ($width/4)), 0, ($width/4), ($height/3)],
            [(3 * ($width/4)), 0, ($width/4), ($height/3)],

            [0, ($height/3), ($width/4), ($height/3)],
            [($width/4), ($height/3), ($width/4), ($height/3)],
            [(2 * ($width/4)), ($height/3), ($width/4), ($height/3)],
            [(3 * ($width/4)), ($height/3), ($width/4), ($height/3)],

            [0, (2 * ($height/3)), ($width/3), ($height/3)],
            [($width/3), (2 * ($height/3)), ($width/3), ($height/3)],
            [(2 * ($width/3)), (2 * ($height/3)), ($width/3), ($height/3)],
        ],
        [ # 12 4x4x4
            [0, 0, ($width/4),($height/3)],
            [($width/4), 0, ($width/4),($height/3)],
            [(2 * ($width/4)), 0, ($width/4),($height/3)],
            [(3 * ($width/4)), 0, ($width/4),($height/3)],

            [0, ($height/3), ($width/4),($height/3)],
            [($width/4), ($height/3), ($width/4),($height/3)],
            [(2 * ($width/4)), ($height/3), ($width/4),($height/3)],
            [(3 * ($width/4)), ($height/3), ($width/4),($height/3)],

            [0, (2 * ($height/3)), ($width/4),($height/3)],
            [($width/4), (2 * ($height/3)), ($width/4),($height/3)],
            [(2 * ($width/4)), (2 * ($height/3)), ($width/4),($height/3)],
            [(3 * ($width/4)), (2 * ($height/3)), ($width/4),($height/3)],
        ],
        [ # 13 5x4x4
            [0, 0, ($width/5),($height/3)],
            [($width/5), 0, ($width/5),($height/3)],
            [(2 * ($width/5)), 0, ($width/5),($height/3)],
            [(3 * ($width/5)), 0, ($width/5),($height/3)],
            [(4 * ($width/5)), 0, ($width/5),($height/3)],

            [0, ($height/3), ($width/4),($height/3)],
            [($width/4), ($height/3), ($width/4),($height/3)],
            [(2 * ($width/4)), ($height/3), ($width/4),($height/3)],
            [(3 * ($width/4)), ($height/3), ($width/4),($height/3)],

            [0, (2 * ($height/3)), ($width/4),($height/3)],
            [($width/4), (2 * ($height/3)), ($width/4),($height/3)],
            [(2 * ($width/4)), (2 * ($height/3)), ($width/4),($height/3)],
            [(3 * ($width/4)), (2 * ($height/3)), ($width/4),($height/3)],
        ],
        [ # 14 5x5x4
            [0, 0, ($width/5),($height/3)],
            [($width/5), 0, ($width/5),($height/3)],
            [(2 * ($width/5)), 0, ($width/5),($height/3)],
            [(3 * ($width/5)), 0, ($width/5),($height/3)],
            [(4 * ($width/5)), 0, ($width/5),($height/3)],

            [0, ($height/3), ($width/5),($height/3)],
            [($width/5), ($height/3), ($width/5),($height/3)],
            [(2 * ($width/5)), ($height/3), ($width/5),($height/3)],
            [(3 * ($width/5)), ($height/3), ($width/5),($height/3)],
            [(4 * ($width/5)), ($height/3), ($width/5),($height/3)],

            [0, (2 * ($height/3)), ($width/4),($height/3)],
            [($width/4), (2 * ($height/3)), ($width/4),($height/3)],
            [(2 * ($width/4)), (2 * ($height/3)), ($width/4),($height/3)],
            [(3 * ($width/4)), (2 * ($height/3)), ($width/4),($height/3)],
        ],
        [ # 15 5x5x5
            [0, 0, ($width/5),($height/3)],
            [($width/5), 0, ($width/5),($height/3)],
            [(2 * ($width/5)), 0, ($width/5),($height/3)],
            [(3 * ($width/5)), 0, ($width/5),($height/3)],
            [(4 * ($width/5)), 0, ($width/5),($height/3)],

            [0, ($height/3), ($width/5),($height/3)],
            [($width/5), ($height/3), ($width/5),($height/3)],
            [(2 * ($width/5)), ($height/3), ($width/5),($height/3)],
            [(3 * ($width/5)), ($height/3), ($width/5),($height/3)],
            [(4 * ($width/5)), ($height/3), ($width/5),($height/3)],

            [0, (2 * ($height/3)), ($width/5),($height/3)],
            [($width/5), (2 * ($height/3)), ($width/5),($height/3)],
            [(2 * ($width/5)), (2 * ($height/3)), ($width/5),($height/3)],
            [(3 * ($width/5)), (2 * ($height/3)), ($width/5),($height/3)],
            [(4 * ($width/5)), (2 * ($height/3)), ($width/5),($height/3)],
        ],
        [ # 16 4x4x4x4
            [0, 0, ($width/4), ($height/4)],
            [($width/4), 0, ($width/4), ($height/4)],
            [(2 * ($width/4)), 0, ($width/4), ($height/4)],
            [(3 * ($width/4)), 0, ($width/4), ($height/4)],

            [0, ($height/4), ($width/4), ($height/4)],
            [($width/4), ($height/4), ($width/4), ($height/4)],
            [(2 * ($width/4)), ($height/4), ($width/4), ($height/4)],
            [(3 * ($width/4)), ($height/4), ($width/4), ($height/4)],

            [0, (2 * ($height/4)), ($width/4), ($height/4)],
            [($width/4), (2 * ($height/4)), ($width/4), ($height/4)],
            [(2 * ($width/4)), (2 * ($height/4)), ($width/4), ($height/4)],
            [(3 * ($width/4)), (2 * ($height/4)), ($width/4), ($height/4)],

            [0, (3 * ($height/4)), ($width/4), ($height/4)],
            [($width/4), (3 * ($height/4)), ($width/4), ($height/4)],
            [(2 * ($width/4)), (3 * ($height/4)), ($width/4), ($height/4)],
            [(3 * ($width/4)), (3 * ($height/4)), ($width/4), ($height/4)],
        ],
    ];
    return (@{$cr->[$max - 1]->[$current - 1]});
} ## end sub calculate_window

sub show {
    my $dev     = shift;
    my $ps      = shift;
    my $jobs    = shift;
    my $job     = shift;
    my $display = shift;
    my $delay   = shift;

    local $SIG{'ALRM'} = undef;
    local $SIG{'INT'}  = sub { threads->exit(); };
    local $SIG{'QUIT'} = sub { threads->exit(); };
    local $SIG{'KILL'} = sub { threads->exit(); };

    my $FB = Graphics::Framebuffer->new(
        'SHOW_ERRORS' => $errors,
        'RESET'       => 1,
        'SPLASH'      => $splash,
        'ACCELERATED' => !$noaccel,
        'FB_DEVICE'   => $dev,
        'SPLASH'      => $display,
    );
    $FB->set_color({ 'red' => 0, 'green' => 0, 'blue' => 0, 'alpha' => 255 });
    my @pics = shuffle(@{$ps});
    my $p    = scalar(@pics);
    my $idx  = 0;
    my ($X, $Y, $W, $H) = calculate_window($jobs, $job, $FB->{'XRES'}, $FB->{'YRES'});
    while ($RUNNING && $idx < $p) {
        my $name = $pics[$idx];
        my $image = $FB->load_image( # Uninterruptible at the moment
            {
                'x'          => $X,
                'y'          => $Y,
                'width'      => $W,
                'height'     => $H,
                'file'       => $name,
                'autolevels' => $auto
            }
        );
        my $tdelay;
        if (ref($image) eq 'ARRAY') {
            $tdelay = $delay - $image->[-1]->{'benchmark'}->{'total'};
        } else {
            $tdelay = $delay - $image->{'benchmark'}->{'total'};
        }
        $tdelay = 0 if ($tdelay < 0);
        if (defined($image)) {
            if ($display) {
                $display = FALSE;
                $FB->cls('OFF');
                $GO = TRUE;
            } else {
                if ($GO) {
                    sleep $tdelay * $RUNNING;
                } else {
                    while (! $GO && $RUNNING) {
                        threads->yield();
                    }
                }
            }
            $FB->rbox({ 'x' => $X, 'y' => $Y, 'width' => $W, 'height' => $H, 'filled' => 1 });
            if (ref($image) eq 'ARRAY') {
                my $s = time + ($delay * 2);
                while ($RUNNING && time <= $s) {    # We play it as many times as the delay allows, but at least once.
                                                    # We don't use "play_animation" for threads.  This is so we can stop the playback quickly.
                    for (my $frame = 0; $frame < scalar(@{$image}); $frame++) {
                        my $begin = time;                     # Mark the start time
                        $FB->blit_write($image->[$frame]);    # Write the frame to the display
                                                              # Multiply the 'gif_delay' by 0.01 and then subtract from that the amount of time
                                                              # it took to actually display the frame.  This givs the true delay, which should
                                                              # show an accurate animation.
                        my $d = (($image->[$frame]->{'tags'}->{'gif_delay'} * .01) - (time - $begin));
                        threads->yield();
                        sleep $d if ($d > 0);
                        last unless ($RUNNING);
                    } ## end for (my $frame = 0; $frame...)
                } ## end while ($RUNNING && time <=...)
            } else {
                if ($image->{'width'} < $W) {
                    my $x = ($W - $image->{'width'}) / 2;
                    $image->{'x'} += $x;
                }
                $FB->blit_write($image);
                threads->yield();
            }
        } ## end if (defined($image))
        $idx++;
        $idx = 0 if ($idx >= $p);
    } ## end while ($RUNNING && $idx <...)
    $FB->rbox({ 'x' => $X, 'y' => $Y, 'width' => $W, 'height' => $H, 'filled' => 1 });
    $FB->cls('ON') if ($display);
    return(1);
} ## end sub show


__END__

=pod

=head1 NAME

Slide Show

=head1 DESCRIPTION

Framebuffer Slide Show

This automatically detects all of the framebuffer devices in your system, and shows the images in the images path, in a random order, on the primary framebuffer device (the first it finds).

=head1 SYNOPSIS

 perl threaded_slideshow.pl [options] ["/path/to/scan"]

More than one path can be used.  Just separate each path by a space.

If no path is given, then the current user's "Pictures" directory will be used.

=head2 OPTIONS

=over 2

=item B<--auto>

Turns on auto color level mode.  Sometimes this yields great results... and sometimes it totally ugly's things up

=item B<--errors>

Allows the module to print errors to STDERR, as well as some minimal initial debugging data.

=item B<--delay>=seconds

Number of seconds to wait before loading the next image.  It can take longer to load animated GIFs.

Default is 3 seconds.

=item B<--showall>

Ignores any ".nomedia" files in subdirectories, and shows the images in them anyway.  Typically ".nomedia" is used for risque pictures.  Adding this file simply means using "touch .nomedia" in the directory you want to ignore.

=item B<--threads>=1-16

The program automatically determines the number of threads, and assigns two to each core.  However, you can override this number with this switch, up to 16.

Keep in mind, a thread takes up memory.  So the more threads you have (and animations) the easier it is for the program to crash with an out of memory error.  This isn't a bug, just a limitation in your own system.  I have tried to make sure memory is managed as best it can be.

=back

=head1 COPYRIGHT

Copyright 2019 Richard Kelsch
All Rights Reserved

=head1 LICENSE

GNU Public License Version 3.0

* See the "LICENSE" file in the distribution for this license.

=cut
