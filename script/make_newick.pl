#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;
use Data::Dumper;
use Bio::Phylo::IO 'parse_tree';
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
	'-level' => $verbosity,
	'-class' => 'main',
);
my $tree = parse_tree(
	'-format' => 'nexus',
	'-file'   => $infile,
	'-as_project' => 1,
);
$log->info("read tree from $infile");

# read mapping file
my %map;
{
	my @header;
	$log->info("going to read mapping from file $mapping");
	open my $fh, '<', $mapping or die $!;
	LINE: while(<$fh>) {
		chomp;
		my @record = split /\t/, $_;
		
		# store header
		@header = @record and next LINE unless @header;
		
		# create fields identified by column headers
		my %fields = map { $header[$_] => $record[$_] } 0 .. $#header;
		
		# store this record onder the unique ID we assigned to the taxon
		$map{$fields{'BINOMIAL'}} = \%fields;
	}
	$log->debug(Dumper(\%map));
}

# now map binomials to IDs
my @delete;
for my $tip ( @{ $tree->get_terminals } ) {
	my $name = $tip->get_name;
	
	# names in the pseudochars file are not pretty binomials
	if ( $name =~ /^N\._(.+)$/ ) {
		my $epithet = $1;
		my $binomial = join ' ', 'Nepenthes', $epithet;
		
		# map the names back to IDs
		if ( exists $map{$binomial} ) {
			my $id = $map{$binomial}->{'ID'};
			$tip->set_name($id);
		}
		else {
			$log->warn("don't know this tip: $name");
			push @delete, $tip;
		}
	}
	else {
		$log->warn("couldn't parse name $name");
		push @delete, $tip;
	}
}

# remove all unknown tips
$tree->prune_tips(\@delete);
$log->info("pruned ".scalar(@delete)." stray tips");

# write the output
open my $fh, '>', $outfile or die $!;
print $fh $tree->to_newick;