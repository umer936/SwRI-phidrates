#!/usr/bin/perl -w

require "common.pl";
require "vars.pl";

use IO::File;
use File::Temp qw/ tempfile tempdir /;

################################################################
#  parse QUERY_STRING -> filename; display file
################################################################

# Globals

$solar_activity = 0.0;
$which_tab = "";
$temp = 1000.0;          #default for Blackbody temperature in Kelvin
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

if ($which_tab eq "Int") {  # we need to block out interstellar for the moment!
    print "Content-type: text/html\n\n";
    print "<HTML><HEAD><TITLE>Interstellar Spectrum</TITLE></HEAD>\n";
    print "<BODY><H1>Interstellar Spectrum</H1>";
    print "<IMG SRC=\"img/under_construction.png\">";
    print "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>";
    print "</BODY></HTML>";
    exit (0);
}

#  If option was not on the tab being processed, reset to default value
#  since being overridden by previous parsing of QUERY_STRING.

if ($solar_activity eq "undefined") {
    $solar_activity = 0.0
};

# 1) make a temporary directory
# 2) copy the "molecule".dat to our temporary directory
# 3) Create the "Input" file to the "photo" program in our temporary directory
# 4) run photo on the temporary directory
# 5) Extract the values needed for the plot and place in new data file
# 6) run gnuplot over the new data file
# 7) return the name of the picture

$temp_dir = &MakeTempDirectory ();
&CopyNecessaryFiles ($temp_dir);
&CopyMolecule ($molecule, $temp_dir);
&WriteInputFile ($solar_activity, $temp, $which_tab, $temp_dir);
&RunPhotoRat ($molecule, $temp_dir);
&GenerateSpectrum ($temp_dir);
$gifname = &CreateGIF ($temp_dir, $use_semi_log);

print "Content-type: text/html\n\n";

if ($which_tab eq "BB ") {
    print "<HTML><HEAD><TITLE>Blackbody Spectrum</TITLE></HEAD>\n";
    print "<BODY><H1>Blackbody Spectrum</H1>";
} else {
    print "<HTML><HEAD><TITLE>Solar Spectrum</TITLE></HEAD>\n";
    print "<BODY><H1>Solar Spectrum</H1>";
}

print "<IMG SRC=\"$gifname\">";
print "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>";

print "</BODY></HTML>";
exit (0);

sub GenerateSpectrum {
  my ($temp_dir) = @_;
  local ($i, $val, $line, $header, $Wavelength, $Range, $XSection, $Flux, $Rate, $EExcess, $Sum, $lastline);

  open (INPUT_FILE, "< EIoniz") || die ("Can't open EIoniz\n");
  open (OUTPUT_FILE, "> $temp_dir/GP_SPECTRUM.DAT") || die ("$temp_dir/GP_SPECTRUM.DAT - Location: error.gif\n\n");

# Begin line indicator

  $line = <INPUT_FILE>;
  if ($line =~ /Begin/) {

# read and ignore the 2nd line

    $line = <INPUT_FILE>;
      
# read the 3rd line, which contains column header labels.
   
    $header = <INPUT_FILE>;

    $i = 1;
    $lastline = "false";
    do {
        $line = <INPUT_FILE>;

# When we reach the "Average Energy" line, we are done.
# This works even if there is more than one Begin EIoniz block.

        if ($line =~ /Average/) {
          # ignore this line but flag end of processing
          $lastline = "true";
        }
        elsif ($line =~ /Total/) {
          # ignore this line for now
        }
         else {
           $line =~ s/^\s+//g;
           $line =~ s/\s+$//g;
           $line =~ s/\s+/ /g;

           @values = split (/ /, $line);
           $Wavelength = $values[0];
           $Range = $values[1];
           $XSection = $values[2];
           $Flux = $values[3];
           $Rate = $values[4];
           $EExcess = $values[5];
           $Sum = $values[6];

           if ($Wavelength eq "undefined") {
                print "Content-type: text/html\n\n";
                printf ("Wavelength value is undefined at line number %d\n", $i);
           }
           if ($Flux eq "undefined") {
                print "Content-type: text/html\n\n";
                printf ("Flux value is undefined at line number %d\n", $i);
           }
        printf (OUTPUT_FILE "%10.2f %e\n", $Wavelength, $Flux);
      }
      $i++;
    } while ($lastline eq "false");
    close (INPUT_FILE);
    close (OUTPUT_FILE);
  }

# Invalid 1st line read from file.  This should trap the case where 0-length files are generated
# when photo.exe does not execute properly.

  else {
       print "Content-type: text/html\n\n";
       print "Invalid 1st line in file EIoniz, command = photo;\n";
  }
}

sub CreateGIF {

    local ($tempdir, $use_semi_log) = @_;
    local ($gifname, $xlabel, $ylabel, $plotTitle, $set_mytics);

    my ($fh, $gnuinfo) = tempfile (TEMPLATE => 'gnu_XXXXXX',
                                   DIR => $tempdir, CLEANUP => 1,
                                   SUFFIX => '.info');
    open (TMP_FILE, "> ".$gnuinfo) || die ("Can't open $gnuinfo\n");

    $xlabel = "Wavelength [A]";
    if ($which_tab eq "BB ") {
        $ylabel = "Blackbody Photon Spectrum (cm**-2 s**-1 A**-1)";
        $plotTitle = "Southwest Research Institute\\nBlackbody Rate coefficient at T = ${temp}K";
    } else {
        $ylabel = "Solar Flux (Photons cm**-2 s**-1 A**-1)";
        $plotTitle = "Southwest Research Institute\\nSolar Activity: $solar_activity";
    }
    $set_mytics = "false";
    &SetCommonOutput ($use_semi_log, $xlabel, $ylabel, $plotTitle, $set_mytics);

    print TMP_FILE "set xrange [1:100000]\n";
    print TMP_FILE "set nokey\n";
    print TMP_FILE "set mxtics 5\n";
    print TMP_FILE "plot \"$temp_dir/GP_SPECTRUM.DAT\" with steps\n";
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

    if (!defined ($reg_exp_prefix)) {
        $reg_exp_prefix = "\/tmp\/phidrates";   # remove warning
    }

    if (-s $gifname) {
        chmod (0644, $gifname);
        $plotname = $gifname;
        $plotname =~ s/$reg_exp_prefix/..\/phidrates_images/g;
    } else {
        $plotname = "img/baddata.gif";
    }
    return ($plotname);
}

