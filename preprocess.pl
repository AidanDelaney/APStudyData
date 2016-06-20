#!/bin/perl

my $spec = 'c(';
while(<>) {
    my @tokens = split(/ /);
    my $area = pop(@tokens);
    chomp($area);

    # truncate each token to a single character
    #@tokens = map {substr($_, 0, 1)}  @tokens;
    $spec .= '"' . join('&', @tokens) . '"=' . $area . ', ';
}
$spec .= ')';

# remove the last ', )'
$spec =~ s/, \)/\)/;

print("spec: $spec\n");

open(my $fh, '>', 'tmp.R');

print $fh <<EOF;

library(venneuler)
library(jsonlite)
library(colorspace)

source("doPlot.R")

spec <-$spec
vd <- venneuler(spec)

circles <- getICirclesDiagram(spec)

cs <- rainbow_hcl(length(circles\$circles\$label))
cs <- cs[sample(length(circles\$circles\$label))]

svg("$ARGV.zones-icircles.svg")
plotCircles(circles, spec, border=cs)

svg("$ARGV.zones-wilkinson.svg")
doPlot(vd, border=cs, col = c("white"), spec=spec)

svg("$ARGV.zones-wilkinson-nolabels.svg")
doPlot(vd, border=cs, col = c("white"), areaLabels=FALSE)
EOF

close $fh;

#print $prog
`R --no-save < tmp.R`
