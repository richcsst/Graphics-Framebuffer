use strict;
use warnings;
use Graphics::Framebuffer;
use Benchmark qw{timethese cmpthese};

my ($W, $H) = (0, 0);

my %result;
for my $mode (qw(live fake)) {

    my $SCR = Graphics::Framebuffer->new(
        FB_DEVICE   => ($mode eq 'live' ? '/dev/fb0' : 'EMULATED'),
        SPLASH      => 0,
        RESET       => 0,
        COLOR_ORDER => 'BGR',
    );

    $W = $SCR->{XRES};
    $H = $SCR->{YRES};

    $SCR->cls('OFF');
    $SCR->graphics_mode;

    $SCR->set_color({
        red => 111, green => 112, blue => 113, alpha => 114
    });
    $SCR->plot({ x => 0,    y => 0    });
    $SCR->plot({ x => $W-1, y => $H-1 });

    $result{$mode} = timethese( ($mode eq 'live' ? 2 : 50), {
        "c-orig" => sub { verify( $SCR->blit_read_force_c        ) },
        "c-new"  => sub { verify( $SCR->blit_read_force_c_new    ) },
        "p-orig" => sub { verify( $SCR->blit_read_force_perl     ) },
        "p-new"  => sub { verify( $SCR->blit_read_force_perl_new ) },
    });

    $SCR->text_mode;
    $SCR->cls('ON');
    undef $SCR;
}

sub verify {
    my $opts = shift;
    die unless $opts->{x}      == 0;
    die unless $opts->{y}      == 0;
    die unless $opts->{width}  == $W;
    die unless $opts->{height} == $H;

    my $img = $opts->{image};
    die unless length($img) == 4 * $W * $H;
    die unless ord(substr $img,  0, 1) == 113;
    die unless ord(substr $img,  1, 1) == 112;
    die unless ord(substr $img,  2, 1) == 111;
    die unless ord(substr $img,  3, 1) == 114;
    die unless ord(substr $img,  4, 1) == 0;
    die unless ord(substr $img, -5, 1) == 0;
    die unless ord(substr $img, -4, 1) == 113;
    die unless ord(substr $img, -3, 1) == 112;
    die unless ord(substr $img, -2, 1) == 111;
    die unless ord(substr $img, -1, 1) == 114;
}

select STDERR;
print "LIVE FB:\n"; cmpthese($result{live}); print "\n";
print "FAKE FB:\n"; cmpthese($result{fake}); print "\n";

__END__

=head1 Description

This script compares the performance of blit_read() in various
incarnations:

    * The original C code.
    * The original Perl code.
    * A new version of C code.
    * A new version of Perl code.

=head1 Usage

From the main package directory, build as usual (but do not install)
then run the script.

    perl -Iblib/lib -Iblib/arch t/blitread.pl

The report is issued through STDERR so you will need to arrange capture
of that however your environment allows. I simply redirect to file and
view later. YMMV.

=head1 Method

Copies of the Perl blit_read() and the C c_blit_read() functions where
created and Benchmark was used to call them directly.

=head1 Functions

=over 4

=item blit_read_force_perl()

A copy-paste of blit_read(), modified where ACCELERATION is tested to
force it down the pure Perl path. Used to test the original Perl code.

=item blit_read_force_c()

A copy-paste of blit_read(), modified to force down the C path. Used to
test the original C code.

=item blit_read_force_perl_new()

A copy-paste of blit_read_force_perl(), with better optimization in the
Perl path. Used to test new Perl code.

=item blit_read_force_c_new()

A copy-paste of blit_read_force_c(), modified to call c_blit_read_new()
instead of c_blit_read(). Used to test new C code.

=item c_blit_read_new()

A rewrite of c_blit_read(). It follows the pattern set in the Perl path
of blit_read(), optimized to remove as much as possible from the
memcpy() loop. Called from blit_read_force_c_new().

=back

=head1 Tests

Four tests are run against each of live and emulated framebuffers.

    p-orig - The original Perl code.
    c-orig - The original C code.
    p-new  - The new Perl code.
    c-new  - The new C code.

The emulated framebuffer tests are run 50 times each.

The live tests are only run twice since they are so much slower.
Increasing iterations to as many as 100 doesn't change the result.

=head1 Conclusions

The emulated framebuffer is MUCH faster, literally two orders of
magnitude.

The original C code is SLOWER than the original Perl by around 10%.

On the live framebuffer, the only win is with the new C code simply
because the original is slower. Otherwise, all tests are about equal.

On the emulated framebuffer, the new Perl is 30% faster than original
and the C is another 100% faster than that.

A copy of my results are in the t directory. They were run on an 800MHz
dual-core AMD Athlon processor.

=cut
