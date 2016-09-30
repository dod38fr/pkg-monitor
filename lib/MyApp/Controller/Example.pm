package MyApp::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';
use IO::Async::Loop::Mojo;
use IO::Async::FileStream;


# This action will render a template
sub welcome {
    my $self = shift;

    my $loop = IO::Async::Loop::Mojo->new();

    #$loop->add( ... );
    open my $logh, "<", "dpkg.log" or
        die "Cannot open logfile - $!";

    # need to have only one filestream for all websocket that may be
    # opened at the same time
    my $filestream = IO::Async::FileStream->new(
        read_handle => $logh,
        interval => 0.1,

        on_initial => sub {
            my ( $steam ) = @_;
            $steam->seek_to_last( "\n" );
        },

        # empty the stream while nobody listen
        on_read => sub {
            my ( $steam, $buffref ) = @_;

            while( $$buffref =~ s/^(.*\n)// ) {
                $self->app->log->debug( "websocket not opened, dropped line with: $1");
            }

            return 0;
        },
    );

    # also keep $loop alive in closure 
    $self->app->helper( stream_loop => sub { return $loop });

    $loop->add( $filestream );
    $self->app->helper( fstream => sub { return $filestream });

    # Render template "example/welcome.html.ep" with message
    $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub open_socket {
    my $self = shift;

    # Opened
    $self->app->log->debug('WebSocket opened');

    # Increase inactivity timeout for connection a bit
    $self->inactivity_timeout(1200);# 20 mns
    my $active = 1;

    $self->app->fstream->push_on_read(
        sub {
            my ( $stream, $buffref ) = @_;
            return undef unless $active; # clear read handler

            while( $$buffref =~ s/^(.*\n)// ) {
                $self->send($1) ; # TODO: filter ?
            }

            return 0; # return 1 to be called again once the EOF condition is cleared 
        }
    );

    # Closed
    $self->on(finish => sub {
        my ($c, $code, $reason) = @_;
        $c->app->log->debug("WebSocket closed with status $code");
        $active = 0; # will cancel the filestream handler
    });
};
1;
