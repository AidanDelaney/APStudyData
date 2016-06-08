#!/bin/perl

my $spec = 'c(';
while(<>) {
    my @tokens = split(/ /);
    my $area = pop(@tokens);
    chomp($area);

    # truncate each token to a single character
    @tokens = map {substr($_, 0, 1)}  @tokens;
    $spec .= '"' . join('&', @tokens) . '"=' . $area . ', ';
}
$spec .= ')';

# remove the last ', )'
$spec =~ s/, \)/\)/;

print("spec: $spec\n");

open(my $fh, '>', 'tmp.R');

print $fh <<EOF;
library(venneuler)
library(euleR)

source("doPlot.R")

spec <- $spec
vd <- venneuler(spec)
svg("$ARGV.svg")

# Use the drawing routine rather than venneuler::plot
cs <- c(hrgb(166,206,227),hrgb(31,120,180),hrgb(178,223,138),hrgb(51,160,44),hrgb(251,154,153),hrgb(227,26,28),hrgb(253,191,111),hrgb(255,127,0),hrgb(202,178,214),hrgb(106,61,154))
doPlot(vd, border=cs, col = c("white"))

svg("$ARGV-nolabels.svg")
ls <- array('', length(spec))
vd\$labels <- ls
doPlot(vd, border=cs, col = c("white"))
doPlot(vd)
EOF

close $fh;

#print $prog
`R --no-save < tmp.R`
