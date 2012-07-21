package Uduki::Web::Dispatcher;
use strict;
use warnings;
use utf8;
use Amon2::Web::Dispatcher::Lite;
use Uduki::DateTime;
use Try::Tiny;
use Data::Page;
use SQL::Abstract::Limit; 

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

get '/diary/search' => sub {
    my ($c) = @_;

    my $page   = $c->req->param('page') || 1;
    my $rows   = $c->req->param('rows') || 10;

    my $cond = {};

    if( my $tag_id = $c->req->param('tag_id') ) {
        my @diary_tags = $c->dbh->query('SELECT diary_id FROM diary_tag WHERE tag_id = ?',$tag_id)->hashes; 
        $cond->{id} = { -in => [map { $_->{diary_id} } @diary_tags ] };
    }

    $c->dbh->abstract( SQL::Abstract::Limit->new( limit_dialect => $c->dbh ) );
        
    my $diaries = $c->dbh->query(
        $c->dbh->abstract->select(
            'diary',
            'SQL_CALC_FOUND_ROWS *',
            $cond,
            [ 
                { -desc => [qw/created_on/] }
            ],
            ( ($page - 1) * $rows),
            $rows,
        )
    )->hashes;
   
    my $found_rows = $c->dbh->query('SELECT FOUND_ROWS()')->array;
    my $total      = $found_rows->[0];

    $c->render('/diary/search.tt',{
        diaries => $diaries, 
        pager   => Data::Page->new($total, $rows, $page),
        getTags    => sub {
            my $diary_id = shift;

            if( my @diary_tags = $c->dbh->query('SELECT tag_id FROM diary_tag WHERE diary_id = ?',$diary_id)->hashes ) { 
                return [$c->dbh->query($c->dbh->abstract->select('tag',[qw/id name/],{ id => { -in => [map { $_->{tag_id} } @diary_tags ] } }))->hashes]; 
            }
            else {
                return;
            }
        },
    });
};

post '/api/tag/edit' => sub {
    my ($c) = @_;

    my $tag_name = $c->req->param('tag_name');
    my $diary_id = $c->req->param('diary_id');

    my $tag = $c->dbh->query('SELECT * FROM tag WHERE name = ?',$tag_name)->hash; 
   
    unless( $tag ) {
        $c->dbh->begin_work();
        try {
            $c->dbh->do(q{INSERT INTO tag (name) VALUES(?)},{}, 
                $tag_name,
            );
            $c->dbh->commit();
        }
        catch {
            my $err = shift;
            $c->dbh->rollback();
            Carp::croak($err);
        };
       
        $tag = $c->dbh->query('SELECT * FROM tag WHERE name = ?',$tag_name)->hash;
    };

    if( $c->dbh->query('SELECT * FROM diary_tag WHERE diary_id = ? AND tag_id = ?',$diary_id,$tag->{id})->hash ) { 
        $c->dbh->begin_work();
        try {
            $c->dbh->do(q{DELETE FROM diary_tag WHERE diary_id = ? AND tag_id = ?},{}, 
                $diary_id,
                $tag->{id},
            );
            
            my $diary_tag = $c->dbh->query('SELECT COUNT(id) AS count FROM diary_tag WHERE diary_id != ? AND tag_id = ?',
                $diary_id,
                $tag->{id},
            )->hash;
            
            if( int($diary_tag->{count}) == 0 ) {
                $c->dbh->do(q{DELETE FROM tag WHERE id = ?},{}, 
                    $tag->{id},
                );
            }

            $c->dbh->commit();
        }
        catch {
            my $err = shift;
            $c->dbh->rollback();
            Carp::croak($err);
        };
    }
    else {
        $c->dbh->begin_work();
        try {
            $c->dbh->do(q{INSERT INTO diary_tag (diary_id,tag_id) VALUES(?,?)},{}, 
                $diary_id,
                $tag->{id},
            );
            $c->dbh->commit();
        }
        catch {
            my $err = shift;
            $c->dbh->rollback();
            Carp::croak($err);
        };
    }

    $c->render_json(+{
        result => 'ok',
    });
};

get '/api/tag/list' => sub {
    my ($c) = @_;

    if( my @diary_tags = $c->dbh->query('SELECT tag_id FROM diary_tag WHERE diary_id = ?',$c->req->param('diary_id'))->hashes ) {
        $c->render_json(+{
            tags => [$c->dbh->query($c->dbh->abstract->select('tag',[qw/id name/],{ id => { -in => [map { $_->{tag_id} } @diary_tags ] } }))->hashes], 
        });
    }
    else {
        $c->render_json(+{
            tags => [], 
        });
    }
};

1;
