package Media;
use 5.030;
use utf8;
use strict; use warnings;

use Moose;

sub media_info {
	qw(
		is_video 
		display_url 
		accessibility_caption 
		__typename 
		shortcode 
		id 
		location 
		display_resources
		dimensions
	)
}

has $_ => ( is => 'rw', default => undef )
	for media_info;

sub new {
	my ( $class, %kwargs ) = @_;
	my $json = $kwargs{json};
	$class = ref $class if ref $class;
	my $self = bless {}, $class;
	$self->{$_} = $json->{$_} for media_info;
	$self;
}

#sub comment_info {
#	qw (edge_media_preview_comment edges 0 node)
#}


1;