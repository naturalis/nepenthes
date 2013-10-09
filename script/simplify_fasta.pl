#!/usr/bin/perl
use strict;
use warnings;

while(<>) {
	if ( />gi\|(\d+)\|(?:gb|dbj|emb)\|[^\|]+\| Nepenthes ([a-z]+)/ ) {
		my ( $gi, $species ) = ( $1, $2 );
		print ">N_${species}_${gi}\n";
	}
	elsif ( /\S/ ) {
		print;
	}
}