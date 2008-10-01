#!/bin/perl -w

require "vars.pl";
require "eleLUT.pl";

use IO::File;
use POSIX qw(tmpnam);

################################################################
#  parse QUERY_STRING -> filename; display file
################################################################

# convert variables to a value

$input = $ENV{'QUERY_STRING'};
@items = split (/\?/, $input);
foreach $item (@items) {
    ($key, $val) = split(/=/, $item, 2);
    $val =~ s/%(..)/pack("c",hex($1))/ge;
    $val =~ s/\;//g;
    $$key = $val;
}

# make a temporary directory
# copy the "molecule".dat to our temporary directory
# run photo on the temporary directory

$temp_dir = &MakeTempDirectory ();
&ComputeSpectrum ($solar_activity, $temp_dir);
&CopyMolecule ($molecule, $temp_dir);
&RunPhotoRat ($molecule, $temp_dir);
&PrintResults ($molecule, $temp_dir);

sub PrintResults {
    local ($molecule, $temp_dir) = @_;

    print "Content-type: text/html\n\n";
    print "<HTML><HEAD><TITLE>$molecule</TITLE></HEAD>\n";
#    print "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">";
    print "<BODY><CENTER>";
#    print "Temp Dir = $temp_dir   Input = $input\n";
    $nice_name = &ConvertCanonicalBranchName ($molecule);
    print "<H1>$nice_name</H1>\n";
    print "\n";
    print "<P>";
    chdir ($temp_dir);
    open (EEOUT, "< $temp_dir/EEOUT") || die "Can't open EEOUT!\n";
    $line = <EEOUT>;
    $line = <EEOUT>;
    $line =~ s/Lambda//g;
    $line =~ s/^\s+//g;
##    print "<P>$line<P>\n";
    @sections = split (/\s+/, $line);
    while (!eof && !($line =~ /Rate Coeff/)) {
        $line = <EEOUT>;
    }
    $line2 = <EEOUT>;
    close (EEOUT);
    $line =~ s/ Rate Coeffs. = //g;
    $line =~ s/^\s+//g;
    $line2 =~ s/ Av. Excess E = //g;
    $line2 =~ s/^\s+//g;
#    print "<P>$line<P>\n";
    print "<TABLE BORDER=2 CELLPADDING = 5><TR><TH>Branch</TH>";
    print "<TH>Rate Coeffs.<BR>[s<sup>-1</sup>]</TH><TH>Excess Energies<BR>[eV]</TH></TR><TR>\n";
    @rates_val = split (/\s+/, $line);
    @energy_val = split (/\s+/, $line2);
    $i = 0;
    foreach $section (@sections) { 
        $section =~ s/\^//g;
        $nice_name = &ConvertCanonicalBranchName ($section);
        print "<TD>$nice_name</TD>\n";
        print "<TD>$rates_val[$i]</TD>\n";
        print "<TD>$energy_val[$i]</TD></TR>\n";
        $i++;
    }
    print "</TABLE>";
    print "</CENTER>";
    print "</BODY></HTML>";
}

sub RunPhotoRat {

    local ($molecule, $temp_dir) = @_;

    chdir ($temp_dir);
    `$amop_cgi_bin_dir/photo/photo`;
}

sub CopyMolecule {

    local ($molecule, $temp_dir) = @_;

    `cp $amop_cgi_bin_dir/photo/hrecs/$molecule.dat $temp_dir/HREC`;
}

sub MakeTempDirectory {

    local ($temp_dir);

# make a temporary directory

    $temp_dir = tmpnam ();
    $temp_dir =~ s/var\/tmp/tmp\/joey/;
    if (!(-e "/tmp/joey")) {
        mkdir ("/tmp/joey", 0777);
    }
    mkdir ($temp_dir, 0777);
    return ($temp_dir);
}

sub ComputeSpectrum {

    my ($solar_activity, $temp_dir) = @_;
    my ($i, $x, $y, $sunqflux_line, $sunqflux, $aqratio_line, $aqratio);

# compute the new data
    `cp $amop_cgi_bin_dir/photo/hrecs/$molecule.dat $temp_dir/HREC`;

    open (NEWDATAFILE, "> $temp_dir/PHFLUX.DAT") || die ("Location: error.gif\n\n");
    open (AQRATIO, "< $amop_cgi_bin_dir/photo/aqratio.dat") || die ("Location: error.gif\n\n");
    open (SUNQFLUX, "< $amop_cgi_bin_dir/photo/sunqflux.dat") || die ("Location: error.gif\n\n");

    $i = 0;
    while ($sunqflux_line = <SUNQFLUX>) {
        ($x, $sunqflux) = split (/\s+/, $sunqflux_line);
        if ($i < 162) {
            $aqratio_line = <AQRATIO>;
            ($x, $aqratio) = split (/\s+/, $aqratio_line);
            $y = $sunqflux + $solar_activity * ($aqratio - 1.0) * $sunqflux;
        } else {
            $y = $sunqflux;
        }
        printf (NEWDATAFILE "%8.0f  %8.2e\n", $x, $y);
        $i++;
    }

    close (NEWDATAFILE);
    close (AQRATIO);
    close (SUNQFLUX);
}
