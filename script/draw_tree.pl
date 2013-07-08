#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;
use Getopt::Long;
use Bio::Phylo::Factory;
use Bio::Phylo::IO 'parse_tree';
use Bio::Phylo::Util::Logger ':levels';

# process command line arguments
my $verbosity = WARN;
my $format    = 'svg';
my $width     = 800;
my $height    = 600;
my $radius    = 20;
my $mode      = 'clado';
my $shape     = 'rect';
my ( $infile, $outfile, $mapping, %color );
GetOptions(
	'verbose+'  => \$verbosity,
	'infile=s'  => \$infile,
	'outfile=s' => \$outfile,
	'mapping=s' => \$mapping,
	'format=s'  => \$format,
	'width=i'   => \$width,
	'height=i'  => \$height,
	'color=s'   => \%color,
	'mode=s'    => \$mode,
	'shape=s'   => \$shape,
	'radius=i'  => \$radius,
);

# instantiate helper objects
my $log = Bio::Phylo::Util::Logger->new(
	'-level' => $verbosity,
	'-class' => 'main',
);
my $fac = Bio::Phylo::Factory->new(
	'node' => 'Bio::Phylo::Forest::DrawNode',
	'tree' => 'Bio::Phylo::Forest::DrawTree',
);
$log->info("going to read newick tree from file $infile");
my $tree = parse_tree(
	'-factory'    => $fac,
	'-format'     => 'newick',
	'-file'       => $infile,
	'-as_project' => 1,
);
$log->info("creating $format ${mode}gram drawer, ${width} x ${height} px, shape: $shape");
my $drawer = $fac->create_drawer(
	'-format'            => $format,
	'-tree'              => $tree,
	'-width'             => $width,
	'-height'            => $height,
	'-mode'              => $mode,
	'-shape'             => $shape,
	'-tip_radius'        => $radius,
	'-branch_width'      => $radius,
	'-text_horiz_offset' => $radius * 3,
	'-text_vert_offset'  => 5,
	'-text_width'        => 200,
);

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
		$map{$fields{'ID'}} = \%fields;
	}
	$log->debug(Dumper(\%map));
}

# traverse the tree, apply colors and markers
$tree->visit_depth_first(
	'-post' => sub {
		my $node = shift;
		
		# in post-order traversal we first visit the tips, 
		# which we decorate. we can then copy over the 
		# tip colors to their parents to color the clades		
		if ( $node->is_terminal ) {
			my $id = $node->get_name;
			
			# apply the pretty name to the tip
			my $binomial = $map{$id}->{'BINOMIAL'};
			$node->set_name($binomial);
			$node->set_font_face('Verdana');
			$node->set_font_style('italic');
			$node->set_font_size(12);
			$log->info("$id\t=>\t$binomial");
			die if not $binomial;
			
			# apply the color
			my $location = $map{$id}->{'LOCATION'};
			my $rgb = $color{$location};
			$node->set_branch_color($rgb);
			$log->info("$id color is $rgb");
			die if not $rgb;
			
			# apply the pairing indicator
			my $pair = $map{$id}->{'PAIR'};
			my $white = 'rgb(255,255,255)';
			$node->set_node_color( $pair ? $rgb : $white );
			$node->set_node_outline_colour( $white );
			$log->info("$id tip marker is " . ( $pair ? $rgb : $white ) );
			die if not defined $pair;
		}	
		else {
		
			# get the branch colors of the children. at least one of them
			# will have a color. if there's more than 1 distinct colors
			# we have a problem because the clades were supposed to be
			# monophyletic (though this could still be a rooting problem)
			my @c  = @{ $node->get_children };
			my %cc = map { $_ => 1 } grep { defined } map { $_->get_branch_color } @c;
			my @bc = keys %cc;		
			if ( @bc > 1 ) {
				$log->warn("more than one branch color in children: @bc");
			}
			$node->set_branch_color(shift @bc);
			$node->set_name('');
		}
	}
);

# write the output
open my $fh, '>', $outfile or die $!;
print $fh $drawer->draw;