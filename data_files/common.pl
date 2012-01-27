#!/usr/bin/perl -w

require "vars.pl";

sub CopyMolecule {

    local ($molecule, $temp_dir) = @_;

    `cp $amop_cgi_bin_dir/photo/hrecs/$molecule.dat $temp_dir/Hrec`;
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

sub RunPhotoRat {

    local ($molecule, $temp_dir) = @_;

    chdir ($temp_dir);
    `$amop_cgi_bin_dir/photo/NEW_CODE/photo.exe`;

    if ($?)
    {
          my $code = $? >> 8;
          print "Content-type: text/html\n\n";
          print "Error in subname, command = photo; code = $?/$code\n";
          return $?;
    }
    return 0;
}

sub WriteInputFile {

    local ($solar_activity, $temp, $which_tab, $temp_dir) = @_;
    my $DummySA;

    $DummySA = 0.0;

# Contents of Input file depends on type of radiation field being processed
# but currently, file only contains 3 lines.

    open (NEWFILE, "> $temp_dir/Input") || die ("Cannot create the file $temp_dir/Input.\n");

# Blackbody Radiation Field

   if ($which_tab eq "BB ") {
     print NEWFILE "$which_tab\n";
     printf (NEWFILE "%4.2f\n", $DummySA);
     printf (NEWFILE "%-8.0f\n", $temp);
   }

# InterStellar Radiation Field - has not been completely implemented using Input file.
# For now, just put a placeholder for 3rd line.

   elsif ($which_tab eq "IS ") {
     print NEWFILE "$which_tab\n";
     printf (NEWFILE "%4.2f\n", $DummySA);
     print NEWFILE "\n";
   }

# Solar Radiation Field - third line is ignored

   elsif ($which_tab eq "Sol") {
     print NEWFILE "$which_tab\n";
     printf (NEWFILE "%4.2f\n", $solar_activity);
     print NEWFILE "\n";
   }

# invalid value - nothing put into file.

   else {
   }

  close (NEWFILE);
}

sub CopyNecessaryFiles {

    local ($temp_dir) = @_;

    `cp $amop_cgi_bin_dir/photo/NEW_CODE/BBGrid.dat $temp_dir/BBGrid.dat`;
    `cp $amop_cgi_bin_dir/photo/NEW_CODE/BBFlux.dat $temp_dir/BBFlux.dat`;
    `cp $amop_cgi_bin_dir/photo/NEW_CODE/PhFlux.dat $temp_dir/PhFlux.dat`;
}
