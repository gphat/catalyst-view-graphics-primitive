package Catalyst::View::Graphics::Primitive;

use strict;
use warnings;

use Class::MOP;
use NEXT;
use Scalar::Util 'blessed';

use Catalyst::Exception;

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:GPHAT';

use base 'Catalyst::View';

sub new {
    my($class, $c, $args) = @_;
    my $self = $class->NEXT::new($c, $args);

    my $config = $c->config->{'View::Graphics::Primitive'};

    return $self;
}

sub process {
    my $self = shift;
    my $c    = shift;
    my @args = @_;

    my $content_type = $c->stash->{'graphics_primitive_content_type'}
        || $self->{'content_type'};

    my $gp = $c->stash->{'graphics_primitive'};

    (defined $gp)
        || die "No Graphics::Primitive to render";

    (blessed($gp) && $gp->isa('Graphics::Primitive::Component'))
        || die "Bad graphics_primitive, must be an instance of Graphics::Primitive::Component";

    my $out = eval {

        my $dname = $c->stash->{'graphics_primitive_driver'}
            || $self->{'driver'};
        my $dclass = "Graphics::Primitive::Driver::$dname";
        # If we've got a unary plus, assume they want the driver to be the
        # name they gave, not a suffix.
        if($dname =~ /^\+(.*)/) {
            $dclass = $1;
        }
        my $meta = Class::MOP::load_class($dclass);
        unless(defined($meta)) {
            die("Couldn't load driver: $dclass");
        }

        my $dargs = $c->stash->{'graphics_primitive_driver_args'}
            || $self->{'driver_args'};
        my $driver = $dclass->new($dargs);

        $driver->prepare($gp);
        if($gp->can('layout_manager')) {
            $gp->layout_manager->do_layout($gp);
        }
        $driver->pack($gp);
        $driver->draw($gp);

        $c->response->content_type($content_type);
        $c->response->body($driver->data);
    };
    if ($@) {
        die "Failed to render '$' as '$content_type' because: $@";
    }
}

1;
__END__
=head1 NAME

Catalyst::View::Graphics::Primitive - A Catalyst View for Graphics::Primitive

=head1 SYNOPSIS

  # lib/MyApp/View/GP.pm
  package MyApp::View::GP
  use base 'Catalyst::View::Graphics::Primitive';
  1;
  
  # configure in lib/MyApp.pm
  MyApp->config(
    ...
    'Graphics::Primitive' => {
        driver => 'Cairo',
        driver_args => { format => 'pdf' },
        content_type => 'application/pdf'
    }
  )

=head1 METHOD

=head2 new

The constructor for a new Graphics::Primitive view.

=head2 process

Renders the Graphics::Primitive::Component object stored in
C<< $c->stash->{graphics_primitive} >> using the driver specified in the
configuration or in C<< $c->stash->{graphics_primitive_driver} >> (for 
runtime changes). The driver will instantiated using driver_args from the
configuration or C<< $c->stash->{graphics_primitive_driver_args} >>.  The
component will then be moved through the Graphics::Primitive rendering
lifecycle as follows:

  $driver->prepare($comp);
  $driver->pack($comp);
  if($comp->can('layout_manager')) {
      $comp->layout_manager->do_layout($comp);
  }
  $driver->draw($comp);

The result of C<draw> is then set as the body response.  The content type is
set based on the C<content_type> configuration option or the value of
C<< $c->stash->{graphics_primitive_content_type} >>.

=head1 AUTHOR

Cory Watson, C<< <gphat@cpan.org> >>

Infinity Interactive, L<http://www.iinteractive.com>

=head1 ACKNOWLEDGEMENTS

Many of the ideas here come from my experience using the Cairo library.

=head1 BUGS

Please report any bugs or feature requests to C<bug-geometry-primitive at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Geometry-Primitive>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
