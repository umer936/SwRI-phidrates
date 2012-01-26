#!/usr/bin/perl -w

require "common.pl";
require "vars.pl";
require "LUTIn.txt";
require "LUTOut.txt";

use IO::File;
use File::Temp qw/ tempfile tempdir /;

################################################################
#  parse QUERY_STRING -> filename; display file
################################################################

$solar_activity = 0.0;
$temp = 1000.0;          #default for Blackbody temperature in Kelvin
$which_tab = "";

# convert variables to a value

$input = $ENV{'QUERY_STRING'};
@items = split (/\?/, $input);
foreach $item (@items) {
    ($key, $val) = split(/=/, $item, 2);
    $val =~ s/%(..)/pack("c",hex($1))/ge;
    $val =~ s/\;//g;
    $$key = $val;
}

#  If option was not on the tab being processed, reset to default value
#  since being overridden by previous parsing of QUERY_STRING.

    if ($solar_activity eq "undefined") {
      $solar_activity = 0.0
    };

# make a temporary directory
# copy the "molecule".dat to our temporary directory
# run photo on the temporary directory

$temp_dir = &MakeTempDirectory ();
&ComputeSpectrum ($solar_activity, $which_tab, $temp_dir);
&CopyMolecule ($molecule, $temp_dir);
&CopyNecessaryFiles ($temp_dir);
&WriteInputFile ($solar_activity, $temp, $which_tab, $temp_dir);
&RunPhotoRat ($molecule, $temp_dir);
&PrintResults ($molecule, $temp_dir);

sub PrintResults {
    local ($molecule, $temp_dir) = @_;

    print "Content-type: text/html\n\n";
    print "<HTML><HEAD><TITLE>$molecule</TITLE></HEAD>\n";
#    print "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">";
    #print "<BODY><CENTER>";
	print "<BODY>";
#    print "Temp Dir = $temp_dir   Input = $input\n";
    $nice_name = &ConvertCanonicalInputName ($molecule);
    if (defined ($nice_name)) {
        print "<H1>$nice_name</H1>\n";
    } else {
        print "<H1>$molecule</H1>\n";
    }
    print "\n";
    print "<P>";
    chdir ($temp_dir);
    open (EEOUT, "< $temp_dir/EEOut") || die "Can't open EEOut!\n";
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
    print "<TABLE><TR><TH>Branch</TH>";
    print "<TH>Rate Coeffs.<BR>[s<sup>-1</sup>]</TH><TH>Excess Energies<BR>[eV]</TH></TR><TR>\n";
    @rates_val = split (/\s+/, $line);
    @energy_val = split (/\s+/, $line2);
    $i = 0;
    foreach $section (@sections) { 
#        $section =~ s/\^//g;
        $nice_name = &ConvertCanonicalOutputName ($section);
        if (defined ($nice_name)) {
            print "<TD>$nice_name</TD>\n";
        } else {
            print "<TD>$section</TD>\n";
        }
        print "<TD>$rates_val[$i]</TD>\n";
        print "<TD>$energy_val[$i]</TD></TR>\n";
        $i++;
    }
    print "</TABLE>";
    #print "</CENTER>";
	print "<HR align=\"center\" width=\"50%\" size=\"1\"><br>";
    print "</BODY></HTML>";
}
