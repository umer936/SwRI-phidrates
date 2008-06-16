#!/usr/bin/perl -w

use IO::File;
use POSIX qw(tmpnam);

################################################################
#  parse QUERY_STRING -> filename; display file
################################################################

print "Content-type: text/html\n\n";

$input = $ENV{'QUERY_STRING'};
($key, $val) = split(/=/, $input, 2);
$val =~ s/%(..)/pack("c",hex($1))/ge;

$dir_name = "/we/rlink/spacephysics/atomic/data/";
open (ASCII_FILE, "$dir_name"."$val");
@datafile = <ASCII_FILE>;
close (ASCII_FILE);

print "<HTML><HEAD><TITLE>Results of query for $val</TITLE></HEAD><BODY>\n";

if (grep (/CONSTRUCTION/, @datafile) > 1) {

   print "<H1>UNDER CONSTRUCTION!</H1>";

} else {

# table 1 is for the outer stuff

    print "<TABLE BORDER=2>\n";
    print "<TH>Actual Data</TH><TH>Plot of Data</TH>";
    print "<TR><TD>";
    
    #table 2 is for the x/y values
    
    print "<TABLE CELLPADDING=2 BORDER=1>\n";
    print "<TH>Wavelength</TH><TH>Y-Value</TH>";
    
    foreach $line (@datafile) {
          $line =~ s/^\s+//;   # leading white space
          $line =~ s/\s+$//;   # trailing white space
          $line =~ s/\s+/ /;   # all spaces into one space
         ($x, $y) = split (/ /, $line);
         print "<TR><TD>$x</TD><TD>$y</TD></TR>\n";
    }
    
    
    print "</TD></TABLE>";
    
    open (TMP_FILE, "> /tmp/gnuplot.info");
    print TMP_FILE "set terminal gif\n";
    print TMP_FILE "set logscale y\n";
    print TMP_FILE "plot \"$dir_name$val\" title \"\" with lines\n";
    close (TMP_FILE);
    $gifname = tmpnam ();
    $gifname =~ s/\/var//;
    $gifname .= ".gif";
    `/opt/local/bin/gnuplot /tmp/gnuplot.info > /swdevel/apache_1.2.5/htdocs/$gifname`;
    
    unlink ("/tmp/gnuplot.info");
    
    print "<TD VALIGN=top><IMG ALT=\"plot of data\" SRC=\"$gifname\">";
    print "</TR></TABLE>"
}

print "</BODY></HTML>\n";
exit (0);
