#!/usr/bin/perl
use strict;
use warnings;

my @infiles = @ARGV;

# count the files in which it occurs, and the number of times in that file
my %seen;
for my $file ( @infiles ) {
	open my $fh, '<', $file or die $!;
	while(<$fh>) {
		if ( />N_([a-z]+)/ ) {
			my $species = $1;
			$seen{$species} = {} if not $seen{$species};
			$seen{$species}->{$file}++;
		}
	}
}

# write the output
for my $file ( @infiles ) {

	# create outfile name
	my $outfile = $file;
	$outfile =~ s/\.fa/-reconciled.fa/;
	
	# open handles
	open my $in, '<', $file or die $!;
	open my $out, '>', $outfile or die $!;
	
	# flag to determine whether focal sequence is echo'd
	my $printme = 0;
	while(<$in>) {
	
		# capture FASTA defline
		if ( />N_([a-z]+)/ ) {
			my $species = $1;
			
			# flag is true of the number of files in which the species occurs equals total
			$printme = scalar( keys( %{ $seen{$species} } ) ) == scalar( @infiles );
		}
		print $out $_ if $printme;
	}
}