#!/usr/bin/perl

use IO::File;
use File::Temp qw/ tempfile tempdir /;

require "vars.pl";

$solar_activity = 0.0;

################################################################
#  parse QUERY_STRING -> filename; display file
################################################################

# this is where the aliases in httpd.conf is set and where the temp files will be written!

$prefix = "/tmp/phidrates";
$reg_exp_prefix = "\/tmp\/phidrates";

print "Content-type: text/html\n\n";

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

# 1) open a temporary directory 
# 2) compute the new data and write it to our temporary directory
# 3) run gnuplot over the new data file
# 4) return the name of the picture

$temp_dir = &MakeTempDirectory ();
&ComputeSpectrum ($solar_activity, $temp_dir);
$gifname = &CreateGIF ($temp_dir);

print "<HTML><HEAD><TITLE>Solar Spectrum</TITLE></HEAD>\n";
print "<BODY><H1>Solar Spectrum</H1>";

print "<IMG SRC=\"$gifname\">";
print "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>";

print "</BODY></HTML>";
exit (0);

sub MakeTempDirectory {

    local ($temp_dir);

# make a temporary directory

    if (!(-e $prefix)) {
        mkdir ($prefix, 0777);
    }

    $temp_dir = tempdir (TEMPLATE => 'fileXXXXXX',
                         DIR => $prefix,
                         CLEANUP => 0);
    chmod (0755, $temp_dir);
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

    local ($tempdir) = $_ [0];
    local ($gifname);

    my ($fh, $gnuinfo) = tempfile (TEMPLATE => 'gnu_XXXXXX',
                                   DIR => $tempdir, CLEANUP => 1,
                                   SUFFIX => '.info');
    open (DATAFILE, "> ".$gnuinfo) || die ("Can't open $gnuinfo\n");

    print DATAFILE "set terminal png size 800,600 font \"/usr/share/fonts/dejavu-lgc/DejaVuLGCSans.ttf\" 12\n";
    if ($use_semi_log eq "false") {
        print DATAFILE "set logscale xy\n";
    } else {
        print DATAFILE "set logscale y\n";
    }

print DATAFILE << "EOF";

# Line style for axes
set style line 80 lt 0

# Line style for grid
set style line 81 lt 3  # dashed
set style line 81 lw 0.5  # grey

# set grid back linestyle 81
set xtics nomirror
set ytics nomirror

#set log x
set mxtics 10    # Makes logscale look good.

# Line styles: try to pick pleasing colors, rather
# than strictly primary colors or hard-to-see colors
# like gnuplot's default yellow.  Make the lines thick
# so they're easy to see in small plots in papers.
set style line 1 lt 1
set style line 2 lt 1
set style line 3 lt 1
set style line 4 lt 1
set style line 1 lt 1 lw 6 pt 7
set style line 2 lt 2 lw 6 pt 9
set style line 3 lt 3 lw 6 pt 5
set style line 4 lt 4 lw 6 pt 13
set origin 0, 0.01
EOF

    print DATAFILE "set title \"Southwest Research Institute\\nSolar Activity: $solar_activity\"\n";
    print DATAFILE "set xrange [1:100000]\n";
    print DATAFILE "set xlabel \"Wavelength  (A)\"\n";
    print DATAFILE "set ylabel \"Solar Flux  (Photons cm**-2 s**-1 A**-1)\"\n";
    print DATAFILE "set nokey\n";
    print DATAFILE "set mxtics 5\n";
    print DATAFILE "plot \"$temp_dir/PHFLUX.DAT\" with steps\n";
    close (DATAFILE);

    my ($fh2, $gifname) = tempfile (TEMPLATE => 'XXXXXX',
                                   DIR => $tempdir,
                                   CLEANUP => 0,
                                   SUFFIX => '.png');
    system ("/usr/bin/gnuplot $gnuinfo > $gifname");
    if ($? == -1) {
        print "failed to execute: $!\n";
    } elsif ($? & 127) {
        printf "child died with signal %d, %s coredump\n",
        ($? & 127),  ($? & 128) ? 'with' : 'without';
    } else {
#        printf "child exited with value %d\n", $? >> 8;
    }

    chmod (0644, $gifname);
    $plotname = $gifname;
    $plotname =~ s/$reg_exp_prefix/..\/amop_images/g;
    return ($plotname);
}

