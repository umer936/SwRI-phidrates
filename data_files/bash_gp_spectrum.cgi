#!/bin/bash

source /usr/local/var/www/SwRI-phidrates/data_files/common.bash
source /usr/local/var/www/SwRI-phidrates/data_files/vars.bash

# Globals
solar_activity=0.0
which_tab=""
temp=1000.0
use_semi_log="false"

# Convert variables to values
input="${QUERY_STRING}"
IFS='?' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -r key val <<< "$item"
    val="$(echo -e "${val//%/\\x}" | sed 's/;//g')"
    declare "$key=$val"
done

if [[ "$which_tab" = "Int" ]]; then
    which_tab="IS "
fi

if [[ "$solar_activity" = "undefined" ]]; then
    solar_activity=0.0
fi

print_results() {
    if [[ "$which_tab" -eq "BB "]]; then
        echo "<HTML><HEAD><TITLE>Blackbody Spectrum</TITLE></HEAD>\n"
        echo "<BODY><H1>Blackbody Spectrum</H1>"
    elif [[ "$which_tab" -eq "IS "]]; then
        echo "<HTML><HEAD><TITLE>Interstellar Radiation Field</TITLE></HEAD>\n"
        echo "<BODY><H1>Interstellar Radiation Field</H1>"
    else
        echo "<HTML><HEAD><TITLE>Solar Spectrum</TITLE></HEAD>\n"
        echo "<BODY><H1>Solar Spectrum</H1>"
    fi

    generate_branches

    echo "<IMG SRC=\"$gifname\">"
    echo "<br><br><HR align=\"center\" width=\"50%\" size=\"1\"><br>";

    echo "</BODY></HTML>";
}

generate_branches() {
    local temp_dir="$1"
    local input_file output_file line

    input_file="$temp_dir/EIoniz"
    if [[ ! -e "$input_file" ]]; then
        echo "Couldn't open EIoniz" >&2
        exit 1
    fi

    output_file="$temp_dir/GP_SPECTRUM.DAT"
    if ! touch "$output_file"; then
        echo "Couldn't create GP_SPECTRUM.DAT" >&2
        exit 1
    fi

    if [[ "$(head -n 1 "$input_file")" =~ Begin]]; then
        while read -r line; do
            if (( $n == 0 || $n == 2 )); then
                continue
            elif (( $n == 1 )); then
                IFS=" " read -ra header <<< "$line"
            elif [[ "$line" =~ Average ]]; then
                break
            else
                line="$(echo "$line" | awk '{$1=$1};1')"
                IFS=" " read -r wavelength range xsection flux rate eexcess sum <<< "$line"

                [[ -n "$wavelength" ]] || echo "Wavelength value is undefined at line number $n\n" >&2
                [[ -n "$flux" ]] || echo "Flux value is undefined at line number $n\n" >&2

                printf "%10.2f %e" "$wavelength" "$flux" >> "$output_file"
            fi
            ((n++))
        done < "$input_file"
    else
        echo "Invalid 1st line in file EIoniz, command = photo;\n" >&2 
    fi
    # awk '{ print $1, $2 }' "$temp_dir/EIoniz" > "$temp_dir/GP_SPECTRUM.DAT"
}

generate_plot() {
    local tempdir="$1"
    local use_semi_log="$2"
    local bnum="$3"
    
    local gnuinfo="$temp_dir/gnu_$bnum.info"
    if ! touch "$gnuinfo"; then
        echo "Can't open $gnuinfo" >&2
        exit 1
    fi

    local xlabel ylabel plotTitle set_mytics
    xlabel='Wavelength [A]'
    if [[ "$which_tab" = "BB " ]]; then
        ylabel='Blackbody Photon Spectrum (cm**-2 s**-1 A**-1)'
        plotTitle="Southwest Research Institute\\nBlackbody Rate coefficient at T = ${temp}K"
    elif [[ "$which_tab" = "IS " ]]; then
        ylabel='Interstellar Radioation Field (cm**-2 s**-1 A**-1)'
        plotTitle="Southwest Research Institute"
    else
        ylabel='Solar Flux (Photons cm**-2 s**-1 A**-1)'
        plotTitle="Southwest Research Institute\\nSolar Activity: $solar_activity"
    fi
    set_mytics="false"
    set_common_output "$use_semi_log" "$xlabel" "$ylabel" "$plotTitle" "$set_mytics"

    if [[ "$which_tab" = "IS " ]]; then
        echo 'set xrange [100:100000]' >&3
    else
        echo 'set xrange [1:100000]' >&3
    fi
    echo 'set nokey' >&3
    echo 'set mxtics 5' >&3
    #? danger!
    echo "plot \"$tempdir/GP_SPECTRUM.DAT\" with steps" >&3
    exec 3>&-

    local gifname
    gifname="$tempdir/gnu_$bnum.png"
    /usr/bin/gnuplot "$gnuinfo" > "$gifname"
    if [[ $? -eq -1 ]]; then
        echo "failed to execute: $!"
    elif (( $? & 127 )); then #? what?!
        printf "child died with signal %d, %s coredump\n" $(( $? & 127 )) $(( $? & 128 )) ? 'with' : 'without'
    fi

    if [[ -s "$gifname" ]]; then
        chmod 0644 "$gifname"
        plotname="${gifname//$reg_exp_prefix/..\/phidrates_images}"
    else
        plotname="img/baddata.gif"
    fi

    echo "$plotname"
}

echo "Content-type: text/html\n"

cd "/usr/local/var/www/SwRI-phidrates"
temp_dir="$(make_temp_directory)"

copy_molecule "$molecule" "$temp_dir"
copy_necessary_files "$temp_dir"
write_input_file "$solar_activity" "$temp" "$which_tab" "$temp_dir"
run_photo_rat "$molecule" "$temp_dir"
print_results "$molecule" "$temp_dir" "$use_semi_log"

exit 0