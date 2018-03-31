#!/usr/bin/perl

use strict;

use Graphics::Framebuffer;
use Time::HiRes qw(sleep time);
use List::Util qw(shuffle);
use Getopt::Long;

# use Data::Dumper::Simple;

my $path;
my $errors     = 0;
my $auto       = 0;
my $fullscreen = 0;
my $showall    = 0;

GetOptions(
    'auto'   => \$auto,
    'errors' => \$errors,
    'full'   => \$fullscreen,
    'path=s' => \$path,
    'showall|all' => \$showall,
);

my $p = gather($path);

my $FB = Graphics::Framebuffer->new(
    'SHOW_ERRORS' => $errors,
    'RESET'       => 1,
);

system('clear');
$FB->cls('OFF');

show($FB, $p);

exit(0);

sub gather {
    my @pics;
    my $path = shift;
    chop($path) if ($path =~ /\/$/);
    opendir(my $DIR, "$path") || die "Problem reading $path directory";
    chomp(my @dir = readdir($DIR));
    closedir($DIR);

    return if (! $showall && grep(/^\.nomedia$/, @dir));
    foreach my $file (@dir) {
        next if ($file =~ /^\.+/);
        if (-d "$path/$file") {
            my $r = gather("$path/$file");
            if (defined($r)) {
                @pics = (@pics,@{$r});
            }
        } elsif (-f "$path/$file" && $file =~ /\.(jpg|jpeg|gif|tiff|bmp|png)$/i) {
            push(@pics, "$path/$file");
        }
    }
    return(\@pics);
}

sub show {
    my $FB  = shift;
    my $ps  = shift;
    my @pics = shuffle(@{$ps});
    my $p = scalar(@pics);
    my $idx = 0;

    while ($idx < $p) {
        my $name = $pics[$idx];
        print_it($FB, "Loading image $name");
        my $image;
        unless ($fullscreen) {
            $image = $FB->load_image(
                {
                    'file'       => $name,
                    'center'     => CENTER_XY,
                    'autolevels' => $auto
                }
            );
        } else {
            $image = $FB->load_image(
                {
                    'width'      => $FB->{'XRES'},
                    'height'     => $FB->{'YRES'},
                    'file'       => $name,
                    'center'     => CENTER_XY,
                    'autolevels' => $auto
                }
            );
        } ## end else

        #        warn Dumper($image);exit;
        if (defined($image)) {
            $FB->cls();
            if (ref($image) eq 'ARRAY') {
                my $s = time + 8;
                while (time <= $s) {
                    $FB->play_animation($image,1);
                } ## end while (time <= $s)
            } else {
                $FB->cls();
                $FB->blit_write($image);
                sleep 3;
            }
        } ## end if (defined($image))
        $idx++;
#        $idx = 0 if ($idx >= $p);
    } ## end while ($RUNNING)
} ## end sub show

sub print_it {
    my $fb      = shift;
    my $message = shift;

    unless ($fb->{'XRES'} < 256) {
        $fb->xor_mode();

        my $b = $fb->ttf_print(
            {
                'x'            => 5,
                'y'            => 20,
                'height'       => 20,
                'color'        => 'FFFFFFFF',
                'text'         => $message,
                'bounding_box' => 1,
                'center'       => CENTER_X,
                'antialias'    => 1
            }
        );
        $fb->ttf_print($b);
    } else {
        print "$message\n";
    }
    $fb->normal_mode();
} ## end sub print_it

=head1 NAME

Slide Show

=head1 DESCRIPTION

Multi-threaded, multi-framebuffer Slide Show

This automatically detects all of the framebuffer devices in your system, and shows the images in the images path, in a random order, on all devices.

=head1 SYNOPSIS

 perl slideshow [options]

=head2 OPTIONS

=over 2

=item C<--auto>

Turns on auto color level mode.  Sometimes this yields great results... and sometimes it totally ugly's things up

=item C<--errors>

Allows the module to print errors to STDERR

=item C<--path>="/path/to/files"

Makes the module render in file handle mode instead of memory mapped string mode.

=item C<full>

Scales all images (and animations) to full screen (proportionally).

=back

=cut
