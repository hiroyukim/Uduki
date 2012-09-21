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
    $c->render('/index.tt',{
        created_on => Uduki::DateTime->today()->strftime("%Y-%m-%d"), 
    });
};

any '/api/diary/edit' => sub {
    my ($c) = @_;

    my $created_on = $c->req->param('created_on') || Uduki::DateTime->today()->strftime("%Y-%m-%d");
    my $diary      = $c->dbh->query('SELECT * FROM diary WHERE created_on = ?',$created_on )->hash; 

    if( $c->req->method eq 'POST' && $c->req->param('body') ) {
        $c->dbh->begin_work();
        try {
            unless($diary) {
                $c->dbh->do(q{INSERT INTO diary (body,created_on) VALUES('',?)},{}, 
                    $created_on,
                );
            }

            $c->dbh->do('UPDATE diary SET body = ? WHERE created_on = ?',{},
                $c->req->param('body'),
                $created_on,
            );
            $c->dbh->commit();
        }
        catch {
            my $err = shift;
            $c->dbh->rollback();
            Carp::croak($err);
        };
    }

    return $c->render_json(+{});
};    

get '/diary/cal' => sub {
    my ($c) = @_;

    my $month = $c->req->param('month') || Uduki::DateTime->today->strftime("%Y-%m");

    $c->render('/diary/cal.tt',{
        month => $month,
    });
};

get '/api/diary/cal' => sub {
    my ($c) = @_;

    my $month = $c->req->param('month') || Uduki::DateTime->today->strftime("%Y-%m");

    my $diaries = $c->dbh->query(
        q{SELECT id,body,created_on FROM diary WHERE created_on LIKE CONCAT(?,'%')},$month
    )->hashes;

    $c->render_json(
        [ map {
            +{
                start => $_->{created_on},
                title => do {
                    my @titles = ($_->{body} =~ /^#\s+([^#\n]+)$/mg);
                    join(",",map { "[" . $_ . "]" } @titles);
                },
            }
        } @{$diaries}],
    );
};

get '/api/diary/search' => sub {
    my ($c) = @_;

    my $page   = $c->req->param('page') || 1;
    my $rows   = $c->req->param('rows') || 10;
    my $offset = ($page - 1) * $rows;

    my $cond = {};
   
    # http://search.cpan.org/~frew/SQL-Abstract-1.73/lib/SQL/Abstract.pm#SPECIAL_OPERATORS
    $c->dbh->abstract(SQL::Abstract::Limit->new( 
        limit_dialect => $c->dbh, 
        special_ops => [{
            regex => qr/^match$/i,
            handler => sub {
                my ($self, $field, $op, $arg) = @_;
                $arg = [$arg] if not ref $arg;
                my $label         = $self->_quote($field);
                my ($placeholder) = $self->_convert('?');
                my $placeholders  = join ", ", (($placeholder) x @$arg);
                #my $sql           = $self->_sqlcase('match') . " (@{[$label x @$arg]}) "
                my $sql           = $self->_sqlcase('match') . " (@{[join q{,}, map { $label } @$arg]}) "
                                    . $self->_sqlcase('against') . " ($placeholders  IN BOOLEAN MODE)";
                                    warn $sql;
                my @bind = $self->_bindtype($field, @$arg);
                return ($sql, @bind);
            }
        }],
    ));

    if( my $word = $c->req->param('word') ) {
        if( $c->config->{full_text_search} ) { 
            $cond->{body} = { -match => [split /\s+/,$word] }
        }
        else {
            $cond->{body} = [ 
                -and => map { +{ ( /^-(.+)$/ ? 'not like' : 'like' ) => '%' . ($1 || $_) . '%' }  } split /\s+/, $word 
            ];
        }
    }

    if( $c->req->param('created_on') ) {
        $cond->{created_on} = $c->req->param('created_on');
    }

    my $diaries = $c->dbh->query(
        $c->dbh->abstract->select(
            'diary',
            '*', 
            $cond,
            [ { -desc => [qw/created_on/] } ],
            $rows,
            $offset,
        )
    )->hashes;

    my ($count_where,@count_where_bind) = $c->dbh->abstract->where(
        $cond,
        [],
    );
    my $found_rows = $c->dbh->query(
        "SELECT COUNT(*) AS count FROM diary " . $count_where, @count_where_bind,
    )->array;
    my $total      = $found_rows->[0];
    my $pager      = Data::Page->new($total, $rows, $page);

    $c->render_json(+{
        data   => $diaries, 
        pager  => { map { $_ => $pager->$_ } qw/total_entries entries_per_page current_page entries_on_this_page first_page last_page first last previous_page next_page/ },
    });
};

1;
