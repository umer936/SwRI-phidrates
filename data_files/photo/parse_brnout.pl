#!/opt/local/bin/perl -w

&GenerateBranches ();

sub GenerateBranches {
    local ($num_branches, $num_values, $line, $i, $bnum, $val);

    open (INPUT_FILE, "< BRNOUT") || die ("Can't open BRNOUT\n");

    $ref_count = 0;
    $ref_count = 0;
    $num_values = 0;
 
    do {
        $line = <INPUT_FILE>;
        if ($line =~ /^0.*References/) {
            if ($ref_count != 0) {
                $ref_list [$ref_count-1] = @refs;
# print join ("\n", $ref_list [$ref_count-1]);
            }
            $ref_count++;
            @refs = {};
            $read_refs = 1;
        } elsif ($line =~ /^0.*Branching.* (\d+) Branches/) {
            $read_refs = 0;
            $num_branches = $1;
print "$num_branches\n";
            $header = <INPUT_FILE>;
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
                        $items{$i,$num_values} = $val;
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
}
