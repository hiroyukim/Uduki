package Uduki::DateTime;
use strict;
use warnings;
use DateTime;
use DateTime::TimeZone;
use Smart::Args;

our $TIME_ZONE =  DateTime::TimeZone->new( name => 'Asia/Tokyo' ); 

sub new {
    my $self = shift;
    my %args = @_;

    unless( $args{time_zone} ) {
        $args{time_zone} = $TIME_ZONE;
    }

    DateTime->new( %args );
}

sub now      {
    my $self = shift;
    DateTime->now( time_zone => $TIME_ZONE );
}

sub today    {
    my $self = shift;
    DateTime->today( time_zone => $TIME_ZONE );
}

sub strptime {
    args my $self,
         my $string  => 'Str',
         my $pattern => 'Str';

    my $strp = new DateTime::Format::Strptime(
        pattern     => $pattern,
        time_zone   => $TIME_ZONE,
    );

    $strp->parse_datetime($string);
}

1;
