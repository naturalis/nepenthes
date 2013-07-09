#!/usr/bin/perl
use strict;
use warnings;
use Bio::Phylo::IO 'parse_tree';

my $infile = shift;
my $tree = parse_tree(
	'-format'     => 'nexus',
	'-as_project' => 1,
	'-file'       => $infile,
);

my @tips = @{ $tree->get_terminals };
for my $i ( 0 .. $#tips - 1 ) {
	for my $j ( $i + 1 .. $#tips ) {
		my $species_i = $tips[$i]->get_name;
		my $species_j = $tips[$j]->get_name;
		my $dist = $tips[$i]->calc_nodal_distance($tips[$j]);
		print $species_i, "\t", $species_j, "\t", $dist, "\n";
	}
}