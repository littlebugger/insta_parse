BEGIN { push @INC, "." }
package JSON_Extrct;
use 5.030;
use utf8;
use strict; use warnings;
use Carp qw( croak );
use Try::Tiny;

#use Moose;
#use Moose::Util::TypeConstraints;
use namespace::autoclean;

use JSON qw(from_json);
use Media;
use Data::Dumper;

sub media_extract($$) {
	my ($self, $html ) = @_;
	my @media;
	my $json = json_extract($html);
	try {
		$json = $json->{entry_data}{PostPage}[0]{graphql}{shortcode_media};
		if ($json->{__typename} eq 'GraphSidecar') { #album
			$json = $json->{edge_sidecar_to_children}{edges};
			for my $edge (@{$json}) {
				push @media, Media->new(json => $edge->{node});
			}
		} else {
			push @media, Media->new(json => $json);
		}
		return @media;
	}
	catch {
		croak "Media exctractor fail $!\n";
	}
}

sub pages_extract($$) {
	my ($self, $html ) = @_;
	my (@pages_info, $json);

	$json = eval { json_extract($html) }; #page come from html?
	if ($@) { #guess not
			my $error = $@; $@ = undef;
			$json = eval { from_json($html)->{data} }; #page from graphql?
			if ($@) {
				die "$error\n Non JSON string in pages_extract $!";
			}
	}

		if (defined $json->{entry_data}) { #premiere
			$json = $json->{entry_data}{ProfilePage}[0]{graphql};
			my $target_id = $json->{user}{id};
			push @pages_info, $target_id;
		}
		#update and so on
		$json = $json->{user}{edge_owner_to_timeline_media};
		my $end_cursor = $json->{page_info}{end_cursor};
		push @pages_info, $end_cursor;

		push @pages_info, map { $_->{node}{shortcode} } @{$json->{edges}};
		return @pages_info;
}

sub json_extract($) {
	my $html = shift;
	try {
		from_json( ($html =~ /<script[^>]*>\s*window._sharedData\s*=\s*((?!<script>).*)\s*;\s*<\/script>/)[0] );
	}
	catch {
		#
		croak "Non HTML data fail $!";
	}
}

1;