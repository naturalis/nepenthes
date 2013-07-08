#!/bin/bash

DATA=data
NEXUS=$DATA/Nepenthes_matk_trimmed_alphabeb
PHYLIP=$NEXUS.phy
MAPPING=$NEXUS.tsv
MAKE_PHYLIP="perl script/make_phylip.pl"
PHYML="phyml -q -p -m GTR -f m -a e -s BEST --quiet"
PHYMLTREE=_phyml_tree.txt


# convert nexus to phylip
if [ ! -f $PHYLIP ]; then
	$MAKE_PHYLIP -infile $NEXUS -outfile $PHYLIP -mapping $MAPPING -verbose
fi

# run PHYML
if [ ! -f $PHYLIP$PHYMLTREE ]; then
	$PHYML -i $PHYLIP
fi
