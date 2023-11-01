#!/bin/bash

# Include variables from vars.pl if needed
source "vars.pl"

CopyMolecule() {
    local molecule="$1"
    local temp_dir="$2"
    cp "$amop_cgi_bin_dir/photo/hrecs/$molecule.dat" "$temp_dir/Hrec"
}

MakeTempDirectory() {
    local temp_dir

    # Make a temporary directory
    if [ ! -e "$prefix" ]; then
        mkdir -p "$prefix"
    fi

    temp_dir=$(mktemp -d -p "$prefix" "fileXXXXXX")
    chmod 0755 "$temp_dir"
    echo "$temp_dir"
}

RunPhotoRat() {
    local molecule="$1"
    local temp_dir="$2"

    cd "$temp_dir"
    "$amop_cgi_bin_dir/photo/NEW_CODE/photo.exe"

    if [ $? -ne 0 ]; then
        local code=$(( $? >> 8 ))
        echo "Content-type: text/html"
        echo
        echo "Error in subname, command = photo; code = $/?$code"
        return $?
    fi
    return 0
}

WriteInputFile() {
    local solar_activity="$1"
    local temp="$2"
    local which_tab="$3"
    local temp_dir="$4"
    local DummySA=0.0

    # Contents of Input file depends on the type of radiation field being processed
    # but currently, the file only contains 3 lines.

    if [ "$which_tab" == "BB " ]; then
        echo "$which_tab" > "$temp_dir/Input"
        printf "%4.2f\n" "$DummySA" >> "$temp_dir/Input"
        printf "%-8.0f\n" "$temp" >> "$temp_dir/Input"
    elif [ "$which_tab" == "Int" ] || [ "$which_tab" == "IS " ]; then
        echo "IS " > "$temp_dir/Input"
        printf "%4.2f\n" "$DummySA" >> "$temp_dir/Input"
    elif [ "$which_tab" == "Sol" ]; then
        echo "$which_tab" > "$temp_dir/Input"
        printf "%4.2f\n" "$solar_activity" >> "$temp_dir/Input"
    fi
}

CopyNecessaryFiles() {
    local temp_dir="$1"

    cp "$amop_cgi_bin_dir/photo/NEW_CODE/BBGrid.dat" "$temp_dir/BBGrid.dat"
    cp "$amop_cgi_bin_dir/photo/NEW_CODE/PhFlux.dat" "$temp_dir/PhFlux.dat"
}

SetCommonOutput() {
    local use_semi_log="$1"
    local xlabel="$2"
    local ylabel="$3"
    local title="$4"
    local set_ytics="$5"

    # Define your TMP_FILE or use stdout as appropriate
    # TMP_FILE="/path/to/output/file"

    echo "set terminal png size 800,600 font \"/usr/share/fonts/dejavu/DejaVuLGCSans.ttf\" 12" >> "$TMP_FILE"
    if [ "$use_semi_log" == "false" ]; then
        echo "set logscale x" >> "$TMP_FILE"
        echo "set logscale y 10" >> "$TMP_FILE"
        echo "set format y '%g'" >> "$TMP_FILE"
    else
        echo "set logscale y" >> "$TMP_FILE"
    fi

    # Rest of the output settings go here
    # Add to the TMP_FILE as needed
    # echo "set xlabel \"$xlabel\"" >> "$TMP_FILE"
    # echo "set ylabel \"$ylabel\"" >> "$TMP_FILE"
    # echo "set title \"$title\"" >> "$TMP_FILE"
    # ...

    if [ "$set_ytics" == "true" ]; then
        echo "set mytics 5" >> "$TMP_FILE"
    fi
}

# Usage examples:
# CopyMolecule "molecule_name" "/temp_dir"
# MakeTempDirectory
# RunPhotoRat "molecule_name" "/temp_dir"
# WriteInputFile 1.0 300.0 "Sol" "/temp_dir"
# CopyNecessaryFiles "/temp_dir"
# SetCommonOutput "false" "X Label" "Y Label" "Title" "true"