#!/usr/bin/perl
use List::Util qw(shuffle);
use List::MoreUtils qw(uniq zip);

@questions = qw (t1 t2 t3 t4 q1 q2 q3 q4 q5 q6 q7 q8 q9 q10 q11 q12 q13 q14 q15 q17 q18 q19 q20 q22 q23 q24 q25 q26 q27 q28 q29 q30 q31 q32);

foreach $question (@questions) {
    print "Frobrigating question $question\n";
    replaceColour($question);

    undef $/;
    open(my $fh, "<" , "manual/$question.zones.zones-wilkinson.svg") or die ("Can't open manual/$question.zones.zones-wilkinson.svg\n");
    my $data = <$fh>;
    close $fh;


    # Replace black with white.
    $data =~ s/\#000000/\#ffffff/g;

    open(my $fh, ">" , "$question-wilkinson-nolabels.svg") or die ("Can't open $question-wilkinson-nolabels.svg\n");
    print $fh $data;
    close $fh;
}

sub replaceColour {
    my $qname = shift;
    my @c_icircles = getColours("manual/$qname.zones.zones-icircles.svg");
    my @c_wilkinson = getColours("manual/$qname.zones.zones-wilkinson.svg");

    # Check the list we get from both files is cool
    @c_icircles ~~ @c_wilkinson or die("iCircles and Wilkinson colours don't match for $qname!");

    @palette = shuffle @c_icircles;

    sedColours(\@c_icircles, \@palette, "manual/$qname.zones.zones-icircles.svg", "$qname-icircles.svg");
    sedColours(\@c_icircles, \@palette, "manual/$qname.zones.zones-wilkinson.svg", "$qname-wilkinson.svg");
}

sub getColours {
    my $fname = shift;
    my @colours;
    undef $/;
    open(my $fh, "<" , $fname) or die ("Can't open $fname\n");
    my $data = <$fh>;
    close $fh;

    push (@colours,$&) while($data =~ /(\#[A-Fa-f0-9]{6})/g );

    # Remove some colours that we don't want
    @colours = grep  {!/\#666666/} @colours;
    @colours = grep  {!/\#000000/} @colours;
    @colours = grep  {!/\#010000/} @colours;
    @colours = grep  {!/\#000001/} @colours;
    @colours = grep  {!/\#ffffff/} @colours;

    @colours = uniq(sort(@colours));
    return @colours;
}

sub sedColours {
    my $orig_ref = shift;
    my @orig = @{ $orig_ref };
    my $rep_ref = shift;
    my @replacement = @{ $rep_ref };
    my $fname = shift;
    my $ofname = shift;

    undef $/;
    open(my $fh, "<" , $fname) or die ("Can't open $fname\n");
    my $data = <$fh>;
    close $fh;

    foreach my $i (0..($orig-1)) {
	my $j = $i + 1;
	$data =~ s/$orig[$i]/\#$j$j$j$j$j$j/g;
    }

    foreach my $i (0..($replacement-1)) {
	my $j = $i + 1;
	$data =~ s/\#$j$j$j$j$j$j/$replacement[$i]}/g;
    }

    open(my $fh, ">" , $ofname) or die ("Can't open $ofname\n");
    print $fh $data;
    close $fh;
}
