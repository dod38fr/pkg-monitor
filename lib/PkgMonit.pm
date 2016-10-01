package PkgMonit;
use Mojo::Base 'Mojolicious';

# This method will run once at server start
sub startup {
    my $self = shift;
    my %args = @_;

    # Documentation browser under "/perldoc"
    $self->plugin('PODRenderer');

    # Add another "public" directory for javascript delivered by Debian
    push @{$self->static->paths}, '/usr/share/javascript', 'js';

    # Router
    my $r = $self->routes;

    # Normal route to controller
    $r->get('/')->to('main#welcome');

    $r->websocket('/pkg')->to('main#open_socket');
}

1;
