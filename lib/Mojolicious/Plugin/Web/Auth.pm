use strict;
use warnings;

package Mojolicious::Plugin::Web::Auth;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';

sub register {
    my ( $self, $app, $args ) = @_;
    my $module = delete $args->{module} or die "Missing mandatory parameter: module";
    my $klass  = join '::', __PACKAGE__, 'Site', $module;
    Mojo::Loader->load($klass);

    my $moniker           = $klass->moniker;
    my $authenticate_path = delete $args->{authenticate_path} || "/auth/${moniker}/authenticate";
    my $callback_path     = delete $args->{callback_path}     || "/auth/${moniker}/callback";

    # handlers
    my $on_finished = delete $args->{on_finished} or die "Missing mandatory parameter: on_finished";
    my $on_error    = delete $args->{on_error} || sub {
        my ( $c, $err ) = @_;
        die "Authentication error in $module: $err";
    };

    # auth object
    my $auth = $klass->new(%$args);

    $app->hook( before_dispatch => sub {
        my $c    = shift;
        my $path = $c->req->url->path;
        if ( $path->contains($authenticate_path) ) {
            my $callback = $c->req->url->path($callback_path)->to_abs;
            return $c->redirect_to( $auth->auth_uri( $c, $callback ) );
        }
        elsif ( $path->contains($callback_path) ) {
            return $auth->callback( $c, +{
                on_finished => sub {
                    $on_finished->($c, @_);
                },
                on_error => sub {
                    $on_error->($c, @_);
                },
            } );
        }
        else {
            return undef;
        }
    } );

    return $self;
}

1;

__END__

=head1 NAME

Mojolicious::Plugin::Web::Auth - Authentication plugin for Mojolicious

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Web::Auth'
      module      => 'Twitter',
      key         => 'Twitter consumer key',
      secret      => 'Twitter consumer secret',
      on_finished => sub {
          my ( $c, $access_token, $access_secret ) = @_;
          ...
      },
  );

  # Mojolicious::Lite
  plugin 'Web::Auth',
      module      => 'Twitter',
      key         => 'Twitter consumer key',
      secret      => 'Twitter consumer secret',
      on_finished => sub {
          my ( $c, $access_token, $access_secret ) = @_;
          ...
      };


  ### default authentication endpoint: /auth/{moniker}/authenticate
  # e.g.)
  # /auth/twitter/authenticate
  # /auth/facebook/authenticate

=head1 DESCRIPTION

L<Mojolicious::Plugin::Web::Auth> is authentication plugin for <Mojolicious>.

=head1 METHODS

L<Mojolicious::Plugin::Web::Auth> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>, L<Amon2::Auth>.

=cut
