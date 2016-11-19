package Grid;

use Moose;
use Moose::Util::TypeConstraints;

use List::AllUtils qw/max/;
use POSIX qw/ceil/;

# number of items
has [ qw/grid_width grid_height/ ] => ( is => 'rw', isa => 'Int' );
# item size
has [ qw/item_width item_height/ ] => ( is => 'rw', isa => 'Num' );
# gutter border
has [ qw/gutter border/ ] => ( is => 'rw', isa => 'Num' );

subtype 'Seq', as 'Str', where { /[h,v]/i };
has arrange => ( is => 'rw', isa => 'Seq', default => sub { 'h' } );

# has item_sizes => ( is => 'rw', isa => 'ArrayRef[ArrayRef[Num]]' );


around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if ( !ref $_[0] ) {
	
	my %h;
	@h{qw/grid_width grid_height item_width item_height gutter border/} = grep { /[^a-z]/i } @_;

	($h{arrange}) = (grep { /^[h,v]i/ } @_) || ('h');
	$h{gutter} ||= 0;
	$h{border} ||= 0;
	return $class->$orig( \%h );
    } else {
	return $class->$orig(@_);
    }
};

sub total_height {
    my $self = shift;
    return $self->border + $self->item_height * $self->grid_height + $self->gutter * ($self->grid_height - 1) + $self->border
};

sub total_width {
    my $self = shift;
    return $self->border + $self->item_width * $self->grid_width + $self->gutter * ($self->grid_width - 1) + $self->border
};

sub bbox {
    my $self = shift;
    my ($w, $h) = ($self->total_width, $self->total_height);
    return wantarray ? ($w, $h) : [ $w, $h ];
}

sub sequence {
    my $self = shift;
    my ($gw, $gh) = map { $self->$_ } qw/grid_width grid_height/; 
    my @sequence;

    if (lc($self->arrange) eq 'v') {
	for my $x (0..$gw-1) { for my $y (0..$gh-1) { push @sequence, [$x, $y] } }
    } else {
	for my $y (0..$gh-1) { for my $x (0..$gw-1) { push @sequence, [$x, $y] } }
    }
    return @sequence;
}

sub position {
    my $self = shift;
    my ($x, $y, $x1, $y1, $x2, $y2) = @_;
    my ($gw, $gh, $iw, $ih, $gt, $pb) = map { $self->$_ } qw/grid_width grid_height item_width item_height gutter border/; 

    # $_->[0] = $iw * $_->[0] + ($gt * $_->[0]) + $pb;
    # $_->[1] = $ih * $_->[1] + ($gt * $_->[1]) + $pb
}

sub positions {
    my $self = shift;
    my ($x1, $y1, $x2, $y2) = @_;
    for ($x1, $y1) { $_ ||= 0 }; 
    my ($gw, $gh, $iw, $ih, $gt, $pb) = map { $self->$_ } qw/grid_width grid_height item_width item_height gutter border/; 

    # first assign positions in terms of page coordinates
    my @grid = $self->sequence;

    # then calculate and assign the actual position
    for (@grid) {
	$_->[0] = $iw * $_->[0] + ($gt * $_->[0]) + $pb + $x1;
	$_->[1] = $ih * $_->[1] + ($gt * $_->[1]) + $pb + $y1
    };

    if (defined $x2 || defined $y2) { for (@grid) {
	$_->[2] = $_->[0] + $x2;
	$_->[3] = $_->[1] + $y2;
    } }
    
    return @grid;
}

sub numbers {
    my $self = shift;
    return (1..($self->grid_width * $self->grid_height))
}

__PACKAGE__->meta->make_immutable;

1;
