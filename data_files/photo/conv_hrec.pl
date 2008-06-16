#!/opt/local/bin/perl -w

open (INF, "< hrec_ids.txt");

print "#!/opt/local/bin/perl -w\n";
while ($line = <INF>) {
    chomp ($line);
    @vals = split (/\s+/, $line);

# 0 - first element
# 1 - second element
# 2 - real first element
# 3, 4, 5 - + v ->
# 6 - end real second element

    $cnv = &convert_real_element ($vals [2]);
    print "\$eleLUT {'$vals[0]'} = \"$cnv\";\n"; 
    if ($vals [1] ne "total") {
        $cnv = &convert_real_element ($vals [6]);
        print "\$eleLUT {'$vals[1]'} = \"$cnv"; 
        $cnt = 8;
        while (defined ($vals [$cnt])) {
            if ($vals [$cnt] ne "+") {
                $cnv = &convert_real_element ($vals [$cnt]);
                print " + $cnv";
            }
            $cnt++;
        } 
        print "\";\n";
    } 
}

sub convert_real_element {

    $element = $_ [0];

    $element =~ s/\-/<sup>-<\/sup>/g;
    $element =~ s/\+/<sup>+<\/sup>/g;
    $element =~ s/[^(]([A-Z][a-z]*)([0-9])/$1<sub>$2<\/sub>/g;
    $element =~ s/([0-9])\)/<sub>$1<\/sub>)/g;
    $element =~ s/\(([0-9])/(<sup>$1<\/sup>/g;
    $element =~ s/\(X([0-9])/(X<sup>$1<\/sup>/g;
    $element =~ s/\(a([0-9])/(a<sup>$1<\/sup>/g;
    $element =~ s/\(A([0-9])/(A<sup>$1<\/sup>/g;
    return ($element);
}
