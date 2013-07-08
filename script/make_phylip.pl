#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Bio::Phylo::IO 'parse_matrix';
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my $verbosity = WARN;
my ( $infile, $outfile, $mapping );
GetOptions(
	'infile=s'  => \$infile,
	'outfile=s' => \$outfile,
	'mapping=s' => \$mapping,
	'verbose+'  => \$verbosity,
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-class' => 'main',
	'-level' => $verbosity,
);

# read matrix
my $matrix = parse_matrix(
	'-format' => 'nexus',
	'-file'   => $infile,
	'-as_project' => 1,
);
my ( $ntax, $nchar ) = ( $matrix->get_ntax, $matrix->get_nchar );
$log->info("read matrix from $infile, ntax: $ntax, nchar: $nchar");

# initialize PHYLIP file
open my $phylipFH, '>', $outfile or die $!;
print $phylipFH $ntax, ' ', $nchar, "\n";
$log->info("going to write PHYLIP data to $outfile");

# initialize spreadsheet mapping
open my $mappingFH, '>', $mapping or die $!;
print $mappingFH join("\t", qw(ID BINOMIAL PAIR LOCATION)), "\n";
$log->info("going to write taxon mapping to $mapping");

# iterate over rows to create new names
my $counter = 0;
$matrix->visit(sub{
	my $row  = shift;
	my $name = $row->get_name;
	my $id = 'taxon' . ++$counter;
	$log->info("$id:\t$name");
	
	# build a nice scientific name
	my $binomial = 'Nepenthes';
	if ( $name =~ /[_ ]([a-z]+)[_ ]/ ) {
		my $epithet = $1;
		$binomial .= ' ' . $epithet;
		$log->info("$id is species $binomial");
	}
	
	# taxon is part of a pair
	my $pair = '';
	if ( $name =~ /pair(\d+)/ ) {
		$pair = $1;
		$log->info("$id is part of pair $pair");
	}
	
	# fetch high/lowland
	my $location;
	if ( $name =~ /([HL])/ ) {
		$location = $1;
		$log->info("$id is on location $location");
	}
	
	# print PHYLIP output
	my $char = $row->get_char;
	my $padding = ' ' x ( 10 - length($id) );
	print $phylipFH $id, $padding, $char, "\n";
	
	# print mapping spreadsheet
	print $mappingFH join("\t",$id,$binomial,$pair,$location), "\n";
});