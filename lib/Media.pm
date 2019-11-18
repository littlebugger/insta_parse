package Media;
use 5.030;
use utf8;

use Moose::Role;

requires qw( get_url );

my %TYPES = (
	GraphVideo => 'Video',
	GraphImage => 'Image',
);

has 'json' => (
	is => 'rw',
	required => 1,
);

sub base_info {
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

has [&base_info] => ( is => 'rw', default => undef );

sub new {
	my ($class, %kwargs) = @_;
	$class = ref $class if ref $class;
	my $self = bless {}, $class;
	my $json = $kwargs{json};
	$self->{$_} = $json->{$_} for base_info;
	$self->{json} = $json;
	return $TYPES{$json->{__typename}}->new($self);
}

1;

package Image;
use Moose;
use namespace::autoclean;

with qw( Media );

sub new {
	my ($class , $generic ) = @_;
	$class = ref $class if ref $class;
	bless $generic, $class;
}

sub get_url($) {
	return shift->display_url;
}

1;

package Video;
use Moose;
use namespace::autoclean;

with qw( Media );

sub video_info {
	qw(
		video_duration
		video_view_count
		video_url
	)
}

has [&video_info] => ( is => 'rw', default => undef );

sub new {
	my ($class , $generic ) = @_;
	$class = ref $class if ref $class;
	my $self = bless $generic, $class;
	$self->{$_} = $self->{json}->{$_} for video_info;
	$self;
}

sub get_url($) {
	return shift->video_url;
}

1;