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

    my %livesockets;
    my $socket_idx = 'ws001';

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
                my $info = $1 ; # TODO: filter ?
                if (%livesockets) {
                    $self->app->log->debug( "sending line to " . scalar (keys %livesockets) . " websocket: $info");
                    foreach my $ws (values %livesockets) {
                        $ws->send($info)  ;
                    }
                }
                $self->app->log->debug( "websocket not opened, dropped line with: $1");
            }

            return 0;
        },
    );

    # also keep $loop alive in closure 
    $self->app->helper( stream_loop => sub { return $loop });

    $loop->add( $filestream );
    $self->app->helper( record_ws => sub {
        my ($self,$ws) = @_;
        $self->app->log->debug( "websocket $socket_idx recorded $ws");
        $livesockets{$socket_idx} = $ws ;
        return $socket_idx++;
    });
    $self->app->helper( remove_ws => sub {
        my ($self,$i) = @_;
        $self->app->log->debug( "websocket $i deleted");
        delete $livesockets{$i} ;
    });

    # Render template "example/welcome.html.ep" with message
    $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub open_socket {
    my $self = shift;

    # Opened
    $self->app->log->debug('WebSocket opened');

    # Increase inactivity timeout for connection a bit
    $self->inactivity_timeout(1200);# 20 mns

    my $idx = $self->app->record_ws($self);

    # Closed
    $self->on(finish => sub {
        my ($c, $code, $reason) = @_;
        $c->app->log->debug("WebSocket closed with status $code");
        $self->app->remove_ws($idx);
    });
};
1;
