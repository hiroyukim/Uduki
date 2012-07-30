package Uduki::Web;
use strict;
use warnings;
use utf8;
use parent qw/Uduki Amon2::Web/;
use HTTP::MobileAgent;
use HTTP::MobileAgent::Plugin::SmartPhone;

# dispatcher
use Uduki::Web::Dispatcher;
sub dispatch {
    return (Uduki::Web::Dispatcher->dispatch($_[0]) or die "response is not generated");
}

# setup view class
use Uduki::Web::View;
{
         
    my $view_conf = __PACKAGE__->config->{'Text::Xslate'} || +{};
    my $base_dir  = __PACKAGE__->base_dir();
    my ($view_pc,$view_mobile) = map { 
        Uduki::Web::View->create({ base_dir => $base_dir, view_conf => $view_conf, view_paths => $_ }) 
    } ([qw/tmpl/],[qw/tmpl mobile/]);

    sub create_view {  
        my ($c) = @_;
        ( HTTP::MobileAgent->new($c->req->env)->is_smartphone ) ? $view_mobile : $view_pc;
    }
}

# load plugins
__PACKAGE__->load_plugins(
    'Web::FillInFormLite',
    'Web::JSON',
);

# for your security
__PACKAGE__->add_trigger(
    AFTER_DISPATCH => sub {
        my ( $c, $res ) = @_;

        # http://blogs.msdn.com/b/ie/archive/2008/07/02/ie8-security-part-v-comprehensive-protection.aspx
        $res->header( 'X-Content-Type-Options' => 'nosniff' );

        # http://blog.mozilla.com/security/2010/09/08/x-frame-options/
        $res->header( 'X-Frame-Options' => 'DENY' );

        # Cache control.
        $res->header( 'Cache-Control' => 'private' );

        # dbh disconnect
        $c->dbh->disconnect();
    },
);

__PACKAGE__->add_trigger(
    BEFORE_DISPATCH => sub {
        my ( $c ) = @_;
        # ...
        return;
    },
);

1;
