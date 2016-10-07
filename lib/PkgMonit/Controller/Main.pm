package PkgMonit::Controller::Main;
use Mojo::Base 'Mojolicious::Controller';
use IO::Async::Loop::Mojo;
use IO::Async::FileStream;

my $loop = IO::Async::Loop::Mojo->new();
my $filestream;

{
    my %livesockets;
    my $socket_idx = 'ws001';

    sub record_ws {
        my ($self) = @_;
        $self->app->log->debug( "websocket $socket_idx recorded $self");
        $livesockets{$socket_idx} = $self ;
        return $socket_idx++;
    }

    sub remove_ws {
        my ($self,$i) = @_;
        $self->app->log->debug( "websocket $i deleted");
        delete $livesockets{$i} ;
    }

    sub count_ws {
        return scalar keys %livesockets;
    }

    sub all_ws {
        return values %livesockets;
    }
}

# This action will render a template
sub welcome {
    my $self = shift;

    $self->app->log->debug("Serving main page");

    # Render template "example/welcome.html.ep" with message
    $self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub setup_filestream {
    my ($self ) = @_;

    my $file = "/var/log/dpkg.log";
    open my $logh, "<", $file or
        die "Cannot open $file - $!";

    $self->app->log->debug( "Setting up $file filestream");

    # need to have only one filestream for all websocket that may be
    # opened at the same time
    my $stream = IO::Async::FileStream->new(
        read_handle => $logh,
        interval => 0.1,

        on_initial => sub {
            my ( $steam ) = @_;
            $steam->seek_to_last( "\n" );
        },

        # empty the stream while nobody listen
        on_read => sub {
            my ( $steam, $buffref ) = @_;

            while( $$buffref =~ s/^(.*)\n// ) {
                my $info = $1 ;
                my ($date,$hour,$action,@data) = split /\s/,$info;
                my $ws_count = count_ws();

                if ($ws_count and $action =~ /^(install|remove)$/) {
                    my ($pkg,$arch) = split /:/,$data[0];
                    my $msg = "$action $pkg";
                    $self->app->log->debug( "sending line to $ws_count websocket: $msg");
                    foreach my $ws ( all_ws() ) {
                        $ws->send($msg)  ;
                    }
                }
                elsif ($ws_count) {
                    $self->app->log->debug( "dropped: $info");
                }
                else {
                    $self->app->log->debug( "No open websocket, dropped: $info");
                }
            }

            return 0;
        },

        on_truncated => sub {
            $self->app->log->debug( "file truncated");
        }
    );

    $loop->add( $stream );
    return $stream;
}

sub open_socket {
    my $self = shift;

    # Opened
    $self->app->log->debug('WebSocket opened');

    $filestream //= $self->setup_filestream();

    # Increase inactivity timeout for connection a bit
    $self->inactivity_timeout(1200); # 20 mns

    my $idx = $self->record_ws();

    # Closed
    $self->on(finish => sub {
        my ($c, $code, $reason) = @_;
        $c->app->log->debug("WebSocket closed with status $code");
        $self->remove_ws($idx);
        if (count_ws() == 0) {
            $c->app->log->debug("No more open websocket, closing file stream");
            $loop->remove($filestream);
            $filestream = undef;
        }
    });
};
1;
