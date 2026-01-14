use strict;
use warnings;
use Graphics::Framebuffer;

my $SCR = Graphics::Framebuffer->new(
    FB_DEVICE => '/dev/fb0',
    SPLASH    => 0,
    RESET     => 0,
);

my $EMU = Graphics::Framebuffer->new(
    FB_DEVICE => 'EMULATED',
    VXRES     => $SCR->{XRES},
    VYRES     => $SCR->{YRES},
);

$SCR->cls('OFF');
$SCR->graphics_mode;

$EMU->plot({ x => 0, y => 0 });

$SCR->blit_write( $EMU->blit_read );

$SCR->text_mode;
$SCR->cls('ON');

__END__

=head1 Description

This script demonstrates an off-by-one problem when doing full-screen
blit_write()s.

=head1 Usage

Install Devel::Peek if you don't already have it.

In the main GFB directory, build as usual (but do not install) then run
the script.

    perl -Iblib/lib -Iblib/arch t/offbyone.pl

The report is issued through STDERR so you will need to arrange capture
of that however your environment allows. I simply redirect to file and
view later. YMMV.

=head1 Method

The _blit_adjust_for_clipping() function was renamed to
_p_blit_adjust_for_clipping() then a replacement was created as a direct
pass-thru.

The new function emits debug information before and after the call to
the original looking at changes in $params, specifically the size and
content of the image.

With the hook in place, one test is run - a full screen blit read from
an emulated framebuffer directly followed by a blit write to the live
framebuffer.

A copy of my results are in t/offbyone.pre and t/offbyone.post.

=head1 Conclusions

The size of the incoming image is correct for my machine - 1280x1024,
confirmed by the CUR size of 1280*1024*4.

Before patching, the size of the image coming out has shrunk by one
pixel in either direction, again confirmed by the CUR size. Also, the
exiting image is in a new location as indicated by the inner PV and it
has lost the IsCOW flag, altogether meaning either copy-on-write was
triggered or this is now an entirely new SV (or both).

After patching, the size of the image coming out is correct. Notice also
that the inner PV is the same and the COW_REFCNT has increased, so the
image was copied by pointer only. It didn't have to do a full bitwise
copy.

=cut
