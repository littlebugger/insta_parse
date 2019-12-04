package InstaCombine;

require Exporter;

our %EXPORT_TAGS = ( 'all' => [ qw(
	new
	get_media
	account
	entry_limit
	entry_amount
	target_id

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} }, );

our @EXPORT = qw(
	new
	get_media
);

our $VERSION = '0.01';


# Preloaded methods go here.
use utf8;
use Carp qw( croak );
use Try::Tiny;

use Moose;
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
	$self->end_cursor( ($pages[0] =~ /[0-9a-z]{118}==/i)? shift @pages : undef );
	return @pages;
}

sub extract_media($) {
	JSON_Extrct->media_extract(@_);
}

sub get_media($;@) {
	my ($self, %kwargs) = @_;
	my $requested_amount = $kwargs{amount} // $self->entry_amount;
	my @pages;
	while ($requested_amount > @pages) {
		push @pages, $self->get_list_of_pages(
			(defined $self->target_id and defined $self->end_cursor)?
				$self->make_update($requested_amount - @pages) : 
				$self->make_init_request()
			);
		last if not defined $self->end_cursor;
	}
	my @media = map { extract_media( $self->get_page( $_ ) ) } @pages;
	return @media;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

InstaCombine - Perl extension for simply scrap pictures and videos from instagram

=head1 SYNOPSIS

  use InstaCombine;

  my $account = 'kittenisodd';

  my $agent = InstaCombine->new(account => $account);
  map { say ($_->get_url) } $agent->get_media();

=head1 DESCRIPTION

Flex program to scrap instagram with perl basics. No particular value whatsoever.

=head2 EXPORT

requires JSON, HTTP::Request, HTTP::CookieJar::LWP, LWP::UserAgent

=head1 SEE ALSO

Media.pm for spec about scrap which can be exracted from instagram with current version of program.

https://github.com/littlebugger/insta_parse for request issues, bugs and requests.

=head1 AUTHOR

little_bugger,

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by little_bugger

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
