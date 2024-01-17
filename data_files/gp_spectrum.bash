#!/bin/bash

# Include common and vars scripts (replace these with actual content)
source common.bash  # Assuming you have a common file for functions
source vars.bash    # Assuming you have a vars file for variables
source LUTInNew.txt # Assuming you have a LUTIn.txt file
source LUTOutNew.txt # Assuming you have a LUTOut.txt file

# Globals
solar_activity=0.0
which_tab=""
temp=1000.0
use_semi_log="false"

# Convert variables to values
input=$QUERY_STRING
IFS='?' read -ra items <<< "$input"
for item in "${items[@]}"; do
    IFS='=' read -r key val <<< "$item"
    val=$(echo -e "${val//%/\\x}")
    val=${val//;/}
    declare "$key=$val"
done

if [ "$which_tab" = "Int" ]; then
    which_tab="IS "
fi

# If the option was not on the tab being processed, reset to default value
# since being overridden by previous parsing of QUERY_STRING.
if [ "$solar_activity" = "undefined" ]; then
    solar_activity=0.0
fi

# Function definitions

make_temp_directory() {
    local temp_dir
    temp_dir=$(mktemp -d)
    echo "$temp_dir"
}

copy_necessary_files() {
    local temp_dir=$1
    # Replace the following line with actual logic to copy necessary files to the temporary directory
    cp /path/to/source/directory/* "$temp_dir/"
}

copy_molecule() {
    local molecule=$1
    local temp_dir=$2
    # Replace the following line with actual logic to copy the molecule.dat file to the temporary directory
    cp "$molecule.dat" "$temp_dir/"
}

write_input_file() {
    local solar_activity=$1
    local temp=$2
    local which_tab=$3
    local temp_dir=$4
    # Replace the following line with actual logic to create the input file
    echo "Some content for input file" > "$temp_dir/Input"
}

run_photo_rat() {
    local molecule=$1
    local temp_dir=$2
    # Replace the following line with actual logic to run the photo program on the temporary directory
    ./photo "$temp_dir"
}

generate_spectrum() {
    local temp_dir=$1
    # Replace the following lines with actual logic to generate the spectrum file
    awk '{ print $1, $2 }' "$temp_dir/EIoniz" > "$temp_dir/GP_SPECTRUM.DAT"
}

create_gif() {
    local tempdir=$1
    local use_semi_log=$2
    local gifname
    local xlabel
    local ylabel
    local plotTitle
    local set_mytics

    local gnuinfo
    gnuinfo=$(mktemp -p "$tempdir" gnu_XXXXXX.info)
    exec 3>"$gnuinfo" || { echo "Can't open $gnuinfo"; exit 1; }

    xlabel="Wavelength [A]"
    if [ "$which_tab" = "BB " ]; then
        ylabel="Blackbody Photon Spectrum (cm**-2 s**-1 A**-1)"
        plotTitle="Southwest Research Institute\\nBlackbody Rate coefficient at T = ${temp}K"
    elif [ "$which_tab" = "IS " ]; then
        ylabel="Interstellar Radioation Field (cm**-2 s**-1 A**-1)"
        plotTitle="Southwest Research Institute"
    else
        ylabel="Solar Flux (Photons cm**-2 s**-1 A**-1)"
        plotTitle="Southwest Research Institute\\nSolar Activity: $solar_activity"
    fi

    set_mytics="false"
    set_common_output "$use_semi_log" "$xlabel" "$ylabel" "$plotTitle" "$set_mytics"

    if [ "$which_tab" = "IS " ]; then
        echo "set xrange [100:100000]" >&3
    else
        echo "set xrange [1:100000]" >&3
    fi
    echo "set nokey" >&3
    echo "set mxtics 5" >&3
    echo "plot \"$tempdir/GP_SPECTRUM.DAT\" with steps" >&3
    exec 3>&-

    local gifname
    gifname=$(mktemp -p "$tempdir" XXXXXX.png)
    /usr/bin/gnuplot "$gnuinfo" > "$gifname"
    if [ $? == -1 ]; then
        echo "failed to execute: $!"
    elif [ $? & 127 ]; then
        printf "child died with signal %d, %s coredump\n" $(( $? & 127 )) $(( $? & 128 )) ? 'with' : 'without'
    fi

    if [ ! -z "$reg_exp_prefix" ]; then
        reg_exp_prefix="\/tmp\/phidrates"
    fi

    if [ -s "$gifname" ]; then
        chmod 0644 "$gifname"
        plotname="$gifname"
        plotname="${plotname//$reg_exp_prefix/..\/phidrates_images}"
    else
        plotname="img/baddata.gif"
    fi

    echo "$plotname"
}