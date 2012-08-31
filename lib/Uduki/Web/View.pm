package Uduki::Web::View;
use strict;
use warnings;
use Amon2;
use File::Spec;
use Text::Xslate;
use Smart::Args;

sub create {
    args my $class       => 'ClassName',
         my $base_dir    => { isa => 'Str'      },
         my $view_conf   => { isa => 'HashRef'  },
         my $view_paths  => { isa => 'ArrayRef' };

    $view_conf->{path} = [ File::Spec->catdir($base_dir, @{$view_paths}) ];

    return Text::Xslate->new(+{
        'syntax'   => 'TTerse',
        'module'   => [ 'Text::Xslate::Bridge::Star' ],
        'function' => {
            c => sub { Amon2->context() },
            uri_with => sub { Amon2->context()->req->uri_with(@_) },
            uri_for  => sub { Amon2->context()->uri_for(@_) },
            static_file => do {
                my %static_file_cache;
                sub {
                    my $fname = shift;
                    my $c = Amon2->context;
                    if (not exists $static_file_cache{$fname}) {
                        my $fullpath = File::Spec->catfile($c->base_dir(), $fname);
                        $static_file_cache{$fname} = (stat $fullpath)[9];
                    }
                    return $c->uri_for($fname, { 't' => $static_file_cache{$fname} || 0 });
                }
            },
        },
        %$view_conf
    });
}

1;
