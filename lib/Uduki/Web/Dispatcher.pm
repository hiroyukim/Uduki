package Uduki::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;
use Uduki::DateTime;

any '/' => sub {
    my ($c) = @_;

    my $today = Uduki::DateTime->today();

    my $diary = $c->dbh->query('SELECT id,created_on FROM diary WHERE created_on = ?',$today->strftime("%Y-%m-%d"))->hash;

    unless($diary) {
        $c->dbh->begin_work();
        try {
            $c->dbh->do('INSERT INTO diary (body,created_on) VALUES('',?)',{}, 
                $today->strftime("%Y-%m-%d")
            );
            $c->dbh->commit();
        }
        catch {
            my $err = shift;
            $c->dbh->rollback();
            Carp::croak($err);
        };
    }
    
    $c->redirect('/diary/edit',{
        created_on => $today->strftime("%Y-%m-%d"),
    });
};

1;
