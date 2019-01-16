#!/usr/bin/env perl

use strict;

use threads;
use threads::shared;
use Graphics::Framebuffer;
use Time::HiRes qw(sleep time alarm);
use List::Util qw(shuffle);
use Getopt::Long;
use Pod::Usage;
use Sys::CPU;

# use Data::Dumper::Simple; $Data::Dumper::Sortkeys = 1;

my $errors     = 0;
my $auto       = 0;
my $showall    = 0;
my $help       = 0;
my $delay      = 3;
my $nosplash   = 0;
my $threads    = Sys::CPU::cpu_count();
my $RUNNING : shared = 1;

GetOptions(
    'auto'         => \$auto,
    'errors'       => \$errors,
    'showall|all'  => \$showall,
    'help'         => \$help,
    'delay|wait=i' => \$delay,
    'nosplash'     => \$nosplash,
    'threads=i'    => \$threads,
);
my @paths      = @ARGV;

unless (scalar(@paths) && ! $help) {
    $help = 2;
}

if ($help) {
    pod2usage('-exitstatus' => 1,'-verbose' => $help);
}

my $splash = ($nosplash) ? 0 : 2;

if ($errors) {
    system('clear');

    print qq{
AUTO     = $auto
ERRORS   = $errors
SHOWALL  = $showall
DELAY    = $delay
NOSPLASH = $nosplash
CPU      = }, Sys::CPU::cpu_type(), qq{
THREADS  = $threads
PATH(s)  = }, join('; ',@paths),"\n";

    sleep 3;
}
# Double buffering now supported
my ($F,$FB) = Graphics::Framebuffer->new(
    'SHOW_ERRORS'   => $errors,
    'RESET'         => 1,
    'SPLASH'        => $splash,
    'DOUBLE_BUFFER' => 1,
);

my $info  = $F->screen_dimensions();
my $DB    = 0;
my $DIRTY : shared = 1;

if ($info->{'bits_per_pixel'} == 16 && $F->{'ACCELERATED'}) {
    $DB = 1;
} else {
    $FB = $F;
}

if ($DB) {
    $SIG{'ALRM'} = sub {
        alarm(0);
        if ($DIRTY) {
            $DIRTY = 0;
            $F->blit_flip($FB);
        }
        alarm(1/15);
    };
}

system('clear');
$FB->cls('OFF');

my $p = gather($FB,@paths);

system('clear');
$FB->cls();
$FB->set_color({'red' => 0,'green' => 0, 'blue' => 0, 'alpha' => 255});
my @thrd;
$SIG{'QUIT'} = \&finish;
$SIG{'INT'}  = \&finish;
$SIG{'KILL'} = \&finish;

for (my $t=0;$t<$threads;$t++) {
    $thrd[$t] = threads->create(\&show,$FB, $p, $threads, $t);
}
while ($RUNNING && scalar(threads::list(threads::running))) {
    sleep 1;
}

$FB->cls('ON');
exit(0);

sub finish {
    print_it($FB,'SHUTTING DOWN...',1);
    $RUNNING = 0;
    alarm 0;
    $SIG{'ALRM'} = sub {
        exit(1);
    };
    alarm 20;
    while(my @thr = threads->list(threads::running)) {
        while (my @j = threads->list(threads::joinable)) {
            foreach my $jo (@j) {
                $jo->join();
                print_it($FB,'SHUTTING DOWN...',1);
            }
        }
    }
    while (my @j = threads->list(threads::joinable)) {
        foreach my $jo (@j) {
            $jo->join();
            print_it($FB,'SHUTTING DOWN...',1);
        }
    }
    foreach my $thr (threads->list()) {
        $thr->kill->detach();
    }
    exec('reset');
}

sub gather {
    my $FB    = shift;
    my @paths = @_;
    my @pics;
    foreach my $path (@paths) {
        chop($path) if ($path =~ /\/$/);
        print STDOUT "Scanning - $path\n";
        opendir(my $DIR, "$path") || die "Problem reading $path directory";
        chomp(my @dir = readdir($DIR));
        closedir($DIR);

        return if (! $showall && grep(/^\.nomedia$/, @dir));
        foreach my $file (@dir) {
            next if ($file =~ /^\.+/);
            if (-d "$path/$file") {
                my $r = gather($FB,"$path/$file");
                if (defined($r)) {
                    @pics = (@pics,@{$r});
                }
            } elsif (-f "$path/$file" && $file =~ /\.(jpg|jpeg|gif|tiff|bmp|png)$/i) {
                push(@pics, "$path/$file");
            }
        }
    }
    return(\@pics);
}

sub calculate_window {
    my $max     = shift;
    my $current = shift;
    my $width   = shift;
    my $height  = shift;

    my ($x,$y,$w,$h) = (0,0,$width,$height);
    if ($max == 2) {
        $w = int($width/2);
        if ($current == 0) {
        } else {
            $x = $w;
        }
    } elsif ($max <= 4) {
        $h = int($height/2);
        $w = int($width/2);
        if ($current == 0) {
        } elsif ($current == 1) {
            $x = $w;
        } elsif ($current == 2) {
            $w = $width if ($max == 3);
            $y = $h;
        } else {
            $x = $w;
            $y = $h;
        }
    } elsif ($max <= 6) {
        $h = int($height/2);
        $w = int($width/3);
        if ($current == 0) {
        } elsif ($current == 1) {
            $x = $w;
        } elsif ($current == 2) {
            $x = int($w * 2);
        } elsif ($current == 3) {
            $w = int($width/2) if ($max == 5);
            $y = $h;
        } elsif ($current == 4) {
            $w = int($width/2) if ($max == 5);
            $y = $h;
            $x = $w;
        } else {
            $y = $h;
            $x = int($w * 2);
        }
    } elsif ($max <= 8) { 
        $w = int($width/4);
        $h = int($height/2);
        if ($current == 0) {
        } elsif ($current == 1) {
            $x = $w;
        } elsif ($current == 2) {
            $x = int($w * 2);
        } elsif ($current == 3) {
            $x = int($w * 3);
        } elsif ($current == 4) {
            $y = $h;
            $w = int($width/3) if ($max == 7);
        } elsif ($current == 5) {
            $y = $h;
            $w = int($width/3) if ($max == 7);
            $x = $w;
        } elsif ($current == 6) {
            $y = $h;
            $w = int($width/3) if ($max == 7);
            $x = int($w * 2);
        } else {
            $y = $h;
            $x = int($w * 3);
        }
    } elsif ($max <= 12) {
        $w = int($width/4);
        $h = int($height/3);
        if ($current == 0) {
        } elsif ($current == 1) {
            $x = $w
        } elsif ($current == 2) {
            $x = int($w * 2);
        } elsif ($current == 3) {
            $x = int($w * 3);
        } elsif ($current == 4) {
            $y = $h;
        } elsif ($current == 5) {
            $x = $w;
            $y = $h;
        } elsif ($current == 6) {
            $x = int($w * 2);
            $y = $h;
        } elsif ($current == 7) {
            $x = int($w * 3);
            $y = $h;
        } elsif ($current == 8) {
            $y = int($h * 2);
        } elsif ($current == 9) {
            $x = $w;
            $y = int($h * 2);
        } elsif ($current == 10) {
            $x = int($w * 2);
            $y = int($h * 2);
        } else {
            $x = int($w * 3);
            $y = int($h * 2);
        }
    }
    return($x,$y,$w,$h);
}

sub show {
    my $FB   = shift;
    my $ps   = shift;
    my $jobs = shift;
    my $job  = shift;
    local $SIG{'ALRM'} = undef;
    local $SIG{'INT'}  = undef;
    local $SIG{'QUIT'} = undef;
    local $SIG{'KILL'} = undef;
    my @pics = shuffle(@{$ps});
    my $p = scalar(@pics);
    my $idx = 0;
    my ($X,$Y,$W,$H) = calculate_window($jobs,$job,$FB->{'XRES'},$FB->{'YRES'});

    while ($RUNNING && $idx < $p) {
        my $name = $pics[$idx];
#        print_it($FB, "Loading image $name");

        my $image = $FB->load_image(
            {
                'x'          => $X,
                'y'          => $Y,
                'width'      => $W,
                'height'     => $H,
                'file'       => $name,
                'autolevels' => $auto
            }
        );

        if (defined($image)) {
            $FB->rbox({'x'=>$X,'y'=>$Y,'width'=>$W,'height'=>$H,'filled'=>1});
            if (ref($image) eq 'ARRAY') {
                my $s = time + ($delay * 2);
                while ($RUNNING && time <= $s) {
                    $FB->play_animation($image,1);
                } ## end while (time <= $s)
            } else {
                $FB->blit_write($image);
                {
                    lock($DIRTY);
                    $DIRTY = 1;
                }
                sleep $delay * $RUNNING;
            }
        } ## end if (defined($image))
        $idx++;
#        $idx = 0 if ($idx >= $p);
    } ## end while ($RUNNING)
    $FB->rbox({'x'=>$X,'y'=>$Y,'width'=>$W,'height'=>$H,'filled'=>1});
} ## end sub show

sub print_it {
    my $fb      = shift;
    my $message = shift;
    my $big     = shift || 0;

    unless ($fb->{'XRES'} < 256) {
        my $b = $fb->ttf_print(
            {
                'x'            => 5,
                'y'            => 32,
                'height'       => ($big) ? 64 : 20,
                'color'        => 'FFFFFFFF',
                'text'         => $message,
                'bounding_box' => 1,
                'center'       => ($big) ? CENTER_XY : CENTER_X,
                'antialias'    => 1
            }
        );
        $fb->ttf_print($b);
    } else {
        print "$message\n";
    }
    {
        lock($DIRTY);
        $DIRTY = 1;
    }
    $fb->normal_mode();
} ## end sub print_it

__END__

=pod

=head1 NAME

Slide Show

=head1 DESCRIPTION

Framebuffer Slide Show

This automatically detects all of the framebuffer devices in your system, and shows the images in the images path, in a random order, on the primary framebuffer device (the first it finds).

=head1 SYNOPSIS

 perl threaded_slideshow.pl [options] "/path/to/scan"

More than one path can be used.  Just separate each path by a space.

=head2 OPTIONS

=over 2

=item B<--auto>

Turns on auto color level mode.  Sometimes this yields great results... and sometimes it totally ugly's things up

=item B<--errors>

Allows the module to print errors to STDERR

=item B<--delay>=seconds

Number of seconds to wait before loading the next image.  It can take longer to load animated GIFs.

Default is 3 seconds.

=item B<--showall>

Ignores any ".nomedia" files in subdirectories, and shows the images in them anyway.

=back

=cut
