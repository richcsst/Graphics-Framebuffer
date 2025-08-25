#!/usr/bin/env perl

use strict;
use Math::Trig ':pi';
use Term::ReadKey;
use Getopt::Long;
use Pod::Usage;

BEGIN {
    our $VERSION = '0.01';    # Increment this as you develop the code.
}

use Graphics::Framebuffer;    # There are things to import, if you want, but they
                              # are usually not needed.

my $granularity = 0.005; # Default = 0.0001
my $help = 0;
my $man  = 0;

GetOptions(
	'granularity=f' => \$granularity,
	'help|?'        => \$help,
	'man'           => \$man,
);

pod2usage(1) if ($help);
pod2usage(-exitval => 0, -verbose => 2) if ($man);

our $FB = Graphics::Framebuffer->new('SPLASH' => 0);    # The splash screen is
                                                        # mainly for testing.

$FB->cls('OFF');                                        # Turn off the console cursor

# You can optionally set graphics mode here, but remember to turn on text mode
# before exiting.

$FB->graphics_mode();    # Shuts off all text and cursors.

# Gathers information on the screen for you to use as global information
our $screen_info = $FB->screen_dimensions();

my $wid = $screen_info->{'width'};
my $hgt = $screen_info->{'height'};
my $r;
my $widbase;
my $hgtbase;
my $cycles;
my $redphase;
my $greenphase;
my $bluephase; # random color generation variables
my $x0;
my $y0;
my $x1;
my $y1;
my $twists;
my $key = '';

ReadMode 4;
do {
	$r = int(rand(490) + 10);
	$cycles = int(rand(19) + 2);
	$widbase = $wid - 2 * $r;
	$hgtbase = $hgt - 2 * $r;
	$twists = int(sqrt(rand(9) + 1));
	$x0 = $r;
	$x1 = $wid - $r;
	$y0 = $r;
	$y1 = $hgt - $r;
	$redphase = rand() / 2;
	$greenphase = rand() / 2;
	$bluephase = rand() / 2;
	$FB->cls();
	for (my $i = $x0;$i < $x1; $i = $i + $granularity) {
		# plot ($i, hgt / 2 + hgt / 2 * Sin($i / wid * 2 * pi * 5)), _RGB(255, 0, 0)
		my $x = $i + $r * cos(10 * $i);
		my $y = $hgt / 2 + $hgtbase / 2 * sin($i / $widbase * 2 * pi * $cycles) + $r * sin(10 * $twists * $i);
		$FB->setcolor({'red' => 20 + sin($i * $redphase) * 235, 'green' => 20 + sin($i * $greenphase) * 235, 'blue' => sin(20 + $i * $bluephase) * 235});
		$FB->plot({'x' => $x, 'y' => $y});
		last if (defined ($key = ReadKey(-1)));
	}
} until (defined($key) && uc($key) eq 'Q');
ReadMode 0;
##############################################################################

$FB->text_mode();        # Turn text and cursor back on.  You MUST do this if
                         # graphics mode was set.
$FB->cls('ON');          # Turn the console cursor back on
exit(0);

__END__

=head1 NAME

Shapes - Generate randowm shapes in random colors.

Must be used with Graphics::Framebuffer

=head1 SYNOPWSIS

perl shapes.pl [options]

 Options:
   -help                 Brief help message
   -man                  Full documentation
   -granularity=number   Change granularity.  Default is 0.005 (can be as small as 0.0001, but slower)

=head1 OPTIONS

=over 8

=item B<-help>

Print a breief help message and exit

=item B<-man>

Print the manual page and exit

=item B<-granularity>=number

Change the granularity from 0.005 to anything else less than 1.  Nothing smaller than the number 0.0001 should be used. 

=back

=head1 DESCRIPTION

Just run it.  Hitting any key (except Q) will change output
Hit Q to exit

=cut
