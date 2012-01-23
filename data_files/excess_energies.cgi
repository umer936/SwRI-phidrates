#!/usr/bin/perl -w

require "vars.pl";
require "LUTIn.txt";
require "LUTOut.txt";

use IO::File;
use File::Temp qw/ tempfile tempdir /;

################################################################
#  parse QUERY_STRING -> filename; display file
################################################################

# this is where the aliases in httpd.conf is set and where the temp files will be written!

$prefix = "/tmp/phidrates";
$reg_exp_prefix = "\/tmp\/phidrates";

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
    local ($nice_name);

    print "Content-type: text/html\n\n";
    print "<HTML><HEAD><TITLE>Excess Energies of $molecule</TITLE></HEAD>\n";
    print "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">";
    #print "<CENTER>";
#    print "Temp Dir = $temp_dir   Input = $input\n";
    $nice_name = &ConvertCanonicalInputName ($molecule);
    print "<H1>Excess Energies of $nice_name</H1>\n";
    print "\n";
    print "<P>";
    chdir ($temp_dir);

    my $url_temp_dir = $temp_dir;
    $url_temp_dir =~ s/$reg_exp_prefix/\/amop_images/g;
    $url_temp_dir =~ s/tmp//;

    #print "</CENTER>";
    print "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/EEOut\"><span>Click here to view or shift-click to \
           download the data wavelength-integrated over each bin!</span></A>\n";	   
    #print "<CENTER>";
    $num_branches = &GenerateBranches ();
    $bnum = 1;
    while ($bnum <= $num_branches) {
        if ($branches[$bnum] eq "Lambda") {
            $branches[$bnum] = "Total";
        }
        $gifname = &GeneratePlot ($temp_dir, "branch_r.$bnum", $branches[$bnum+1]);
        $nice_name = &ConvertCanonicalOutputName ($branches[$bnum+1]);
        print "<H2>$nice_name</H2>";
        print "<IMG SRC = \"$gifname\" BORDER=4>\n";
        print "<P><P>";
        unlink ("branch_r.$bnum");
        $bnum++;
    }
    #print "</CENTER>";

    print "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/EEOut\"><span>Click here to view or shift-click to \
           download the data wavelength-integrated over each bin!</span></A>\n";
    print "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>";
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

sub GenerateBranches {
    local ($num_branches, $num_values, $line, $i, $bnum, $val);

    open (INPUT_FILE, "< EEOut") || die ("Can't open EEOut\n");

    $line = <INPUT_FILE>;
    $line =~ /^ (\d+)/;
    $num_branches = $1;
    $header = <INPUT_FILE>;
    @branches = split (/\s+/, $header);

    $ref_count = 0;
    $ref_count = 0;
    $num_values = 0;
 
    do {
        $line = <INPUT_FILE>;
        if ($line =~ /Rate/) {
            # ignore this line
        } else {
            $line =~ s/^\s+//g;
            $line =~ s/\s+$//g;
            $line =~ s/\s+/ /g;
            @values = split (/ /, $line);
            $i = 0;
            foreach $val (@values) {
                $items{$i,$num_values} = $val;
                $i++;
            }
            $num_values++;
        }
    } while (!eof (INPUT_FILE));
    close (INPUT_FILE);
    $bnum = 1;
    while ($bnum <= $num_branches) {
        open (OUTPUT_FILE, "> branch_r.$bnum") || die ("Couldn't open branch_r.$bnum\n");
        $i = 1;
        $last_x = $items{0,0};
        $last_y = $items{$bnum,0};
        while ($i < $num_values) {

# add the divide back in to show per angstrom
#            $new_y = $last_y; # / ($items{0,$i} - $last_x);

            $new_y = $last_y / ($items{0,$i} - $last_x);
            print OUTPUT_FILE "$last_x $new_y\n";
            $last_x = $items{0,$i};
            $last_y = $items{$bnum,$i};
            $i++;
        }
        close (OUTPUT_FILE);
        $bnum++;
    }
    return ($num_branches);
}

sub GeneratePlot {

    local ($tempdir) = $_ [0];
    local ($filename) = $_ [1];
    local ($branch) = $_ [2];
    local ($gifname);

    my ($fh, $gnuinfo) = tempfile (TEMPLATE => 'gnu_XXXXXX',
                                   DIR => $tempdir, CLEANUP => 1,
                                   SUFFIX => '.info');
    open (TMP_FILE, "> ".$gnuinfo) || die ("Can't open $gnuinfo\n");
    print TMP_FILE "set terminal png\n";
    print TMP_FILE "set size 0.7,0.7\n";
    print TMP_FILE "set title \"Southwest Research Institute\\nBranch: $branch\"\n";
    print TMP_FILE "set xlabel \"Wavelength [A]\"\n";
    print TMP_FILE "set ylabel \"Excess Energies [eV A**-1 s**-1]\"\n";
    if ($use_semi_log eq "false") {
        print TMP_FILE "set logscale xy\n";
    } else {
        print TMP_FILE "set logscale y\n";
    }
    print TMP_FILE "set mytics 5\n";
    print TMP_FILE "plot \"$filename\" title \"\" with steps\n";
    close (TMP_FILE);

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

