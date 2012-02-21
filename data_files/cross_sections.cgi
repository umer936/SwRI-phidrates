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

# Globals

$use_semi_log = "false";
$solar_activity = "0.0";
$temp = 1000.0;          #default for Blackbody temperature in Kelvin
$which_tab = "";
@ref_list = ();

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
&CopyMolecule ($molecule, $temp_dir);
&CopyNecessaryFiles ($temp_dir);
&WriteInputFile ($solar_activity, $temp, $which_tab, $temp_dir);
&RunPhotoRat ($molecule, $temp_dir);
&PrintResults ($molecule, $temp_dir, $use_semi_log);

sub PrintResults {
    local ($molecule, $temp_dir, $use_semi_log) = @_;
    local ($nice_name);

    print "Content-type: text/html\n\n";
#	print "Content-type: video/mpeg\n\n";

    #print "<HTML><HEAD><TITLE>Cross Sections of $molecule</TITLE></HEAD>\n";
    #print "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">";
    #print "<CENTER>";
    $nice_name = &ConvertCanonicalInputName ($molecule);
    if (!defined ($nice_name)) {
        print "<H1>Cross Sections of $molecule\n</H1>";
    } else {
        print "<H1>Cross Sections of $nice_name\n</H1>";
    }
#    print "Temp Dir = $temp_dir\n Input = $input\n";
    print "\n";
    print "<P>";
    chdir ($temp_dir);
    my $url_temp_dir = $temp_dir;
    $url_temp_dir =~ s/$reg_exp_prefix/\/amop_images/g;
    $url_temp_dir =~ s/tmp//;

    #print "</CENTER>";
#    print "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/BrnOut\"><span>Click here to view or shift-click to download \
#           the data file used to create this plot!</span></A>\n";   
		   
		   
    #print "<CENTER>";
    $num_branches = &GenerateBranches ();
    $bnum = 0;
    while ($bnum <= $num_branches) {
        if ($branches[$bnum+2] eq "Sigma") {
            $branches[$bnum+2] = "Total";
        }
        $gifname = &GeneratePlot ($temp_dir, "branch.$bnum", $branches[$bnum+2], $use_semi_log);
        $nice_name = &ConvertCanonicalOutputName ($branches[$bnum+2]);
        if (!defined ($nice_name)) {
            print "<H2>$branches[$bnum + 2]</H2>";
        } else {
            print "<H2>$nice_name</H2>";
        }
        print "<IMG SRC = \"$gifname\" BORDER=4>\n";
        print "<P><P>";
        unlink ("branch.$bnum");
        $bnum++;
    }
    #print "</CENTER>";

    print "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/BrnOut\"><span>Click here to view or shift-click to download \
           the data file used to create this plot!</span></A>\n";
    print "<HR align=\"center\" width=\"50%\" size=\"1\">";
	
    print "</BODY></HTML>";
}

sub GenerateBranches {
    local ($num_branches, $num_values, $line, $i, $bnum, $val);

    open (INPUT_FILE, "< BrnOut") || die ("Can't open BrnOut\n");

    $ref_count = 0;
    $num_branches = 0;
    $num_values = 0;
 
    do {
        $line = <INPUT_FILE>;
        if ($line =~ /^0.*References/) {
            if ($ref_count != 0) {
                $ref_list [$ref_count-1] = @refs;
            }
            $ref_count++;
            @refs = {};
            $read_refs = 1;
        } elsif ($line =~ /^0.*Branching.* (\d+) branches/) {
            $read_refs = 0;
            $num_branches = $1;
            $header = <INPUT_FILE>;
            @branches = split (/\s+/, $header);
        } else {
            if ($read_refs) {
                push (@refs, $line);
            } else {    # read branches
                $line =~ s/^\s+//g;
                $line =~ s/\s+$//g;
                $line =~ s/\s+/ /g;
                @values = split (/ /, $line);
                if ($#values > $num_branches) {
                    $i = 0;
                    foreach $val (@values) {
                        if (($i == 0) && ($use_electron_volts eq "true")) {
                            $items{0,$num_values} = 12398.42 / $val;
                        } else {
                            $items{$i,$num_values} = $val;
                        }
                        $i++;
                    }
                    $num_values++;
                }
            }
        }
    } while (!eof (INPUT_FILE));
    close (INPUT_FILE);

    $bnum = 0;
    while ($bnum <= $num_branches) {
        open (OUTPUT_FILE, "> branch.$bnum") || die ("Couldn't open branch.$bnum\n");
        $i = 0;
        while ($i < $num_values) {
            print OUTPUT_FILE "$items{0,$i} $items{$bnum + 1,$i}\n";
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
    local ($use_semi_log) = $_ [3];
    local ($gifname, $xlabel, $ylabel, $plotTitle, $set_mytics);

    my ($fh, $gnuinfo) = tempfile (TEMPLATE => 'gnu_XXXXXX',
                                   DIR => $tempdir, CLEANUP => 1,
                                   SUFFIX => '.info');
    open (TMP_FILE, "> ".$gnuinfo) || die ("Can't open $gnuinfo\n");

    if ($use_electron_volts eq "true") {
        $xlabel = "Energy [eV]";
    } else {
        $xlabel = "Wavelength [A]";
    }
    $ylabel = "Cross Section [cm**2]";
    $plotTitle = "Southwest Research Institute\\nBranch: $branch";
    $set_mytics = "true";
    &SetCommonOutput ($use_semi_log, $xlabel, $ylabel, $plotTitle, $set_mytics);

    print TMP_FILE "plot \"$filename\" title \"\" with lines\n";
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

    if (-s $gifname) {
        chmod (0644, $gifname);
        $plotname = $gifname;
        $plotname =~ s/$reg_exp_prefix/..\/amop_images/g;
    } else {
        $plotname = "img/baddata.gif";
    }
    return ($plotname);
}
