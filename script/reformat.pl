#!/usr/bin/perl
use strict;
use warnings;

my %seen;
my %matrix;
my %gi;
my ( $seq, $species, $gi );
while(<>) {
	chomp;
	if ( />(N_[a-z]+)_(.+)/ ) {
		my ( $new_species, $new_gi ) = ( $1, $2 );
		if ( $seq ) {
			reformat( $species, $gi, $seq );
		}
		( $species, $gi ) = ( $new_species, $new_gi );
		undef($seq);
	}
	else {
		$seq .= $_;
	}
}
reformat( $species, $gi, $seq );

my $ntax = scalar keys %matrix;
my $nchar = length $seq;

print <<"HEADER";
#NEXUS
BEGIN DATA;
	DIMENSIONS NTAX=${ntax} NCHAR=${nchar};
	FORMAT DATATYPE=DNA MISSING=N GAP=-;
	MATRIX
HEADER
for my $taxon ( sort { $a cmp $b } keys %matrix ) {
	print $taxon, "\t", $matrix{$taxon}, "\n";
}
print ";\nEND;\nBEGIN NOTES;\n";
my $i = 1;
for my $taxon ( sort { $a cmp $b } keys %gi ) {
	print "\tTEXT TAXON=$i TEXT='", $gi{$taxon}, "';\n";
	$i++;
}
print "END;\n";


sub reformat {
	my ( $species, $gi, $seq ) = @_;
	my $index = ++$seen{$species};
	$matrix{"${species}_${index}"} = $seq;
	$gi{"${species}_${index}"} = $gi;
}