#!/opt/local/bin/perl -w


@filenames = ("hrec1.dat", "hrec2.dat", "hrec3.dat", "hrec4.dat", "hrec5.dat");
@filenames = ("HRec1Sup.dat");

foreach $file (@filenames) {

    open (INPUT_FILE, "< $file") || die ("ERROR - Couldn't open $file!\n");

START_OF:

    $line = <INPUT_FILE>;
    if (!eof (INPUT_FILE)) {
        @fields = split (/\s+/, $line);
        open (OUTPUT_FILE, "> hrecs/$fields[4].dat") || 
            die ("ERROR - Couldn't open $fields[4].dat\n");
        print OUTPUT_FILE $line;
        while ($line = <INPUT_FILE>) {
            print OUTPUT_FILE $line;
            if ($line =~ /\*\*\*/) {
                close (OUTPUT_FILE);
                goto START_OF;
            }
        }
    }
    close (INPUT_FILE);
}
