# insta_parse

### Description
This is my own humble Perl library for scraping the Instagram. Works through Web interface.  
Goal is to save entire pages to local storage.  

SYNOPSIS
=================
```perl
use utf8;
use strict; use warnings;

use InstaCombine;

my $agent = InstaCombine->new(account => 'elonmusk'); #why not?
map { print $_->shortcode."\n" } $agent->get_media();
```

## Available Media methods for now  
  
  + For all media:  
  		- is_video - bool  
		- display_url - url string of original image  
		- accessibility_caption  
		- shortcode - page name string  
		- id - owner user id  
		- location - gps location of posted media  
		- display_resources - JSON list of different size thumbnails  
		- dimensions - size dimentions in pixels for original image  
  
 + For video media:  
		- video_duration - video duration in seconds   
		- video_view_count  
		- video_url - ur string of video content  
      
## Under construction
## Work in progress
