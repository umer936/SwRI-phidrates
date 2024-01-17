
function reformat(str)
    
    left, right = strip.(split(str, "="))
    left=chopprefix(replace(left, " {"=>"[", "}"=>"]", "'"=>"\""), "\$")
    right=chopsuffix(right, ";")
    println(left*"="*right)
end

function reformat2(str)
    str=replace(str, ";"=>"", "\""=>"", "'"=>"", "{"=>"", "}"=>"", " = "=>"=") |> strip
    println(str[12:end])
end

lut = readlines("LUTOut.txt")
for line in lut
    !contains(line, "=") && continue
    reformat2(line)
end

