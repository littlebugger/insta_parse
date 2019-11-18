BEGIN { push @INC, '.' }
package Requests;
use 5.030;
use utf8;
use strict; use warnings;
use Carp qw( croak );
use Try::Tiny;

use Moose;
#use Moose::Util::TypeConstraints;
use namespace::autoclean;

use HTTP::Request;
use HTTP::CookieJar::LWP;
use LWP::UserAgent;
use List::Util qw(min max);
use Time::HiRes qw(sleep);
use JSON_Extrct qw();

has 'account' => (
	is => 'rw',
	isa => 'Str',
	required => 1,
);

around 'account' => sub {
 my $next = shift;
 my $self = shift;
 blessed $self ? $self->$next(@_) : croak "Specify account name in $self";
};

has 'ua' => (
	is => 'rw',
	default => sub { LWP::UserAgent->new(
		#	    cookie_jar        => HTTP::CookieJar::LWP->new,
		#	    protocols_allowed => ['http', 'https'],
		#	    timeout           => 10,
		#	    agent 						=> 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Safari/537.36 OPR/63.0.3368.57756'
		);
	},
);

my %ro = ( 
	update_query => 'https://www.instagram.com/graphql/query/',
	query_hash => 'c6809c9c025875ac6f02619eae97a80e',
	base_query => 'https://www.instagram.com/',
	page_entry => 'p/',
	entry_limit => 50,
);
my %rw = ( 
	end_cursor => undef,
	entry_amount => 12,
	target_id => undef,
);

while (my ($ro_key, $ro_value) = each %ro) {
	has $ro_key => (is => 'ro', default => $ro_value);
}

while (my ($rw_key, $rw_value) = each %rw) {
	has $rw_key => (is => 'rw', default => $rw_value);
}

sub prepare($) {
	my $url = shift;
	try {
		return HTTP::Request->new('GET', $url);
	}
	catch {
		#todo
		croak "Request create fail $url\n$!";
	}
}

sub get_request($$) {
	my ( $self, $url ) = @_;
	try {
		sleep(2);
		my $req = prepare($url);
		my $response = $self->ua->request($req);
		if ($response->is_success) {
			return $response->decoded_content;
		}
		else {
			die $response->status_line;
		}
	}
	catch {
		#todo
		croak "Get request fail $url\n$!";
	} 
}

sub make_init_request($) {
	my $self = shift;
	my $instagram_page = $self->base_query.$self->account;
	return $self->get_request($instagram_page);
}

sub make_update($$) {
	my ($self, $requested_amount) = @_;
	my $svariables = sprintf '{"id":"%s","first":%d,"after":"%s"}', $self->target_id, max($self->entry_amount, $requested_amount), $self->end_cursor;
	my $json_content = sprintf 'query_hash=%s&variables=%s', $self->query_hash, $svariables;
	return $self->get_request($self->update_query."?$json_content");
}

sub get_page($$) {
	my ( $self, $shortcode ) = @_;
	my $page_url = $self->base_query.$self->page_entry.$shortcode;
	return $self->get_request($page_url);
}

sub get_list_of_pages($$) {
	my ($self, $html) = @_;
	my @pages = eval { JSON_Extrct->pages_extract($html) };
	croak "$!" if ($@);
	$self->target_id(shift @pages) if (not defined $self->target_id);
	$self->end_cursor(shift @pages);
	return @pages;
}

sub extract_media($) {
#	my ($self, $html) = @_;
	JSON_Extrct->media_extract(@_);
}

sub get_media($;@) {
	my $self = shift;
	my %args = @_;
	my $requested_amount = $args{amount} // $self->entry_amount;
	my @pages;
	#my $html = $self->make_init_request();
	#my @pages = $self->get_list_of_pages($html);
	while ($requested_amount > @pages) {
		push @pages, $self->get_list_of_pages(
			(defined $self->target_id and defined $self->end_cursor)?
				$self->make_update($requested_amount - @pages) : 
				$self->make_init_request()
			);
	}
	my @media = map { extract_media( $self->get_page( $_ ) ) } @pages;
	return @media;
}

1;