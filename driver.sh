#!/bin/bash

DATA=data
NEXUS=$DATA/Nepenthes_matk_trimmed_alphabeb
PHYLIP=$NEXUS.phy
MAPPING=$NEXUS.tsv
MAKE_PHYLIP="perl script/make_phylip.pl"
PHYML="phyml -q -p -m GTR -f m -a e -s BEST --quiet"
PHYMLTREE=_phyml_tree.txt
TREE=$PHYLIP$PHYMLTREE

# drawing parameters
# Lowland (pairs1-3) - Amethyst: RGB(197/0/255) Lab(55.792966435524/85.1295049022369/66.5430243345725)
# Highland (pairs4-6)- Lapis Blue: RGB(0/92/230) Lab(49.0657262451549/18.7804258920237/67.4316364640922)
L='rgb(197,0,255)'
H='rgb(0,92,230)'
WIDTH=800
HEIGHT=1600
MODE=clado # i.e. cladogram, don't care about branch lengths
SHAPE=rect # i.e. rectangular branches, can also be curvy?
RADIUS=7  # tip radius, which we use to mark species pairs
IMAGE=$NEXUS.svg
DRAW="perl script/draw_tree.pl"
POSTPROCESSED=$NEXUS-pp.svg
POSTPROCESS="perl script/postprocess.pl"

# convert nexus to phylip
if [ ! -f $PHYLIP ]; then
	$MAKE_PHYLIP -infile $NEXUS -outfile $PHYLIP -mapping $MAPPING -verbose
fi

# run PHYML
if [ ! -f $TREE ]; then
	$PHYML -i $PHYLIP
fi

# draw tree
if [ ! -f $IMAGE ]; then
	$DRAW -i $TREE -o $IMAGE -map $MAPPING -mode $MODE -verbose -shape $SHAPE\
		-radius $RADIUS -color L=$L -color H=$H -width $WIDTH -height $HEIGHT
fi

# postprocess SVG
if [ ! -f $POSTPROCESSED ]; then
	$POSTPROCESS -i $IMAGE -o $POSTPROCESSED
fi
