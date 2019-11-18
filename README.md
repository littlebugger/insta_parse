# insta_parse

### Description
This is my own humble Perl library for scraping the Instagram. Works through Web interface.
Goal is to save entire pages to local storage.

SYNOPSIS
=================
```perl
use utf8;
use strict; use warnings;

use Requests qw();

my $agent = Requests->new(account => 'irinashayk'); #why not?
map { print $_->shortcode."\n" } $agent->get_media();
```

## Under construction
## Work in progress