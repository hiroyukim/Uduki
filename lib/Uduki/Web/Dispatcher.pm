package Uduki::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;
use Uduki::DateTime;
use Try::Tiny;
use Data::Page;

any '/' => sub {
    my ($c) = @_;

    my $today = Uduki::DateTime->today();

    my $diary = $c->dbh->query('SELECT id,created_on FROM diary WHERE created_on = ?',$today->strftime("%Y-%m-%d"))->hash;

    unless($diary) {
        $c->dbh->begin_work();
        try {
            $c->dbh->do(q{INSERT INTO diary (body,created_on) VALUES('',?)},{}, 
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

any '/diary/edit' => sub {
    my ($c) = @_;

    my $diary = $c->dbh->query('SELECT * FROM diary WHERE created_on = ?',$c->req->param('created_on') )->hash; 

    unless( $diary ) {
        $c->redirect('/');
    }

    if( $c->req->method eq 'POST' && $c->req->param('created_on') && $c->req->param('body') ) {
        $c->dbh->begin_work();
        try {
            $c->dbh->do('UPDATE diary SET body = ? WHERE created_on = ?',{},
                $c->req->param('body'),
                $c->req->param('created_on'),
            );
            $c->dbh->commit();
        }
        catch {
            my $err = shift;
            $c->dbh->rollback();
            Carp::croak($err);
        };

        return $c->redirect('/');
    }

    $c->fillin_form($diary);
    $c->render('/diary/edit.tt',{
        diary => $diary, 
    });
};    

get '/diary/list' => sub {
    my ($c) = @_;

    my $page = $c->req->param('page') || 1;
    my $rows = $c->req->param('rows') || 10;

    my $diaries = $c->dbh->selectall_arrayref(q{SELECT SQL_CALC_FOUND_ROWS * FROM diary ORDER BY created_on DESC LIMIT ?,?},{ Columns => {} },
        ( ($page - 1) * $rows),
        $rows,
    );
   
    my $found_rows = $c->dbh->query('SELECT FOUND_ROWS()')->array;
    my $total      = $found_rows->[0];

    $c->render('/diary/list.tt',{
        diaries => $diaries, 
        pager   => Data::Page->new($total, $rows, $page),
    });
};

1;
