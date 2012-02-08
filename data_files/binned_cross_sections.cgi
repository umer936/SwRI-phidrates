#!/usr/bin/perl -w

require "common.pl";
require "vars.pl";
require "LUTIn.txt";
require "LUTOut.txt";

use IO::File;
use POSIX qw(tmpnam);
use File::Temp qw/ tempfile tempdir /;

################################################################
#  parse QUERY_STRING -> filename; display file
################################################################

# Globals

$solar_activity = 0.0;
$temp = 1000.0;          #default for Blackbody temperature in Kelvin
$which_tab = "";
$use_semi_log = "false";

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
# Create the "Input" file to the "photo" program in our temporary directory
# run photo on the temporary directory

$temp_dir = &MakeTempDirectory ();
&CopyNecessaryFiles ($temp_dir);
&CopyMolecule ($molecule, $temp_dir);
&WriteInputFile ($solar_activity, $temp, $which_tab, $temp_dir);
&RunPhotoRat ($molecule, $temp_dir);
&PrintResults ($molecule, $temp_dir, $use_semi_log);

sub PrintResults {
    local ($molecule, $temp_dir, $use_semi_log) = @_;
    local ($nice_name);

    print "Content-type: text/html\n\n";
    print "<HTML><HEAD><TITLE>Binned Cross Sections of $molecule</TITLE></HEAD>\n";
    print "<BODY BGCOLOR=\"#000000\" TEXT=\"#00ff00\" LINK=\"#00ffff\" VLINK=\"#33ff00\">";
    #print "<CENTER>";
#    print "Temp Dir = $temp_dir   Input = $input\n";
    $nice_name = &ConvertCanonicalInputName ($molecule);
    if (defined ($nice_name)) {
        print "<H1>Binned Cross Sections of $nice_name</H1>\n";
    } else {
        print "<H1>Binned Cross Sections of $molecule</H1>\n";
    }
    print "\n";
    print "<P>";
    chdir ($temp_dir);

    my $url_temp_dir = $temp_dir;
    $url_temp_dir =~ s/$reg_exp_prefix/\/amop_images/g;
    $url_temp_dir =~ s/tmp//;

    #print "</CENTER>";
#    print "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/FotOut\"><span>Click here to view or shift-click to \
#           download the data file used to create this plot!</span></A>\n";
    #print "<CENTER>";
    $num_branches = &GenerateBranches ();
    $bnum = 1;
    while ($bnum <= $num_branches) {
        if ($branches[$bnum] eq "Lambda") {
            $branches[$bnum] = "Total";
        }
        $gifname = &GeneratePlot ($temp_dir, "branch.$bnum", $branches[$bnum+1], $use_semi_log);

# convert the $branches[$bnum+1] to a nice name

        $nice_name = &ConvertCanonicalOutputName ($branches[$bnum+1]);
        if (defined ($nice_name)) {
            print "<H2>$nice_name</H2>";
        } else {
            print "<H2>$branches[$bnum+1]</H2>";
        }

        print "<IMG SRC = \"$gifname\" BORDER=4>\n";
        print "<P><P>";
        unlink ("branch.$bnum");
        $bnum++;
    }
    #print "</CENTER>";

    print "<A target=\"_blank\" class=\"btn\" HREF=\"$url_temp_dir/FotOut\"><span>Click here to view or shift-click to \
           download the data file used to create this plot!</span></A>\n";
		   
	print "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>";	   
    print "</BODY></HTML>";
}

sub GenerateBranches {
    local ($num_branches, $num_values, $line, $i, $bnum, $val);

    open (INPUT_FILE, "< FotOut") || die ("Can't open FotOut\n");

    $line = <INPUT_FILE>;
    $line =~ /^\s*(\d+)/;
    $num_branches = $1;
    $header = <INPUT_FILE>;
    @branches = split (/\s+/, $header);

    $ref_count = 0;
    $ref_count = 0;
    $num_values = 0;
 
    do {
        $line = <INPUT_FILE>;
        if ($line =~ /Rate/) {
            # ignore this line - Although does not appear to be written by NEW_CODE
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
        open (OUTPUT_FILE, "> branch.$bnum") || die ("Couldn't open branch.$bnum\n");
        $i = 1;
        $last_x = $items{0,0};
        $last_y = $items{$bnum,0};
        while ($i < $num_values) {
            $new_y = $last_y; # / ($items{0,$i} - $last_x);
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
    local ($use_semi_log) = $_ [3];
    local ($gifname, $xlabel, $ylabel, $plotTitle, $set_mytics);

    my ($fh, $gnuinfo) = tempfile (TEMPLATE => 'gnu_XXXXXX',
                                   DIR => $tempdir, CLEANUP => 1,
                                   SUFFIX => '.info');
    open (TMP_FILE, "> ".$gnuinfo) || die ("Can't open $gnuinfo\n");

    $xlabel = "Wavelength [A]";
    $ylabel = "Cross Section [cm**2/A]";
    $plotTitle = "Southwest Research Institute\\nBranch: $branch";
    $set_mytics = "true";
    &SetCommonOutput ($use_semi_log, $xlabel, $ylabel, $plotTitle, $set_mytics);

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

    if (-s $gifname) {
        chmod (0644, $gifname);
        $plotname = $gifname;
        $plotname =~ s/$reg_exp_prefix/..\/amop_images/g;
    } else {
        $plotname = "img/baddata.gif";
    }

    return ($plotname);
}

