#!/usr/bin/env perl
use strict;
use SDL qw(:init);
use SDL::Video qw(:video);
use SDL::Surface;
use SDL::Rect;
use SDL::Event;
use SDL::Events qw(:events);
use SDL::Keysym qw(:keysym);

# Initialize Video subsystem
SDL::init(SDL_INIT_VIDEO) == 0
    or die "Error: Could not initialize SDL: " . SDL::get_error() . "\n";

my $screen = SDL::Video::set_video_mode(
    $width, $height, $bpp,
    SDL_SWSURFACE
);
die "Error: Failed to create SDL window: " . SDL::get_error() . "\n" unless $screen;

SDL::Video::wm_set_caption("Graphics::Framebuffer Viewer [$width x $height]", "GFB Viewer");

# Define color channel masks
my ($rmask, $gmask, $bmask, $amask) = (0, 0, 0, 0);
if ($bpp == 32) {
    # Match standard fbdev/DRM 32-bit little-endian (BGRx / BGRA)
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
my $clip_rect = SDL::Rect->new(0, 0, $width, $height);

print "[gfb_viewer] Window active. Polling at ${framerate} FPS...\n";

while ($running) {
    my $t0 = time;

    while (SDL::Events::poll_event($event)) {
        my $type = $event->type;
        if ($type == SDL_QUIT || ($type == SDL_KEYDOWN && $event->key_sym == SDLK_ESCAPE)) {
            $running = 0;
            last;
        }
    }

    # Map shared memory directly onto an SDL surface
    my $source = SDL::Surface->new_from(
        $shm_buffer,
        $width, $height, $bpp,
        $pitch,
        $rmask, $gmask, $bmask, $amask
    );

    if ($source) {
        SDL::Video::blit_surface($source, $clip_rect, $screen, $clip_rect);
        SDL::Video::update_rect($screen, 0, 0, $width, $height);
    }

    my $elapsed = time - $t0;
    my $sleep_time = $delay - $elapsed;
    sleep($sleep_time) if ($sleep_time > 0);
}