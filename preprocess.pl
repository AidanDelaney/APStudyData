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

source("doPlot.R")

# convert an 8-bit RGB spec (i.e. HTML) to R.
hrgb <- function (r, g, b) {
  rgb(r/255, g/255, b/255)
}

spec <-$spec
vd <- venneuler(spec)

circles <- getICirclesDiagram(spec)

n <- 7
cs <- sapply(seq.int(n), function(x) {hsv(h= x*(1/n), s = 0.5, v = 0.5, alpha = 1)})

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
