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

sub SetCommonOutput {

    local ($use_semi_log, $xlabel, $ylabel, $title, $set_ytics) = @_;

# do not use local or my for file handler.

    print TMP_FILE "set terminal png size 800,600 font \"/usr/share/fonts/dejavu-lgc/DejaVuLGCSans.ttf\" 12\n";
    if ($use_semi_log eq "false") {
        print TMP_FILE "set logscale xy\n";
    } else {
        print TMP_FILE "set logscale y\n";
    }

   print TMP_FILE << "EOF";

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

    print TMP_FILE "set xlabel \"$xlabel\"\n";
    print TMP_FILE "set ylabel \"$ylabel\"\n";
    print TMP_FILE "set title \"$title\"\n";

# Currently, all but gp_spectrum set this value.

    if ($set_ytics eq "true") {
      print TMP_FILE "set mytics 5\n";
   }
}