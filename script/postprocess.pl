#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

# process command line arguments
my ( $infile, $outfile );
GetOptions(
	'infile=s'  => \$infile,
	'outfile=s' => \$outfile,
);

# open handles
open my $infh,  '<', $infile  or die $!;
open my $outfh, '>', $outfile or die $!;

# clean up the SVG
while(<$infh>) {

	# remove the text rotation that illustrator chokes on
	s/transform="[^"]+"//; 

	# remove white nodes
    s/<circle .+\/>// if /\Qfill: rgb(255,255,255)\E/;
    
    if ( /circle/ && /x="(\d+)"/ ) {
    	my $x = $1;
    	my $newx = $x + 11;
    	s/x="$x"/x="$newx"/;
    }
	
	print $outfh $_;
}