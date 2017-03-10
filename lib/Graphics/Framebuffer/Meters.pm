package Graphics::Framebuffer::Meters;

use strict;
no strict 'vars';    # We have to map a variable as the screen.  So strict is going to whine about what we do with it.
no warnings;         # We have to be as quiet as possible

use constant {
    TRUE  => 1,
    FALSE => 0
};

use List::Util qw(min max);

BEGIN {
    our $VERSION = '1.00';
}

=head1 radial_init

Initialize a radial meter

The parameters are passed in via an anonymous hash:

 {
     'x'             => 0,      # bottom left corner
     'y'             => 0,      # "
     'width'         => 300,    #
     'height'        => 200,    #
     'start_angle'   => 90,
     'end_angle'     => 180,
     'direction'     => 'positive', # positive or negative
     'damping'       => 0, # % per second (0 is fastest, no damping)
     'peak'          => 'none', # none, needle, pie
     'max_value'     => 1000,   # Can be anything, but keep it sane
     'red_start'     => 850,    # Must be less than 'max_value'
                                # If equal to 'max_value', then not used
     'yellow_start'  => 700,    # Must be less than 'red_start'
                                # If equal to 'red_start', then not used
     'red_color'     => {
         'red'   => 255,
         'green' => 0,
         'blue'  => 0,
         'alpha' => 255,
     },
     'yellow_color'  => {
         'red'   => 255,
         'green' => 255,
         'blue'  => 0,
         'alpha' => 255,
     },
     'background_color' => {
         'red'   => 255,
         'green' => 255,
         'blue'  => 255,
         'alpha' => 255,
     },
     'indicator' => {
         'color' => { # Defaults to black
             'red'   => 0,
             'green' => 0,
             'blue'  => 0,
             'alpha' => 255,
         },
         'stroke'       => 1,
         'start_radius' => 0, # assumes a circle, and needle is drawn starting on the perimeter of the circle.
         'length'       => 20,
     },
     'image_background' => $image # (optional) Image from 'image_load' or 'blit_read'
 }

=cut

sub radial_init {
    my $self   = shift;
    my $params = shift;

    # Draw box in default color
    unless(exists($params->{'image_background'}) && defined($params->{'image_background'})) {
        $self->set_color($params->{'background_color'});
        $self->rbox(
            {
                'x'      => $params->{'x'},
                'y'      => $params->{'y'},
                'width'  => $params->{'width'},
                'height' => $params->{'height'},
                'filled' => TRUE,
            }
        );
        $self->set_color($params->{'indicator'}->{'color'});
    } else {
        $params->{'image_background'}->{'x'} = $params->{'x'};
        $params->{'image_background'}->{'y'} = $params->{'y'};
        $self->blit_write($params->{'image_background'});
    }
    $self->radial_update({'meter' => $params, 'value' => 0});
    return($params);
}

sub radial_update {
    my $self   = shift;
    my $params = shift;


}

sub bar_init {
    my $self   = shift;
    my $params = shift;

    return($params);
}

sub bar_update {
    my $self   = shift;
    my $params = shift;


}

1;

=head1 NAME

Graphics::Framebuffer::Meters

=head1 DESCRIPTION

See the "Graphics::Frambuffer" documentation, as methods within here are pulled into the main module

=cut
