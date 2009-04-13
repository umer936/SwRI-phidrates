#!/usr/bin/perl

use IO::File;
use POSIX qw(tmpnam);

require "vars.pl";

################################################################
#  parse QUERY_STRING -> filename; display file
################################################################

print "Content-type: text/html\n\n";

$input = $ENV{'QUERY_STRING'};
@items = split (/\?/, $input);
foreach $item (@items) {
    ($key, $val) = split(/=/, $item, 2);
    $val =~ s/%(..)/pack("c",hex($1))/ge;
    $val =~ s/\;//g;
    $$key = $val;
}

# 1) open a temporary directory 
# 2) compute the new data and write it to our temporary directory
# 3) run gnuplot over the new data file
# 4) return the name of the picture

$temp_dir = &MakeTempDirectory ();
&ComputeSpectrum ($solar_activity, $temp_dir);
$gifname = &CreateGIF ($temp_dir);

print "<HTML><HEAD><TITLE>Solar Spectrum</TITLE></HEAD>\n";
print "<BODY><P>Solar Spectrum<P></BODY>";
print "<IMG SRC=\"$gifname\"><P></BODY></HTML>";
exit (0);

sub MakeTempDirectory {

    local ($temp_dir);

# make a temporary directory

    $temp_dir = tmpnam ();
#    $temp_dir =~ s/var\/tmp/tmp\/joey/;
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

    open (NEWDATAFILE, "> $temp_dir/PHFLUX.DAT") || die ("Location: error.gif\n\n");
    open (AQRATIO, "< $amop_cgi_bin_dir/photo/aqratio.dat") || die ("Location: error.gif\n\n");
    open (SUNQFLUX, "< $amop_cgi_bin_dir/photo/sunqflux_plot.dat") || die ("Location: error.gif\n\n");

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

sub CreateGIF {

    my ($temp_dir) = $_ [0];
    my ($gnuplot_cmds, $gifname);

    $gnuplot_cmds = "$temp_dir/spectrum.gp";
    $gifname = tmpnam ();
    $gifname .= ".png";

    open (DATAFILE, "> $gnuplot_cmds");
    print DATAFILE "set terminal png\n";
    print DATAFILE "set output \"$gifname\"\n";
    if ($use_semi_log eq "false") {
        print DATAFILE "set logscale xy\n";
    } else {
        print DATAFILE "set logscale y\n";
    }
    print DATAFILE "set title \"Southwest Research Institute\\nSolar Activity: $solar_activity\"\n";
    print DATAFILE "set xrange [1:100000]\n";
    print DATAFILE "set xlabel \"Wavelength  (A)\"\n";
    print DATAFILE "set ylabel \"Solar Flux  (Photons cm**-2 s**-1 A**-1)\"\n";
    print DATAFILE "set nokey\n";
    print DATAFILE "set mxtics 5\n";
    print DATAFILE "plot \"$temp_dir/PHFLUX.DAT\" with steps\n";
    close (DATAFILE);

    `/usr/bin/gnuplot $gnuplot_cmds`;

    unlink ($gnuplot_cmds);
#    $gifname =~ s/\/tmp\//http:\/\/phirates.space.swri.edu\/amop_data_files\//g;
    return ($gifname);
}

